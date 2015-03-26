#pragma once

#include <stdint.h>
#include <stdarg.h>

#include "UnityForwardDecls.h"
#include "UnityRendering.h"

// unity plugin functions
typedef	void	(*UnityPluginSetGraphicsDeviceFunc)(void* device, int deviceType, int eventType);
typedef	void	(*UnityPluginRenderMarkerFunc)(int marker);
typedef int     (*UnityPluginGetAudioEffectDefinitionsFunc)(struct UnityAudioEffectDefinition*** descptr);

// log handler function
#ifdef __cplusplus
	typedef bool (*LogEntryHandler)(LogType logType, const char* log, va_list list);
#endif

//
// these are functions referenced in trampoline and implemented in unity player lib
//

#ifdef __cplusplus
extern "C" {
#endif

// life cycle management

void	UnityParseCommandLine(int argc, char* argv[]);
void	UnityInitApplicationNoGraphics(const char* appPathName);
void	UnityInitApplicationGraphics();
void	UnityCleanup();
void	UnityLoadApplication();
void	UnityPlayerLoop();					// normal player loop
void	UnityBatchPlayerLoop();				// batch mode like player loop, without rendering (usable for background processing)
void	UnitySetPlayerFocus(int focused);	// send OnApplicationFocus() message to scripts
void	UnityPause(int pause);
int		UnityIsPaused();					// 0 if player is running, 1 if paused
void	UnityWillPause();					// send the message that app will pause
void	UnityWillResume();					// send the message that app will resume
void	UnityOnApplicationWillResignActive();
void	UnityInputProcess();


// rendering

int		UnityIsRenderingAPISupported(int renderingApi);
int		UnityHasRenderingAPIExtension(const char* extension);
void	UnityFinishRendering();

// for Create* functions if surf is null we will actuially create new one, otherwise we update the one provided
// gles: one and only one of texid/rbid should be non-zero
// metal: resolveTex should be non-nil only if tex have AA
UnityRenderBuffer	UnityCreateExternalSurfaceGLES(UnityRenderBuffer surf, int isColor, unsigned texid, unsigned rbid, unsigned glesFormat, const UnityRenderBufferDesc* desc);
UnityRenderBuffer	UnityCreateExternalSurfaceMTL(UnityRenderBuffer surf, int isColor, MTLTextureRef tex, const UnityRenderBufferDesc* desc);
UnityRenderBuffer	UnityCreateExternalColorSurfaceMTL(UnityRenderBuffer surf, MTLTextureRef tex, MTLTextureRef resolveTex, const UnityRenderBufferDesc* desc);
UnityRenderBuffer	UnityCreateExternalDepthSurfaceMTL(UnityRenderBuffer surf, MTLTextureRef tex, MTLTextureRef stencilTex, const UnityRenderBufferDesc* desc);
UnityRenderBuffer	UnityCreateDummySurface(int api, UnityRenderBuffer surf, int isColor, const UnityRenderBufferDesc* desc);
void				UnityDestroyExternalSurface(int api, UnityRenderBuffer surf);

void	UnityDisableRenderBuffers(UnityRenderBuffer color, UnityRenderBuffer depth);
void	UnityRegisterFBO(UnityRenderBuffer color, UnityRenderBuffer depth, unsigned fbo);
void	UnitySetAsDefaultFBO(UnityRenderBuffer color, UnityRenderBuffer depth);
void	UnitySetFBO(UnityRenderBuffer color, UnityRenderBuffer depth);


void	UnityStartMetalFrame(UnityRenderBuffer colorRB, UnityRenderBuffer depthRB, int frameNumber);
MTLCommandBufferRef UnityPrepareEndMetalFrame();
void	UnityFinishedMetalFrame(int frameNumber);
void	UnitySetAsDefaultFBOMetal(UnityRenderBuffer color, UnityRenderBuffer depth);
void	UnitySetFBOMetal(UnityRenderBuffer color, UnityRenderBuffer depth);
void	UnityBlitToSystemFBOMetal(MTLTextureRef bltex, unsigned w, unsigned h, unsigned sysw, unsigned sysh);


// controling player internals

// TODO: needs some cleanup
void	UnitySetAudioSessionActive(int active);
void	UnityGLInvalidateState();
void	UnityReloadResources();
void	UnityBlitToSystemFB(unsigned tex, unsigned w, unsigned h, unsigned sysw, unsigned sysh);
int		UnityIsCaptureScreenshotRequested();
void	UnityCaptureScreenshot();
void	UnitySendMessage(const char* obj, const char* method, const char* msg);

EAGLContext*		UnityGetDataContextGLES();
MTLCommandBufferRef	UnityGetCommandBufferMetal();

#ifdef __cplusplus
	void	UnitySetLogEntryHandler(LogEntryHandler newHandler);
#endif


// plugins support

void	UnityRegisterRenderingPlugin(UnityPluginSetGraphicsDeviceFunc setDevice, UnityPluginRenderMarkerFunc renderMarker);
void	UnityRegisterAudioPlugin(UnityPluginGetAudioEffectDefinitionsFunc getAudioEffectDefinitions);


// resolution/orientation handling

void	UnityGetRenderingResolution(unsigned* w, unsigned* h);
void	UnityGetSystemResolution(unsigned* w, unsigned* h);

void	UnityRequestRenderingResolution(unsigned w, unsigned h);

int		UnityIsOrientationEnabled(unsigned /*ScreenOrientation*/ orientation);
int		UnityShouldAutorotate();
int		UnityRequestedScreenOrientation(); // returns ScreenOrientation

int		UnityReportResizeView(unsigned w, unsigned h, unsigned /*ScreenOrientation*/ contentOrientation);	// returns ScreenOrientation
void	UnityReportBackbufferChange(UnityRenderBuffer colorBB, UnityRenderBuffer depthBB);



// player settings

int		UnityDisableDepthAndStencilBuffers();
int		UnityUseAnimatedAutorotation();
int		UnityGetDesiredMSAASampleCount(int defaultSampleCount);
int		UnityGetSRGBRequested();
int		UnityGetTargetResolution();
int		UnityGetShowActivityIndicatorOnLoading();
int		UnityGetAccelerometerFrequency();
int		UnityGetTargetFPS();
int		UnityGetAppBackgroundBehavior();


// push notifications

void	UnitySendLocalNotification(UILocalNotification* notification);
void	UnitySendRemoteNotification(NSDictionary* notification);
void	UnitySendDeviceToken(NSData* deviceToken);
void	UnitySendRemoteNotificationError(NSError* error);


// native events

void	UnityADBannerViewWasClicked();
void	UnityADBannerViewWasLoaded();
void	UnityADInterstitialADWasLoaded();
void	UnityUpdateDisplayList();


// profiler

void*	UnityCreateProfilerCounter(const char*);
void	UnityDestroyProfilerCounter(void*);
void	UnityStartProfilerCounter(void*);
void	UnityEndProfilerCounter(void*);


// sensors

void	UnitySensorsSetGyroRotationRate(int idx, float x, float y, float z);
void	UnitySensorsSetGyroRotationRateUnbiased(int idx, float x, float y, float z);
void	UnitySensorsSetGravity(int idx, float x, float y, float z);
void	UnitySensorsSetUserAcceleration(int idx, float x, float y, float z);
void	UnitySensorsSetAttitude(int idx, float x, float y, float z, float w);
void	UnityDidAccelerate(float x, float y, float z, double timestamp);
void	UnitySetJoystickPosition (int joyNum, int axis, float pos);
int		UnityStringToKey(const char *name);
void	UnitySetKeyState (int key, int /*bool*/ state);

// WWW connection handling

void	UnityReportWWWStatusError(void* udata, int status, const char* error);
void	UnityReportWWWFailedWithError(void* udata, const char* error);

void	UnityReportWWWReceivedResponse(void* udata, int status, unsigned expectedDataLength, const char* respHeader);
void	UnityReportWWWReceivedData(void* udata, unsigned totalRead, unsigned expectedTotal);
void	UnityReportWWWFinishedLoadingData(void* udata);
void	UnityReportWWWSentData(void* udata, unsigned totalWritten, unsigned expectedTotal);

// AVCapture

void	UnityReportAVCapturePermission();
void	UnityDidCaptureVideoFrame(intptr_t tex, void* udata);

// logging override

#ifdef __cplusplus
} // extern "C"
#endif


// touches processing

#ifdef __cplusplus
extern "C" {
#endif

void	UnitySetViewTouchProcessing(UIView* view, int /*ViewTouchProcessing*/ processingPolicy);
void	UnityDropViewTouchProcessing(UIView* view);

void	UnitySendTouchesBegin(NSSet* touches, UIEvent* event);
void	UnitySendTouchesEnded(NSSet* touches, UIEvent* event);
void	UnitySendTouchesCancelled(NSSet* touches, UIEvent* event);
void	UnitySendTouchesMoved(NSSet* touches, UIEvent* event);

#ifdef __cplusplus
} // extern "C"
#endif


//
// these are functions referenced and implemented in trampoline
//

#ifdef __cplusplus
extern "C" {
#endif

// UnityAppController.mm
UIViewController*		UnityGetGLViewController();
UIView*					UnityGetGLView();
UIWindow*				UnityGetMainWindow();
enum ScreenOrientation	UnityCurrentOrientation();

// Unity/DisplayManager.mm
float					UnityScreenScaleFactor(UIScreen* screen);

#ifdef __cplusplus
} // extern "C"
#endif


//
// these are functions referenced in unity player lib and implemented in trampoline
//

#ifdef __cplusplus
extern "C" {
#endif

// iPhone_Sensors.mm
void			UnityInitJoysticks();
void			UnityCoreMotionStart();
void			UnityCoreMotionStop();
int				UnityIsGyroEnabled(int idx);
int				UnityIsGyroAvailable();
void			UnityUpdateGyroData();
void			UnitySetGyroUpdateInterval(int idx, float interval);
float			UnityGetGyroUpdateInterval(int idx);
void			UnityUpdateJoystickData();
int				UnityGetJoystickCount();
void			UnityGetJoystickName(int idx, char* buffer, int maxLen);
void			UnityGetJoystickAxisName(int idx, int axis, char* buffer, int maxLen);
void			UnityGetNiceKeyname(int key, char* buffer, int maxLen);

// UnityAppController+Rendering.mm
void			UnityInitMainScreenRenderingCallback(int* screenWidth, int* screenHeight);
void			UnityGfxInitedCallback();
void			UnityPresentContextCallback(struct UnityFrameStats const* frameStats);
void			UnityFramerateChangeCallback(int targetFPS);
int				UnitySelectedRenderingAPI();

NSBundle*			UnityGetMetalBundle();
MTLDeviceRef		UnityGetMetalDevice();
MTLCommandQueueRef	UnityGetMetalCommandQueue();
EAGLContext*		UnityGetDataContextEAGL();

// UI/ActivityIndicator.mm
void			UnityStartActivityIndicator();
void			UnityStopActivityIndicator();

// UI/Keyboard.mm
void			UnityKeyboard_Show(unsigned keyboardType, int autocorrection, int multiline, int secure, int alert, const char* text, const char* placeholder);
void			UnityKeyboard_Hide();
void			UnityKeyboard_GetRect(float* x, float* y, float* w, float* h);
void			UnityKeyboard_SetText(const char* text);
NSString*		UnityKeyboard_GetText();
int				UnityKeyboard_IsActive();
int				UnityKeyboard_IsDone();
int				UnityKeyboard_WasCanceled();
void			UnityKeyboard_SetInputHidden(int hidden);
int				UnityKeyboard_IsInputHidden();

// UI/UnityViewControllerBase.mm
void			UnityNotifyAutoOrientationChange();

// Unity/AVCapture.mm
int				UnityGetAVCapturePermission(int captureTypes);
void			UnityRequestAVCapturePermission(int captureTypes);

// Unity/CameraCapture.mm
void			UnityEnumVideoCaptureDevices(void* udata, void(*callback)(void* udata, const char* name, int frontFacing));
void*			UnityInitCameraCapture(int device, int w, int h, int fps, void* udata);
void			UnityStartCameraCapture(void* capture);
void			UnityPauseCameraCapture(void* capture);
void			UnityStopCameraCapture(void* capture);
void			UnityCameraCaptureExtents(void* capture, int* w, int* h);
void			UnityCameraCaptureReadToMemory(void* capture, void* dst, int w, int h);
int				UnityCameraCaptureVideoRotationDeg(void* capture);
int				UnityCameraCaptureVerticallyMirrored(void* capture);


// Unity/DeviceSettings.mm
const char*		UnityDeviceUniqueIdentifier();
const char*		UnityVendorIdentifier();
const char*		UnityAdvertisingIdentifier();
int				UnityAdvertisingTrackingEnabled();
const char*		UnityDeviceName();
const char*		UnitySystemName();
const char*		UnitySystemVersion();
const char*		UnityDeviceModel();
int				UnityDeviceCPUCount();
int				UnityDeviceGeneration();
float			UnityDeviceDPI();
const char*		UnitySystemLanguage();

// Unity/DisplayManager.mm
EAGLContext*	UnityGetMainScreenContextGLES();
EAGLContext*	UnityGetContextEAGL(int);

// Unity/Filesystem.mm
const char*		UnityApplicationDir();
const char*		UnityDocumentsDir();
const char*		UnityLibraryDir();
const char*		UnityCachesDir();
int				UnityUpdateNoBackupFlag(const char* path, int setFlag); // Returns 1 if successful, otherwise 0

// Unity/WWWConnection.mm
void*			UnityStartWWWConnectionGet(void* udata, const void* headerDict, const char* url);
void*			UnityStartWWWConnectionPost(void* udata, const void* headerDict, const char* url, const void* data, unsigned length);
void			UnityDestroyWWWConnection(void* connection);
void			UnityShouldCancelWWW(const void* connection);
const void*		UnityGetWWWData(const void* connection);
int				UnityGetWWWDataLength(const void* connection);
const char*		UnityGetWWWURL(const void* connection);

#ifdef __cplusplus
} // extern "C"
#endif


#ifdef __OBJC__
	// This is basically a wrapper for [NSString UTF8String] with additional strdup.
	//
	// Apparently multiple calls on UTF8String will leak memory (NSData objects) that are collected
	// only when @autoreleasepool is exited. This function serves as documentation for this and as a
	// handy wrapper.
	inline char* AllocCString(NSString* value)
	{
		if(value == nil)
			return 0;

		const char* str = [value UTF8String];
		return str ? strdup(str) : 0;
	}
#endif
