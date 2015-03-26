
#include <sys/types.h>
#include <sys/sysctl.h>

#if UNITY_PRE_IOS7_TARGET
	#include <sys/socket.h>
	#include <net/if.h>
	#include <net/if_dl.h>
	#include <CommonCrypto/CommonDigest.h>

	static void _InitDeviceIDPreIOS7();
#endif

#include "DisplayManager.h"


static NSString*	_DeviceID			= nil;
static NSString*	_ADID				= nil;
static bool			_AdTrackingEnabled	= false;
static NSString*	_VendorID			= nil;

static NSString*	_DeviceName			= nil;
static NSString*	_SystemName			= nil;
static NSString*	_SystemVersion		= nil;

static NSString*	_DeviceModel		= nil;
static int			_DeviceGeneration	= deviceUnknown;
static float		_DeviceDPI			= -1.0f;


static void QueryDeviceID();
static void QueryAdID();
static void QueryAdTracking();
static void QueryVendorID();

static void QueryDeviceName();
static void QuerySystemName();
static void QuerySystemVersion();

static void QueryDeviceModel();
static void QueryDeviceGeneration();
static void EstimateDeviceDPI();


//
// unity interface
//

extern "C" const char*	UnityDeviceUniqueIdentifier()
{
	QueryDeviceID();
	return [_DeviceID UTF8String];
}
extern "C" const char*	UnityVendorIdentifier()
{
	QueryVendorID();
	return [_VendorID UTF8String];
}
extern "C" const char*	UnityAdvertisingIdentifier()
{
	QueryAdID();
	return [_ADID UTF8String];
}
extern "C" bool 		UnityAdvertisingTrackingEnabled()
{
	QueryAdTracking();
	return _AdTrackingEnabled;
}
extern "C" const char*	UnityDeviceName()
{
	QueryDeviceName();
	return [_DeviceName UTF8String];
}
extern "C" const char*	UnitySystemName()
{
	QuerySystemName();
	return [_SystemName UTF8String];
}
extern "C" const char*	UnitySystemVersion()
{
	QuerySystemVersion();
	return [_SystemVersion UTF8String];
}
extern "C" const char*	UnityDeviceModel()
{
	QueryDeviceModel();
	return [_DeviceModel UTF8String];
}
extern "C" int			UnityDeviceGeneration()
{
	QueryDeviceGeneration();
	return _DeviceGeneration;
}
extern "C" float		UnityDeviceDPI()
{
	EstimateDeviceDPI();
	return _DeviceDPI;
}


//------------------------------------------------------------------------------
//
//

static void QueryDeviceID()
{
	if(_DeviceID == nil)
	{
	#if UNITY_PRE_IOS7_TARGET
		if(!_ios70orNewer)
			_InitDeviceIDPreIOS7();
	#endif

		// first check vendor id
		if(_DeviceID == nil)
		{
			QueryVendorID();
			_DeviceID = _VendorID;
		}
	}
}

static id QueryASIdentifierManager()
{
	NSBundle* bundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/AdSupport.framework"];
	if(bundle)
	{
		[bundle load];
		Class retClass = [bundle classNamed:@"ASIdentifierManager"];
		if(		retClass
			&&	[retClass respondsToSelector:@selector(sharedManager)]
			&&	[retClass instancesRespondToSelector:@selector(advertisingIdentifier)]
			&&	[retClass instancesRespondToSelector:@selector(isAdvertisingTrackingEnabled)]
		  )
		{
			return [retClass performSelector:@selector(sharedManager)];
		}
	}

	return nil;
}

static void QueryAdID()
{
	// ad id can be reset during app lifetime
	id manager = QueryASIdentifierManager();
	if(manager)
	{
		[_ADID release];
		_ADID = (NSString*)[[[manager performSelector:@selector(advertisingIdentifier)] UUIDString] retain];
	}
}

static void QueryAdTracking()
{
	// ad tracking can be changed during app lifetime
	id manager = QueryASIdentifierManager();
	if(manager)
		_AdTrackingEnabled = [manager performSelector:@selector(isAdvertisingTrackingEnabled)];
}

static void QueryVendorID()
{
	if(_VendorID == nil && [UIDevice instancesRespondToSelector:@selector(identifierForVendor)])
		_VendorID = (NSString*)[[[[UIDevice currentDevice] performSelector:@selector(identifierForVendor)] UUIDString] retain];
}

static NSString* QueryDeviceStringProperty(SEL prop)
{
	return [UIDevice instancesRespondToSelector:prop] ? [[[UIDevice currentDevice] performSelector:prop] retain] : nil;
}


static void QueryDeviceName()
{
	if(_DeviceName == nil)
		_DeviceName = QueryDeviceStringProperty(@selector(name));
}
static void QuerySystemName()
{
	if(_SystemName == nil)
		_SystemName = QueryDeviceStringProperty(@selector(systemName));
}
static void QuerySystemVersion()
{
	if(_SystemVersion == nil)
		_SystemVersion = QueryDeviceStringProperty(@selector(systemVersion));
}

static void QueryDeviceModel()
{
	if(_DeviceModel == nil)
	{
		size_t size;
		::sysctlbyname("hw.machine", NULL, &size, NULL, 0);

		char* model = (char*)::malloc(size + 1);
		::sysctlbyname("hw.machine", model, &size, NULL, 0);
		model[size] = 0;

		_DeviceModel = [[NSString stringWithUTF8String:model] retain];
		::free(model);
	}
}

static void QueryDeviceGeneration()
{
	if(_DeviceGeneration == deviceUnknown)
	{
		const char* model = UnityDeviceModel();

		if (!strcmp(model, "iPhone2,1"))
			_DeviceGeneration = deviceiPhone3GS;
		else if (!strncmp(model, "iPhone3,",8))
			_DeviceGeneration = deviceiPhone4;
		else if (!strncmp(model, "iPhone4,",8))
			_DeviceGeneration = deviceiPhone4S;
		else if (!strncmp(model, "iPhone5,",8))
		{
			int rev = atoi(model+8);
			if (rev >= 3) _DeviceGeneration = deviceiPhone5C; // iPhone5,3
			else		  _DeviceGeneration = deviceiPhone5;
		}
		else if (!strncmp(model, "iPhone6,",8))
			_DeviceGeneration = deviceiPhone5S;
		else if (!strncmp(model, "iPhone7,2",9))
			_DeviceGeneration = deviceiPhone6;
		else if (!strncmp(model, "iPhone7,1",9))
			_DeviceGeneration = deviceiPhone6Plus;
		else if (!strcmp(model, "iPod1,1"))
			_DeviceGeneration = deviceiPodTouch1Gen;
		else if (!strcmp(model, "iPod2,1"))
			_DeviceGeneration = deviceiPodTouch2Gen;
		else if (!strcmp(model, "iPod3,1"))
			_DeviceGeneration = deviceiPodTouch3Gen;
		else if (!strcmp(model, "iPod4,1"))
			_DeviceGeneration = deviceiPodTouch4Gen;
		else if (!strncmp(model, "iPod5,",6))
			_DeviceGeneration = deviceiPodTouch5Gen;
		else if (!strcmp(model, "iPad1,1"))
			_DeviceGeneration = deviceiPad1Gen;
		else if (!strncmp(model, "iPad2,", 6))
		{
			int rev = atoi(model+6);
			if(rev >= 5)	_DeviceGeneration = deviceiPadMini1Gen; // iPad2,5
			else			_DeviceGeneration = deviceiPad2Gen;
		}
		else if (!strncmp(model, "iPad3,", 6))
		{
			int rev = atoi(model+6);
			if(rev >= 4)	_DeviceGeneration = deviceiPad4Gen; // iPad3,4
			else			_DeviceGeneration = deviceiPad3Gen;
		}
		else if (!strncmp(model, "iPad4,", 6))
		{
			int rev = atoi(model+6);
			if(rev >= 7)	_DeviceGeneration = deviceiPadMini3Gen;
			if(rev >= 4)	_DeviceGeneration = deviceiPadMini2Gen; // iPad4,4
			else			_DeviceGeneration = deviceiPad5Gen;
		}
		else if (!strncmp(model, "iPad5,", 6))
		{
			int rev = atoi(model+6);
			if(rev >= 3)	_DeviceGeneration = deviceiPadAir2;
		}

		// completely unknown hw - just determine form-factor
		if(_DeviceGeneration == deviceUnknown)
		{
			if (!strncmp(model, "iPhone",6))
				_DeviceGeneration = deviceiPhoneUnknown;
			else if (!strncmp(model, "iPad",4))
				_DeviceGeneration = deviceiPadUnknown;
			else if (!strncmp(model, "iPod",4))
				_DeviceGeneration = deviceiPodTouchUnknown;
			else
				_DeviceGeneration = deviceUnknown;
		}
	}
}

static void EstimateDeviceDPI()
{
	if (_DeviceDPI < 0.0f)
	{
		switch (UnityDeviceGeneration())
		{
			// iPhone
			case deviceiPhone:
			case deviceiPhone3G:
			case deviceiPhone3GS:
				_DeviceDPI = 163.0f; break;
			case deviceiPhone4:
			case deviceiPhone4S:
			case deviceiPhone5:
			case deviceiPhone5C:
			case deviceiPhone5S:
			case deviceiPhone6:
				_DeviceDPI = 326.0f; break;
			case deviceiPhone6Plus:
				_DeviceDPI = 401.0f; break;

			// iPad
			case deviceiPad1Gen:
			case deviceiPad2Gen:
				_DeviceDPI = 132.0f; break;
			case deviceiPad3Gen:
			case deviceiPad4Gen:		// iPad retina
			case deviceiPad5Gen:		// iPad air
			case deviceiPadAir2:
				_DeviceDPI = 264.0f; break;

			// iPad mini
			case deviceiPadMini1Gen:
				_DeviceDPI = 163.0f; break;
			case deviceiPadMini2Gen:
			case deviceiPadMini3Gen:
				_DeviceDPI = 326.0f; break;

			// iPod
			case deviceiPodTouch1Gen:
			case deviceiPodTouch2Gen:
			case deviceiPodTouch3Gen:
				_DeviceDPI = 163.0f; break;
			case deviceiPodTouch4Gen:
			case deviceiPodTouch5Gen:
				_DeviceDPI = 326.0f; break;

			// unknown (new) devices
			case deviceiPhoneUnknown:
				_DeviceDPI = 326.0f; break;
			case deviceiPadUnknown:
				_DeviceDPI = 264.0f; break;
			case deviceiPodTouchUnknown:
				_DeviceDPI = 326.0f; break;
		}
	}
}


//
// some higher-level helpers
//

extern "C" void QueryTargetResolution(int* targetW, int* targetH)
{
	enum
	{
		kTargetResolutionNative = 0,
		kTargetResolutionAutoPerformance = 3,
		kTargetResolutionAutoQuality = 4,
		kTargetResolution320p = 5,
		kTargetResolution640p = 6,
		kTargetResolution768p = 7
	};


	int targetRes = UnityGetTargetResolution();

	float resMult = 1.0f;
	if(targetRes == kTargetResolutionAutoPerformance)
	{
		switch(UnityDeviceGeneration())
		{
			case deviceiPhone4:		resMult = 0.6f;		break;
			case deviceiPad1Gen:	resMult = 0.5f;		break;
			default:				resMult = 0.75f;	break;
		}
	}

	if(targetRes == kTargetResolutionAutoQuality)
	{
		switch(UnityDeviceGeneration())
		{
			case deviceiPhone4:		resMult = 0.8f;		break;
			case deviceiPad1Gen:	resMult = 0.75f;	break;
			default:				resMult = 1.0f;		break;
		}
	}

	switch(targetRes)
	{
		case kTargetResolution320p:	*targetW = 320;	*targetH = 480;		break;
		case kTargetResolution640p:	*targetW = 640;	*targetH = 960;		break;
		case kTargetResolution768p:	*targetW = 768;	*targetH = 1024;	break;

		default:
			*targetW = GetMainDisplay()->screenSize.width * resMult;
			*targetH = GetMainDisplay()->screenSize.height * resMult;
			break;
	}
}


//
// gritty stuff
//

#if UNITY_PRE_IOS7_TARGET
	static void _InitDeviceIDPreIOS7()
	{
		static const int MD5_DIGEST_LENGTH = 16;

		// macaddr: courtesy of FreeBSD hackers email list
		int mib[6] = { CTL_NET, AF_ROUTE, 0, AF_LINK, NET_RT_IFLIST, 0 };
		mib[5] = ::if_nametoindex("en0");

		size_t len = 0;
		::sysctl(mib, 6, NULL, &len, NULL, 0);

		char* buf = (char*)::malloc(len);
		::sysctl(mib, 6, buf, &len, NULL, 0);

		sockaddr_dl*   sdl = (sockaddr_dl*)((if_msghdr*)buf + 1);
		unsigned char* mac = (unsigned char*)LLADDR(sdl);

		char macaddr_str[18]={0};
		::sprintf(macaddr_str, "%02X:%02X:%02X:%02X:%02X:%02X", *mac, *(mac+1), *(mac+2), *(mac+3), *(mac+4), *(mac+5));
		::free(buf);

		unsigned char hash_buf[MD5_DIGEST_LENGTH];
		CC_MD5(macaddr_str, sizeof(macaddr_str)-1, hash_buf);

		char uid_str[MD5_DIGEST_LENGTH*2 + 1] = {0};
		for(int i = 0 ; i < MD5_DIGEST_LENGTH ; ++i)
			::sprintf(uid_str + 2*i, "%02x", hash_buf[i]);

		_DeviceID = [[NSString stringWithUTF8String:uid_str] retain];
	}
#endif
