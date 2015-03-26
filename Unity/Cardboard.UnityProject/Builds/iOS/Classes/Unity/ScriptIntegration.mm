#import <Foundation/Foundation.h>

//==============================================================================
//
//  Unity Interface:

extern "C" void UnityNSObject_RetainObject(void* obj)	{ [(NSObject*)obj retain]; }
extern "C" void UnityNSObject_ReleaseObject(void* obj)	{ [(NSObject*)obj release]; }


extern "C" int UnityNSError_Code(void* errorObj)
{
	return (int)[(NSError*)errorObj code];
}
extern "C" const char* UnityNSError_Description(void* errorObj)
{
	return [[(NSError*)errorObj localizedDescription] UTF8String];
}
extern "C" const char* UnityNSError_Reason(void* errorObj)
{
	return [[(NSError*)errorObj localizedFailureReason] UTF8String];
}


extern "C" const char* UnityNSNotification_Name(void* notificationObj)
{
	return [[(NSNotification*)notificationObj name] UTF8String];
}
