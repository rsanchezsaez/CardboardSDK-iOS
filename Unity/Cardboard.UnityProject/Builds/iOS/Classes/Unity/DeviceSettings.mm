
#include <sys/types.h>
#include <sys/sysctl.h>

#include <AdSupport/ASIdentifierManager.h>

#if UNITY_PRE_IOS7_TARGET
	#include <sys/socket.h>
	#include <net/if.h>
	#include <net/if_dl.h>
	#include <CommonCrypto/CommonDigest.h>

	static const char* _GetDeviceIDPreIOS7();
#endif

#include "DisplayManager.h"

// ad/vendor ids

static id QueryASIdentifierManager()
{
	NSBundle* bundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/AdSupport.framework"];
	if (bundle)
	{
		[bundle load];
		Class retClass = [bundle classNamed:@"ASIdentifierManager"];
		if (
			retClass
			&& [retClass respondsToSelector:@selector(sharedManager)]
			&& [retClass instancesRespondToSelector:@selector(advertisingIdentifier)]
			&& [retClass instancesRespondToSelector:@selector(isAdvertisingTrackingEnabled)]
		)
		{
			return [retClass performSelector:@selector(sharedManager)];
		}
	}

	return nil;
}

extern "C" const char* UnityAdvertisingIdentifier()
{
	static const char* _ADID = NULL;
	static const NSString* _ADIDNSString = nil;

	// ad id can be reset during app lifetime
	id manager = QueryASIdentifierManager();
	if (manager)
	{
		NSString* adid = [[manager performSelector:@selector(advertisingIdentifier)] UUIDString];
		// Do stuff to avoid UTF8String leaks. We still leak if ADID changes, but that shouldn't happen too often.
		if (![_ADIDNSString isEqualToString:adid])
		{
			_ADIDNSString = adid;
			free((void*)_ADID);
			_ADID = AllocCString(adid);
		}
	}

	return _ADID;
}

extern "C" int UnityAdvertisingTrackingEnabled()
{
	bool _AdTrackingEnabled = false;

	// ad tracking can be changed during app lifetime
	id manager = QueryASIdentifierManager();
	if(manager)
		_AdTrackingEnabled = [manager performSelector:@selector(isAdvertisingTrackingEnabled)];

	return _AdTrackingEnabled ? 1 : 0;
}

extern "C" const char* UnityVendorIdentifier()
{
	static const char*	_VendorID			= NULL;

	if(_VendorID == NULL)
		_VendorID = AllocCString([[UIDevice currentDevice].identifierForVendor UUIDString]);

	return _VendorID;
}


// UIDevice properties

#define QUERY_UIDEVICE_PROPERTY(FUNC, PROP)											\
	extern "C" const char* FUNC()													\
	{																				\
		static const char* value = NULL;											\
		if (value == NULL && [UIDevice instancesRespondToSelector:@selector(PROP)])	\
			value = AllocCString([UIDevice currentDevice].PROP);					\
		return value;																\
	}

QUERY_UIDEVICE_PROPERTY(UnityDeviceName, name)
QUERY_UIDEVICE_PROPERTY(UnitySystemName, systemName)
QUERY_UIDEVICE_PROPERTY(UnitySystemVersion, systemVersion)

#undef QUERY_UIDEVICE_PROPERTY

// hw info

extern "C" const char* UnityDeviceModel()
{
	static const char* _DeviceModel = NULL;

	if(_DeviceModel == NULL)
	{
		size_t size;
		::sysctlbyname("hw.machine", NULL, &size, NULL, 0);

		char* model = (char*)::malloc(size + 1);
		::sysctlbyname("hw.machine", model, &size, NULL, 0);
		model[size] = 0;

		_DeviceModel = AllocCString([NSString stringWithUTF8String:model]);
		::free(model);
	}

	return _DeviceModel;
}

extern "C" int UnityDeviceCPUCount()
{
	static int _DeviceCPUCount = -1;

	if(_DeviceCPUCount <= 0)
	{
		// maybe would be better to use HW_AVAILCPU
		int		ctlName[]	= {CTL_HW, HW_NCPU};
		size_t	dataLen		= sizeof(_DeviceCPUCount);

		::sysctl(ctlName, 2, &_DeviceCPUCount, &dataLen, NULL, 0);
	}
	return _DeviceCPUCount;
}

// misc
extern "C" const char* UnitySystemLanguage()
{
	static const char* _SystemLanguage = NULL;

	if(_SystemLanguage == NULL)
	{
		NSArray* lang = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
		if(lang.count > 0)
			_SystemLanguage = AllocCString(lang[0]);
	}

	return _SystemLanguage;
}

extern "C" int UnityDeviceGeneration()
{
	static int _DeviceGeneration = deviceUnknown;

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
		else if (!strcmp(model, "iPod4,1"))
			_DeviceGeneration = deviceiPodTouch4Gen;
		else if (!strncmp(model, "iPod5,",6))
			_DeviceGeneration = deviceiPodTouch5Gen;
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
			else			_DeviceGeneration = deviceiPadAir1;
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
	return _DeviceGeneration;
}

extern "C" float UnityDeviceDPI()
{
	static float _DeviceDPI	= -1.0f;

	if (_DeviceDPI < 0.0f)
	{
		switch (UnityDeviceGeneration())
		{
			// iPhone
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
			case deviceiPad2Gen:
				_DeviceDPI = 132.0f; break;
			case deviceiPad3Gen:
			case deviceiPad4Gen:        // iPad retina
			case deviceiPadAir1:
			case deviceiPadAir2:
				_DeviceDPI = 264.0f; break;

			// iPad mini
			case deviceiPadMini1Gen:
				_DeviceDPI = 163.0f; break;
			case deviceiPadMini2Gen:
			case deviceiPadMini3Gen:
				_DeviceDPI = 326.0f; break;

			// iPod
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

	return _DeviceDPI;
}



// device id with fallback for pre-ios7

extern "C" const char* UnityDeviceUniqueIdentifier()
{
	static const char* _DeviceID = NULL;

	if(_DeviceID == NULL)
	{
	#if UNITY_PRE_IOS7_TARGET
		if(!_ios70orNewer)
			_DeviceID = _GetDeviceIDPreIOS7();
	#endif

		// first check vendor id
		if(_DeviceID == NULL)
			_DeviceID = UnityVendorIdentifier();
	}
	return _DeviceID;
}

#if UNITY_PRE_IOS7_TARGET
	static const char* _GetDeviceIDPreIOS7()
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

		return strdup(uid_str);
	}
#endif


// target resolution selector for "auto" values

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
			default:				resMult = 0.75f;	break;
		}
	}

	if(targetRes == kTargetResolutionAutoQuality)
	{
		switch(UnityDeviceGeneration())
		{
			case deviceiPhone4:		resMult = 0.8f;		break;
			default:				resMult = 1.0f;		break;
		}
	}

	switch(targetRes)
	{
		case kTargetResolution320p:	*targetW = 320;	*targetH = 480;		break;
		case kTargetResolution640p:	*targetW = 640;	*targetH = 960;		break;
		case kTargetResolution768p:	*targetW = 768;	*targetH = 1024;	break;

		default:
			*targetW = GetMainDisplay().screenSize.width * resMult;
			*targetH = GetMainDisplay().screenSize.height * resMult;
			break;
	}
}
