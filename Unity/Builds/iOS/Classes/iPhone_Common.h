
#ifndef _TRAMPOLINE_IPHONE_COMMON_H_
#define _TRAMPOLINE_IPHONE_COMMON_H_

#include "Preprocessor.h"
#include <stdarg.h>


//------------------------------------------------------------------------------

// ios/sdk version
#ifdef __cplusplus
	extern	bool	_ios42orNewer;
	extern	bool	_ios43orNewer;
	extern	bool	_ios50orNewer;
	extern	bool	_ios60orNewer;
	extern	bool	_ios70orNewer;
	extern	bool	_ios80orNewer;
#endif


//------------------------------------------------------------------------------

typedef enum
DeviceGeneration
{
	deviceUnknown = 0,
	deviceiPhone = 1,
	deviceiPhone3G = 2,
	deviceiPhone3GS = 3,
	deviceiPodTouch1Gen = 4,
	deviceiPodTouch2Gen = 5,
	deviceiPodTouch3Gen = 6,
	deviceiPad1Gen = 7,
	deviceiPhone4 = 8,
	deviceiPodTouch4Gen = 9,
	deviceiPad2Gen = 10,
	deviceiPhone4S = 11,
	deviceiPad3Gen = 12,
	deviceiPhone5 = 13,
	deviceiPodTouch5Gen = 14,
	deviceiPadMini1Gen = 15,
	deviceiPad4Gen = 16,
	deviceiPhone5C = 17,
	deviceiPhone5S = 18,
	deviceiPad5Gen = 19,
	deviceiPadMini2Gen = 20,
	deviceiPhone6 = 21,
	deviceiPhone6Plus = 22,
	deviceiPadMini3Gen = 23,
	deviceiPadAir2 = 24,

	deviceiPhoneUnknown = 10001,
	deviceiPadUnknown = 10002,
	deviceiPodTouchUnknown = 10003,
}
DeviceGeneration;

typedef enum
ScreenOrientation
{
    orientationUnknown,
    portrait,
    portraitUpsideDown,
    landscapeLeft,
    landscapeRight,
    autorotation,
    orientationCount
}
ScreenOrientation;

typedef enum
EnabledOrientation
{
    autorotPortrait = 1,
    autorotPortraitUpsideDown = 2,
    autorotLandscapeLeft = 4,
    autorotLandscapeRight = 8
}
EnabledOrientation;


struct UnityFrameStats;


typedef enum
LogType
{
	/// LogType used for Errors.
	LogType_Error = 0,
    /// LogType used for Asserts. (These indicate an error inside Unity itself.)
	LogType_Assert = 1,
    /// LogType used for Warnings.
	LogType_Warning = 2,
    /// LogType used for regular log messages.
	LogType_Log = 3,
    /// LogType used for Exceptions.
	LogType_Exception = 4,
    /// LogType used for Debug.
	LogType_Debug = 5,
	///
	LogType_NumLevels
}
LogType;


#ifdef __cplusplus
	typedef bool (*LogEntryHandler) (LogType logType, const char* log, va_list list);
	void SetLogEntryHandler(LogEntryHandler newHandler);
#endif


#endif // _TRAMPOLINE_IPHONE_COMMON_H_
