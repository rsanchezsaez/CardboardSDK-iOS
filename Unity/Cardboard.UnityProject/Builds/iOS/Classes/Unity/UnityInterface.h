
#ifndef _TRAMPOLINE_UNITY_UNITYINTERFACE_H_
#define _TRAMPOLINE_UNITY_UNITYINTERFACE_H_

#include "iPhone_Common.h"

#ifdef __OBJC__
	@class UIScreen;
	@class UIWindow;
	@class UIView;
	@class UIViewController;
	@class UIEvent;
	@class UILocalNotification;
	@class NSDictionary;
	@class NSSet;
	@class NSError;
	@class NSData;
#else
	typedef struct objc_object UIScreen;
	typedef struct objc_object UIWindow;
	typedef struct objc_object UIView;
	typedef struct objc_object UIViewController;
	typedef struct objc_object UIEvent;
	typedef struct objc_object UILocalNotification;
	typedef struct objc_object NSDictionary;
	typedef struct objc_object NSSet;
	typedef struct objc_object NSError;
	typedef struct objc_object NSData;
#endif

// unity plugin functions
typedef	void	(*UnityPluginSetGraphicsDeviceFunc)(void* device, int deviceType, int eventType);
typedef	void	(*UnityPluginRenderMarkerFunc)(int marker);


//
// these are functions referenced in trampoline and implemented in unity player lib
//

#ifdef __cplusplus
extern "C" {
#endif

// life cycle management
#ifdef __cplusplus
	extern bool		UnityParseCommandLine(int argc, char* argv[]);
	extern void		UnitySetPlayerFocus(bool focused); // send OnApplicationFocus() message to scripts
	extern void		UnityPause(bool pause);
#endif

extern void		UnityInitApplicationNoGraphics(const char* appPathName);
extern void		UnityInitApplicationGraphics();
extern void		UnityCleanup();
extern void		UnityLoadApplication();
extern void		UnityPlayerLoop();
extern void		UnityForcedPlayerLoop();
extern int		UnityIsPaused();					// 0 if player is running, 1 if paused
extern void		UnityInputProcess();


// rendering
#ifdef __cplusplus
	extern bool		UnityIsRenderingAPISupported(int renderingApi);
	extern bool		UnityHasRenderingAPIExtension(const char* extension);
	extern void*	UnityCreateUpdateExternalColorSurface(int api, void* surf, unsigned texid, unsigned rbid, int width, int height, bool is32bit, int samples, bool backbuffer);
	extern void*	UnityCreateUpdateExternalDepthSurface(int api, void* surf, unsigned texid, unsigned rbid, int width, int height, bool is24bit, int samples, bool backbuffer);
#endif

extern void		UnityFinishRendering();
extern void		UnityDestroyExternalColorSurface(int api, void* surf);
extern void		UnityDestroyExternalDepthSurface(int api, void* surf);
extern void		UnityDisableRenderBuffers(void* color, void* depth);
extern void		UnityRegisterFBO(int api, void* color, void* depth, unsigned fbo);
extern void		UnitySetDefaultFBO(int api, void* color, void* depth);


// plugins support
extern void		UnityRegisterRenderingPlugin(UnityPluginSetGraphicsDeviceFunc setDevice, UnityPluginRenderMarkerFunc renderMarker);


// controling player internals
#ifdef __cplusplus
	extern void		UnitySetAudioSessionActive(bool active);
	extern bool		UnityIsCaptureScreenshotRequested();
#endif

extern void		UnityGLInvalidateState();
extern void		UnityReloadResources();
extern void		UnityBlitToSystemFB(unsigned tex, unsigned w, unsigned h, unsigned sysw, unsigned sysh);
extern void		UnityCaptureScreenshot();


// resolution handling

extern void		UnityGetRenderingResolution(unsigned* w, unsigned* h);
extern void		UnityGetSystemResolution(unsigned* w, unsigned* h);
extern void		UnityReportResizeView(unsigned w, unsigned h, unsigned /*ScreenOrientation*/ contentOrientation);
extern void		UnityReportBackbufferChange(unsigned w, unsigned h);

extern void		UnityRequestRenderingResolution(unsigned w, unsigned h);

// orientation handling
#ifdef __cplusplus
	extern bool		UnityIsOrientationEnabled(int/*EnabledOrientation*/ orientation);
#endif

extern int		UnityRequestedScreenOrientation(); // returns ScreenOrientation


// player settings
#ifdef __cplusplus
	extern bool		UnityUse32bitDisplayBuffer();
	extern bool		UnityUse24bitDepthBuffer();
	extern bool		UnityUseAnimatedAutorotation();
#endif

extern int		UnityGetDesiredMSAASampleCount(int defaultSampleCount);
extern int		UnityGetTargetResolution();
extern int		UnityGetShowActivityIndicatorOnLoading();
extern int		UnityGetAccelerometerFrequency();
extern int		UnityGetTargetFPS();


// push notifications
extern void		UnitySendLocalNotification(UILocalNotification* notification);
extern void		UnitySendRemoteNotification(NSDictionary* notification);
extern void		UnitySendDeviceToken(NSData* deviceToken);
extern void		UnitySendRemoteNotificationError(NSError* error);


// native events
extern void		UnityADBannerViewWasClicked();
extern void		UnityADBannerViewWasLoaded();
extern void 	UnityADInterstitialADWasLoaded();
extern void		UnityUpdateDisplayList();


// profiler
extern void*	UnityCreateProfilerCounter(const char*);
extern void		UnityDestroyProfilerCounter(void*);
extern void		UnityStartProfilerCounter(void*);
extern void		UnityEndProfilerCounter(void*);


// sensors
extern void		UnitySensorsSetGyroRotationRate(int idx, float x, float y, float z);
extern void		UnitySensorsSetGyroRotationRateUnbiased(int idx, float x, float y, float z);
extern void		UnitySensorsSetGravity(int idx, float x, float y, float z);
extern void		UnitySensorsSetUserAcceleration(int idx, float x, float y, float z);
extern void		UnitySensorsSetAttitude(int idx, float x, float y, float z, float w);
extern void		UnityDidAccelerate(float x, float y, float z, double timestamp);
extern void 	UnitySetJoystickPosition (int joyNum, int axis, float pos);
extern int 		UnityStringToKey(const char *name);
#ifdef __cplusplus
extern void 	UnitySetKeyState (int key, bool state);
#endif

// WWW connection handling
extern void		UnityReportWWWStatusError(void* udata, int status, const char* error);
extern void		UnityReportWWWFailedWithError(void* udata, const char* error);

extern void		UnityReportWWWReceivedResponse(void* udata, int status, unsigned expectedDataLength, const char* respHeader);
extern void		UnityReportWWWReceivedData(void* udata, unsigned totalRead, unsigned expectedTotal);
extern void		UnityReportWWWFinishedLoadingData(void* udata);
extern void		UnityReportWWWSentData(void* udata, unsigned totalWritten, unsigned expectedTotal);

#ifdef __cplusplus
}
#endif


// touches processing

// this dictates touches processing on os level: should we transform touches to unity view coords or not.
// N.B. touch.position will always be adjusted to current resolution
//		i.e. if you touch right border of view, touch.position.x will be Screen.width, not view.width
//		to get coords in view space (os-coords), use touch.rawPosition
typedef enum
ViewTouchProcessing
{
	// the touches originated from view will be ignored by unity
	touchesIgnored = 0,

	// touches would be processed as if they were originated in unity view:
	// coords will be transformed from view coords to unity view coords
	touchesTransformedToUnityViewCoords = 1,

	// touches coords will be kept intact (in originated view coords)
	// it is default value
	touchesKeptInOriginalViewCoords = 2,
}
ViewTouchProcessing;


#ifdef __cplusplus
extern "C" {
#endif

extern void		UnitySetViewTouchProcessing(UIView* view, int/*ViewTouchProcessing*/ processingPolicy);
extern void		UnityDropViewTouchProcessing(UIView* view);

extern void		UnitySendTouchesBegin(NSSet* touches, UIEvent* event);
extern void		UnitySendTouchesEnded(NSSet* touches, UIEvent* event);
extern void		UnitySendTouchesCancelled(NSSet* touches, UIEvent* event);
extern void		UnitySendTouchesMoved(NSSet* touches, UIEvent* event);

#ifdef __cplusplus
}
#endif


//
// these are functions referenced and implemented in trampoline
//

#ifdef __cplusplus
extern "C" {
#endif

UIViewController*		UnityGetGLViewController();
UIView*					UnityGetGLView();
UIWindow*				UnityGetMainWindow();
enum ScreenOrientation	UnityCurrentOrientation();

// Unity/DisplayManager.mm
float					UnityScreenScaleFactor(UIScreen* screen);

#ifdef __cplusplus
}
#endif


//
// these are functions referenced in unity player lib and implemented in trampoline
//

// iPhone_Sensors.mm
// extern "C" void	UnityCoreMotionStart();
// extern "C" void	UnityCoreMotionStop();
// extern "C" bool	IsGyroEnabled(int idx);
// extern "C" bool	IsGyroAvailable();
// extern "C" void	UnityUpdateGyroData();
// extern "C" void	UnitySetGyroUpdateInterval(int idx, float interval);
// extern "C" float	UnityGetGyroUpdateInterval(int idx);


// UnityAppController.mm
// extern "C" int	CreateContext_UnityCallback(UIWindow** window, int* screenWidth, int* screenHeight, int* openglesVersion);

// UnityAppController+Rendering.mm
// extern "C" void	GfxInited_UnityCallback();
// extern "C" void	PresentContext_UnityCallback(struct UnityFrameStats const* frameStats);
// extern "C" void	FramerateChange_UnityCallback(int targetFPS)


// UI/ActivityIndicator.mm
// extern "C" void	UnityStartActivityIndicator();
// extern "C" void	UnityStopActivityIndicator();

// UI/UnityViewControllerBase.mm
// extern "C" void	NotifyAutoOrientationChange();

// DeviceSettings.mm
// extern "C" const char*	UnityDeviceUniqueIdentifier();
// extern "C" const char*	UnityVendorIdentifier();
// extern "C" const char*	UnityAdvertisingIdentifier();
// extern "C" const char*	UnityDeviceName();
// extern "C" const char*	UnitySystemName();
// extern "C" const char*	UnitySystemVersion();
// extern "C" const char*	UnityDeviceModel();
// extern "C" int			UnityDeviceGeneration()
// extern "C" float			UnityDeviceDPI()

// Unity/WWWConnection.mm
// extern "C" void*			UnityStartWWWConnectionGet(void* udata, const void* headerDict, const char* url);
// extern "C" void*			UnityStartWWWConnectionPost(void* udata, const void* headerDict, const char* url, const void* data, unsigned length);
// extern "C" void			UnityDestroyWWWConnection(void* connection);
// extern "C" void			UnityShouldCancelWWW(const void* connection);
// extern "C" const void*	UnityGetWWWData(const void* connection);
// extern "C" int			UnityGetWWWDataLength(const void* connection);
// extern "C" const char*	UnityGetWWWURL(const void* connection);


#endif // _TRAMPOLINE_UNITY_UNITYINTERFACE_H_
