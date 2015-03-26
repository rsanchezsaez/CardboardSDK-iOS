#include "UnityAppController+Rendering.h"
#include "UnityAppController+ViewHandling.h"

#include "Unity/InternalProfiler.h"
#include "Unity/UnityMetalSupport.h"
#include "Unity/DisplayManager.h"
#include "Unity/EAGLContextHelper.h"

#include "UI/UnityView.h"

#include <dlfcn.h>


// _glesContextCreated was renamed to _renderingInited
extern bool	_renderingInited;
extern bool	_unityAppReady;
extern bool	_skipPresent;
extern bool	_didResignActive;

static int _renderingAPI = 0;
static int SelectRenderingAPIImpl();


@implementation UnityAppController (Rendering)

- (void)createDisplayLink
{
	int animationFrameInterval = (int)(60.0f / (float)UnityGetTargetFPS());
	assert(animationFrameInterval >= 1);

	_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(repaintDisplayLink)];
	[_displayLink setFrameInterval:animationFrameInterval];
	[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)repaintDisplayLink
{
	if(!_didResignActive)
		[self repaint];
}

- (void)repaint
{
	[self checkOrientationRequest];
	[_unityView recreateGLESSurfaceIfNeeded];

	if (!UnityIsPaused())
		UnityRepaint();
}

- (void)callbackGfxInited
{
	InitRendering();
	_renderingInited = true;

	[self shouldAttachRenderDelegate];
	[_renderDelegate mainDisplayInited:_mainDisplay.surface];
	[_unityView recreateGLESSurface];

	_mainDisplay.surface->allowScreenshot = 1;
}

- (void)callbackPresent:(const UnityFrameStats*)frameStats
{
	if(_skipPresent || _didResignActive)
		return;

	Profiler_FrameEnd();
	[[DisplayManager Instance] present];
	Profiler_FrameUpdate(frameStats);
}

- (void)callbackFramerateChange:(int)targetFPS
{
	if(targetFPS <= 0)
		targetFPS = 60;

	int animationFrameInterval = (60.0f / targetFPS);
	if (animationFrameInterval < 1)
		animationFrameInterval = 1;

	[_displayLink setFrameInterval:animationFrameInterval];
}

- (void)selectRenderingAPI
{
	NSAssert(_renderingAPI == 0, @"[UnityAppController selectRenderingApi] called twice");
	_renderingAPI = SelectRenderingAPIImpl();
}

- (UnityRenderingAPI)renderingAPI
{
	NSAssert(_renderingAPI != 0, @"[UnityAppController renderingAPI] called before [UnityAppController selectRenderingApi]");
	return (UnityRenderingAPI)_renderingAPI;
}

@end


extern "C" void UnityGfxInitedCallback()
{
	[GetAppController() callbackGfxInited];
}
extern "C" void UnityPresentContextCallback(struct UnityFrameStats const* unityFrameStats)
{
	[GetAppController() callbackPresent:unityFrameStats];
}
extern "C" void UnityFramerateChangeCallback(int targetFPS)
{
	[GetAppController() callbackFramerateChange:targetFPS];
}

extern "C" void UnityInitMainScreenRenderingCallback(int* screenWidth, int* screenHeight)
{
	extern void QueryTargetResolution(int* targetW, int* targetH);

	int resW=0, resH=0;
	QueryTargetResolution(&resW, &resH);
	UnityRequestRenderingResolution(resW, resH);

	DisplayConnection* display = GetAppController().mainDisplay;
	[display initRendering];

	*screenWidth	= resW;
	*screenHeight	= resH;
}



static NSBundle*		_MetalBundle	= nil;
static id<MTLDevice>	_MetalDevice	= nil;
static EAGLContext*		_GlesContext	= nil;

static bool IsMetalSupported(int /*api*/)
{
	_MetalBundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/Metal.framework"];
	if(_MetalBundle)
	{
		[_MetalBundle load];
		_MetalDevice = ((MTLCreateSystemDefaultDeviceFunc)::dlsym(dlopen(0, RTLD_LOCAL|RTLD_LAZY), "MTLCreateSystemDefaultDevice"))();
		if(_MetalDevice)
			return true;
	}

	[_MetalBundle unload];
	return false;
}

static bool IsGlesSupported(int api)
{
	_GlesContext = [[EAGLContext alloc] initWithAPI:(EAGLRenderingAPI)api];
	return _GlesContext != nil;
}

typedef bool(*CheckSupportedFunc)(int);


static int SelectRenderingAPIImpl()
{
	int api = 0;

	// we want to do fallback Metal->Gles3->Gles2
	// metal support is available only if built with ios8 sdk and running on ios8
#if UNITY_CAN_USE_METAL
	const bool	canSupportMetal = _ios80orNewer;
#else
	const bool	canSupportMetal = false;
#endif

	const int			unityApiEnum[]		= {apiMetal, apiOpenGLES3, apiOpenGLES2};
	CheckSupportedFunc	checkSupport[]		= {&IsMetalSupported, &IsGlesSupported, &IsGlesSupported};
	const int			checkSupportArg[]	= {0, kEAGLRenderingAPIOpenGLES3, kEAGLRenderingAPIOpenGLES2};
	const bool			iosSupport[]		= {canSupportMetal, _ios70orNewer, true};

	for(int i = 0 ; i < 3 && !api ; ++i)
	{
		if(iosSupport[i] && UnityIsRenderingAPISupported(unityApiEnum[i]) && checkSupport[i](checkSupportArg[i]))
			api = unityApiEnum[i];
	}
	return api;
}

extern "C" NSBundle*			UnityGetMetalBundle()		{ return _MetalBundle; }
extern "C" MTLDeviceRef			UnityGetMetalDevice()		{ return _MetalDevice; }
extern "C" MTLCommandQueueRef	UnityGetMetalCommandQueue()	{ return  ((UnityDisplaySurfaceMTL*)GetMainDisplaySurface())->commandQueue; }

extern "C" EAGLContext*	UnityGetDataContextEAGL()	{ return _GlesContext; }
extern "C" int			UnitySelectedRenderingAPI()	{ return _renderingAPI; }


extern "C" void UnityRepaint()
{
	@autoreleasepool
	{
		Profiler_FrameStart();
		UnityInputProcess();

		[[DisplayManager Instance] prepareRendering];
		UnityPlayerLoop();
		[[DisplayManager Instance] teardownRendering];
	}
}
