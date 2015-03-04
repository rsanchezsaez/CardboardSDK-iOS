#include "WWWConnection.h"

#include <map>
#include <string>

// WARNING: this MUST be c decl (NSString ctor will be called after +load, so we cant really change its value)
// If you need to communicate with HTTPS server with self signed certificate
// you might consider UnityWWWConnectionSelfSignedCertDelegate. Though use it on your own
// risk. Blindly accepting self signed certificate is prone to MITM attack
//const char* WWWDelegateClassName 		= "UnityWWWConnectionSelfSignedCertDelegate";
const char* WWWDelegateClassName 		= "UnityWWWConnectionDelegate";
const char* WWWRequestProviderClassName = "UnityWWWRequestDefaultProvider";

@interface UnityWWWConnectionDelegate()
@property (readwrite, nonatomic) void*						udata;
@property (readwrite, retain, nonatomic) NSURL*				url;
@property (readwrite, retain, nonatomic) NSString*			user;
@property (readwrite, retain, nonatomic) NSString*			password;
@property (readwrite, retain, nonatomic) NSURLConnection*	connection;
@end


@implementation UnityWWWConnectionDelegate
{
	// link to unity WWW implementation
	void*				_udata;
	// connection that we manage
	NSURLConnection*	_connection;

	// NSURLConnection do not quite handle user:pass@host urls
	// so we need to extract user/pass ourselves
	NSURL*				_url;
	NSString*			_user;
	NSString*			_password;

	// response
	NSString* 			_responseHeader;
	int					_status;
	size_t				_estimatedLength;
	int					_retryCount;

	// data
	NSMutableData*		_data;
}

@synthesize url			= _url;
@synthesize user		= _user;
@synthesize password	= _password;
@synthesize data		= _data;
@synthesize connection	= _connection;

@synthesize udata		= _udata;
@synthesize shouldAbort;

- (NSURL*)extractUserPassFromUrl:(NSURL*)url
{
	self.user		= url.user;
	self.password	= url.password;

	// strip user/pass from url
	NSString* newUrl = [NSString stringWithFormat:@"%@://%@%s%s%@%s%s",
		url.scheme, url.host,
		url.port ? ":" : "", url.port ? [[url.port stringValue] UTF8String] : "",
		url.path,
		url.fragment ? "#" : "", url.fragment ? [url.fragment UTF8String] : ""
	];
	return [NSURL URLWithString:newUrl];
}

- (id)initWithURL:(NSURL*)url udata:(void*)udata;
{
	self->_retryCount = 0;
	if((self = [super init]))
	{
		self.url	= url.user != nil ? [self extractUserPassFromUrl:url] : url;
		self.udata	= udata;
	}

	return self;
}

+ (id)newDelegateWithURL:(NSURL*)url udata:(void*)udata
{
	Class target = NSClassFromString([NSString stringWithUTF8String:WWWDelegateClassName]);
	NSAssert([target isSubclassOfClass:[UnityWWWConnectionDelegate class]], @"You MUST subclass UnityWWWConnectionDelegate");

	return [[target alloc] initWithURL:url udata:udata];
}

+ (id)newDelegateWithCStringURL:(const char*)url udata:(void*)udata
{
	return [UnityWWWConnectionDelegate newDelegateWithURL:[NSURL URLWithString:[NSString stringWithUTF8String: url]] udata:udata];
}

+ (NSMutableURLRequest*)newRequestForHTTPMethod:(NSString*)method url:(NSURL*)url headers:(NSDictionary*)headers
{
	static Class targetClass = nil;
	if(targetClass == nil)
	{
		targetClass = NSClassFromString([NSString stringWithUTF8String:WWWRequestProviderClassName]);
		NSAssert([targetClass conformsToProtocol:@protocol(UnityWWWRequestProvider)], @"You MUST implement UnityWWWRequestProvider protocol");
	}

	return [targetClass allocRequestForHTTPMethod:method url:url headers:headers];
}

- (void)cleanup
{
	[_url release];
	_url = nil;

	[_responseHeader release];
	_responseHeader = nil;

	[_connection cancel];
	[_connection release];
	_connection = nil;

	[_data release];
	_data = nil;
}


- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
	// on ios pre-5.0 NSHTTPURLResponse was not created for "file://"" connections, so play safe here
	// TODO: remove that once we have 5.0 as requirement
	self->_status = 200;
	if([response isMemberOfClass:[NSHTTPURLResponse class]])
	{
		NSDictionary* respHeader = [(NSHTTPURLResponse*)response allHeaderFields];
		NSEnumerator* headerEnum = [respHeader keyEnumerator];

		NSMutableString* headerString = [[NSMutableString stringWithCapacity:1024] retain];
		{
			for(id headerKey = [headerEnum nextObject] ; headerKey ; headerKey = [headerEnum nextObject])
				[headerString appendFormat:@"%@: %@\n", (NSString*)headerKey, (NSString*)[respHeader objectForKey:headerKey]];
		}

		self->_responseHeader	= headerString;
		self->_status			= [(NSHTTPURLResponse*)response statusCode];

		long long contentLength = [response expectedContentLength];
		self->_estimatedLength	= contentLength > 0 ? contentLength : 0;

		// status 2xx are all success
		if(self->_status / 100 != 2)
		{
			UnityReportWWWStatusError(self.udata, self->_status, [[NSHTTPURLResponse localizedStringForStatusCode: self->_status] UTF8String]);
			[connection cancel];
		}
	}

	UnityReportWWWReceivedResponse(self.udata, self->_status, self->_estimatedLength, [self->_responseHeader UTF8String]);
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
	if(self->_data == nil)
	{
		size_t capacity = self->_estimatedLength > 0 ? self->_estimatedLength : 1024;
		self->_data = [[NSMutableData dataWithCapacity: capacity] retain];
	}

	[self->_data appendData:data];
	UnityReportWWWReceivedData(self.udata, [self->_data length], self->_estimatedLength);

	if(self.shouldAbort)
		[connection cancel];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
	UnityReportWWWFailedWithError(self.udata, [[error localizedDescription] UTF8String]);
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
	UnityReportWWWFinishedLoadingData(self.udata);
}

- (void)connection:(NSURLConnection*)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	UnityReportWWWSentData(self.udata, totalBytesWritten, totalBytesExpectedToWrite);
}


- (void)connection:(NSURLConnection*)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
{
	// we imitate cpp idiom of private virtual func for implementation details
	BOOL authHandled = NO;
	{
		#pragma clang diagnostic push
    	#pragma clang diagnostic ignored "-Wobjc-method-access"

		if([self respondsToSelector:@selector(connection:handleAuthenticationChallenge:success:)])
			[self connection:connection handleAuthenticationChallenge:challenge success:&authHandled];

		#pragma clang diagnostic pop
	}

	if(authHandled == NO)
	{
		self->_retryCount++;

		// Empty user or password
		if (self->_retryCount > 1 || self.user == nil || [self.user length] == 0 || self.password == nil || [self.password length]  == 0)
		{
			[[challenge sender] cancelAuthenticationChallenge:challenge];
			return;
		}

		NSURLCredential* newCredential =
			[NSURLCredential credentialWithUser:self.user password:self.password persistence:NSURLCredentialPersistenceNone];

		[challenge.sender useCredential:newCredential forAuthenticationChallenge:challenge];
	}
}

@end


@implementation UnityWWWConnectionSelfSignedCertDelegate

- (BOOL)connection:(NSURLConnection*)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace*)protectionSpace
{
	return YES;
}

- (void)connection:(NSURLConnection*)connection handleAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge success:(BOOL*)success
{
	if([[challenge.protectionSpace authenticationMethod] isEqualToString:@"NSURLAuthenticationMethodServerTrust"])
	{
		[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
			forAuthenticationChallenge:challenge];

		*success = YES;
	}
}

@end


@implementation UnityWWWRequestDefaultProvider
+ (NSMutableURLRequest*)allocRequestForHTTPMethod:(NSString*)method url:(NSURL*)url headers:(NSDictionary*)headers
{
	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
	request.URL = url;
	request.HTTPMethod = method;
	request.allHTTPHeaderFields = headers;

	return request;
}
@end




//
// unity interface
//

extern "C" void* UnityStartWWWConnectionGet(void* udata, const void* headerDict, const char* url)
{
	UnityWWWConnectionDelegate*	delegate = [UnityWWWConnectionDelegate newDelegateWithCStringURL:url udata:udata];

	NSMutableURLRequest* request = [UnityWWWConnectionDelegate newRequestForHTTPMethod:@"GET" url:delegate.url headers:(NSDictionary*)headerDict];
	delegate.connection = [NSURLConnection connectionWithRequest:request delegate:delegate];
	[request release];

	return delegate;
}

extern "C" void* UnityStartWWWConnectionPost(void* udata, const void* headerDict, const char* url, const void* data, unsigned length)
{
	UnityWWWConnectionDelegate*	delegate = [UnityWWWConnectionDelegate newDelegateWithCStringURL:url udata:udata];

	NSMutableURLRequest* request = [UnityWWWConnectionDelegate newRequestForHTTPMethod:@"POST" url:delegate.url headers:(NSDictionary*)headerDict];
	request.HTTPBody = [NSData dataWithBytes:data length:length];
	[request setValue:[NSString stringWithFormat:@"%d", length] forHTTPHeaderField:@"Content-Length"];

	delegate.connection = [NSURLConnection connectionWithRequest:request delegate:delegate];
	[request release];

	return delegate;
}

extern "C" void UnityDestroyWWWConnection(void* connection)
{
	UnityWWWConnectionDelegate* delegate = (UnityWWWConnectionDelegate*)connection;

	[delegate cleanup];
	[delegate release];
}

extern "C" const void* UnityGetWWWData(const void* connection)
{
	return [((UnityWWWConnectionDelegate*)connection).data bytes];
}

extern "C" int UnityGetWWWDataLength(const void* connection)
{
	return [((UnityWWWConnectionDelegate*)connection).data length];
}

extern "C" const char* UnityGetWWWURL(const void* connection)
{
	return [[((UnityWWWConnectionDelegate*)connection).url absoluteString] UTF8String];
}

extern "C" void UnityShouldCancelWWW(const void* connection)
{
	((UnityWWWConnectionDelegate*)connection).shouldAbort = YES;
}
