#pragma once

#include <stdint.h>

#ifdef __OBJC__
	@class UIScreen;
	@class UIWindow;
	@class UIView;
	@class UIViewController;
	@class UIEvent;
	@class UILocalNotification;
	@class NSString;
	@class NSDictionary;
	@class NSSet;
	@class NSData;
	@class NSError;
	@class NSBundle;

	@class UnityViewControllerBase;
#else
	typedef struct objc_object UIScreen;
	typedef struct objc_object UIWindow;
	typedef struct objc_object UIView;
	typedef struct objc_object UIViewController;
	typedef struct objc_object UIEvent;
	typedef struct objc_object UILocalNotification;
	typedef struct objc_object NSString;
	typedef struct objc_object NSDictionary;
	typedef struct objc_object NSSet;
	typedef struct objc_object NSError;
	typedef struct objc_object NSData;
	typedef struct objc_object NSBundle;

	typedef struct objc_object UnityViewControllerBase;
#endif

#ifdef __OBJC__
	@class CAEAGLLayer;
	@class EAGLContext;
#else
	typedef struct objc_object CAEAGLLayer;
	typedef struct objc_object EAGLContext;
#endif

#ifdef __OBJC__
	@class CAMetalLayer;
	@protocol CAMetalDrawable;
	@protocol MTLDrawable;
	@protocol MTLDevice;
	@protocol MTLTexture;
	@protocol MTLCommandBuffer;
	@protocol MTLCommandQueue;

	typedef id<CAMetalDrawable>		CAMetalDrawableRef;
	typedef id<MTLDevice>			MTLDeviceRef;
	typedef id<MTLTexture>			MTLTextureRef;
	typedef id<MTLCommandBuffer>	MTLCommandBufferRef;
	typedef id<MTLCommandQueue>		MTLCommandQueueRef;
#else
	typedef struct objc_object		CAMetalLayer;
	typedef struct objc_object*		CAMetalDrawableRef;
	typedef struct objc_object*		MTLDeviceRef;
	typedef struct objc_object*		MTLTextureRef;
	typedef struct objc_object*		MTLCommandBufferRef;
	typedef struct objc_object*		MTLCommandQueueRef;
#endif


// unity internal audio effect definition struct
struct UnityAudioEffectDefinition;


// unity internal render buffer struct
struct RenderSurfaceBase;
typedef struct RenderSurfaceBase* UnityRenderBuffer;


// be aware that this struct is shared with unity implementation so you should absolutely not change it
typedef struct
UnityRenderBufferDesc
{
	unsigned	width, height;
	unsigned	samples;

	int			backbuffer;
}
UnityRenderBufferDesc;


// be aware that this struct is shared with unity implementation so you should absolutely not change it
struct UnityFrameStats
{
	uint64_t	fixedBehaviourManagerDt;
	uint64_t	fixedPhysicsManagerDt;
	uint64_t	dynamicBehaviourManagerDt;
	uint64_t	coroutineDt;
	uint64_t	skinMeshUpdateDt;
	uint64_t	animationUpdateDt;
	uint64_t	renderDt;
	uint64_t	cullingDt;
	uint64_t	clearDt;
	int			fixedUpdateCount;

	int			batchCount;
	uint64_t	drawCallTime;
	int			drawCallCount;
	int			triCount;
	int			vertCount;

	uint64_t	dynamicBatchDt;
	int			dynamicBatchCount;
	int			dynamicBatchedDrawCallCount;
	int			dynamicBatchedTris;
	int			dynamicBatchedVerts;

	int			staticBatchCount;
	int			staticBatchedDrawCallCount;
	int			staticBatchedTris;
	int			staticBatchedVerts;
};


// be aware that this enum is shared with unity implementation so you should absolutely not change it
typedef enum
UnityRenderingAPI
{
	apiOpenGLES2	= 2,
	apiOpenGLES3	= 3,
	apiMetal		= 4,
}
UnityRenderingAPI;


// be aware that this enum is shared with unity implementation so you should absolutely not change it
typedef enum
LogType
{
	logError		= 0,
	logAssert		= 1,
	logWarning		= 2,
	logLog			= 3,
	logException	= 4,
	logDebug		= 5,
}
LogType;


// be aware that this enum is shared with unity implementation so you should absolutely not change it
typedef enum
DeviceGeneration
{
	deviceUnknown		= 0,
	deviceiPhone3GS		= 3,
	deviceiPhone4		= 8,
	deviceiPodTouch4Gen	= 9,
	deviceiPad2Gen		= 10,
	deviceiPhone4S		= 11,
	deviceiPad3Gen		= 12,
	deviceiPhone5		= 13,
	deviceiPodTouch5Gen	= 14,
	deviceiPadMini1Gen	= 15,
	deviceiPad4Gen		= 16,
	deviceiPhone5C		= 17,
	deviceiPhone5S		= 18,
	deviceiPadAir1		= 19,
	deviceiPadMini2Gen	= 20,
	deviceiPhone6		= 21,
	deviceiPhone6Plus	= 22,
	deviceiPadMini3Gen	= 23,
	deviceiPadAir2		= 24,

	deviceiPhoneUnknown		= 10001,
	deviceiPadUnknown		= 10002,
	deviceiPodTouchUnknown	= 10003,
}
DeviceGeneration;


// be aware that this enum is shared with unity implementation so you should absolutely not change it
typedef enum
ScreenOrientation
{
	orientationUnknown,
	portrait,
	portraitUpsideDown,
	landscapeLeft,
	landscapeRight,

	orientationCount,
}
ScreenOrientation;


// be aware that this enum is shared with unity implementation so you should absolutely not change it
typedef enum
AppInBackgroundBehavior
{
	appbgCustom		= -1,
	appbgSuspend	= 0,
	appbgExit		= 1,
}
AppInBackgroundBehavior;


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
	extern	bool	_ios70orNewer;
	extern	bool	_ios80orNewer;
#endif
