#include "UnityAppController+Rendering.h"
#include "UnityAppController+ViewHandling.h"

#include "iPhone_Profiler.h"

#include "Unity/DisplayManager.h"
#include "Unity/EAGLContextHelper.h"
#include "Unity/GlesHelper.h"

#include "UI/UnityView.h"


extern bool	_glesContextCreated;
extern bool	_unityAppReady;
extern bool	_skipPresent;
extern bool	_didResignActive;

@implementation UnityAppController (Rendering)

- (void)createDisplayLink
{
	int animationFrameInterval = 60.0 / (float)UnityGetTargetFPS();
	assert(animationFrameInterval >= 1);

	_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(repaintDisplayLink)];
	[_displayLink setFrameInterval:animationFrameInterval];
	[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)repaintDisplayLink
{
	if(!_didResignActive)
	{
		[self repaint];
		[[DisplayManager Instance] presentAllButMain];
		SetupUnityDefaultFBO(&_mainDisplay->surface);
	}
}

- (void)repaint
{
	// setup unity context and fbo
	EAGLContextSetCurrentAutoRestore autorestore(_mainDisplay->surface.context);
	SetupUnityDefaultFBO(&_mainDisplay->surface);

	[self checkOrientationRequest];
	[_unityView recreateGLESSurfaceIfNeeded];

	Profiler_FrameStart();
	UnityInputProcess();
	UnityPlayerLoop();
}

- (void)callbackGfxInited
{
	InitGLES(_mainDisplay->surface.context.API);
	_glesContextCreated = true;

	[self shouldAttachRenderDelegate];
	[_renderDelegate mainDisplayInited:&_mainDisplay->surface];
	[_unityView recreateGLESSurface];

	_mainDisplay->surface.allowScreenshot = true;

	SetupUnityDefaultFBO(&_mainDisplay->surface);
	glViewport(0, 0, _mainDisplay->surface.targetW, _mainDisplay->surface.targetH);
}

- (void)callbackPresent:(const UnityFrameStats*)frameStats
{
	if(_skipPresent || _didResignActive)
		return;

	Profiler_FrameEnd();
	[_mainDisplay present];
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

@end


extern "C" void GfxInited_UnityCallback()
{
	[GetAppController() callbackGfxInited];
}
extern "C" void PresentContext_UnityCallback(struct UnityFrameStats const* unityFrameStats)
{
	[GetAppController() callbackPresent:unityFrameStats];
}
extern "C" void FramerateChange_UnityCallback(int targetFPS)
{
	[GetAppController() callbackFramerateChange:targetFPS];
}

extern "C" int CreateContext_UnityCallback(UIWindow** window, int* screenWidth, int* screenHeight,  int* openglesVersion)
{
	extern void QueryTargetResolution(int* targetW, int* targetH);

	int resW=0, resH=0;
	QueryTargetResolution(&resW, &resH);
	UnityRequestRenderingResolution(resW, resH);

	DisplayConnection* display = GetAppController().mainDisplay;
	[display createContext:nil];

	*window			= UnityGetMainWindow();
	*screenWidth	= resW;
	*screenHeight	= resH;
	*openglesVersion= display->surface.context.API;

	[EAGLContext setCurrentContext:display->surface.context];

	return true;
}
