#include "UnityAppController+ViewHandling.h"
#include "UnityAppController+Rendering.h"

#include "UI/UnityView.h"
#include "UI/UnityViewControllerBase.h"
#include "Unity/DisplayManager.h"

#include "iPhone_OrientationSupport.h"


// TEMP: ?
#include "UI/ActivityIndicator.h"
#include "UI/SplashScreen.h"
#include "UI/Keyboard.h"

extern bool _skipPresent;
extern bool _unityAppReady;



@implementation UnityAppController (ViewHandling)

- (void)createViewHierarchyImpl
{
	_rootView = _unityView;
	_rootController = [self createRootViewController];
}
- (UnityView*)initUnityViewImpl
{
	return [[UnityView alloc] initFromMainScreen];
}

- (UIViewController*)createAutorotatingUnityViewController
{
	UnityViewControllerBase* vc = [[UnityDefaultViewController alloc] init];
	[vc assignUnityView:_unityView];

	return vc;
}
- (UIViewController*)createUnityViewControllerForOrientation:(ScreenOrientation)orient
{
	UnityViewControllerBase* vc = nil;
#if UNITY_IOS8_ORNEWER_SDK
	if(_ios80orNewer)
	{
		switch(orient)
		{
			case portrait:				vc = [[UnityPortraitOnlyViewController alloc] init];			break;
			case portraitUpsideDown:	vc = [[UnityPortraitUpsideDownOnlyViewController alloc] init];	break;
			case landscapeLeft:			vc = [[UnityLandscapeLeftOnlyViewController alloc] init];		break;
			case landscapeRight:		vc = [[UnityLandscapeRightOnlyViewController alloc] init];		break;

			default:					NSAssert(false, @"bad ScreenOrientation provided");
		}
	}
#else
	vc = [[UnityDefaultViewController alloc] init];
#endif

	[vc assignUnityView:_unityView];
	return vc;
}

- (void)createViewHierarchy
{
	AddViewControllerAllDefaultImpl([UnityDefaultViewController class]);

	NSAssert(_unityView != nil, @"_unityView should be inited at this point");
	NSAssert(_window != nil, @"_window should be inited at this point");

	[self createViewHierarchyImpl];
	NSAssert(_rootView != nil, @"createViewHierarchyImpl must assign _rootView");
	NSAssert(_rootController != nil, @"createViewHierarchyImpl must assign _rootController");

	_rootView.contentScaleFactor = UnityScreenScaleFactor([UIScreen mainScreen]);
	_rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	_rootController.wantsFullScreenLayout = TRUE;
	_rootController.view = _rootView;
	if([_rootController isKindOfClass: [UnityViewControllerBase class]])
		[(UnityViewControllerBase*)_rootController assignUnityView:_unityView];

	[_window makeKeyAndVisible];
	[UIView setAnimationsEnabled:NO];

	// TODO: extract it?

	ShowSplashScreen(_window);

	NSNumber* style = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Unity_LoadingActivityIndicatorStyle"];
	ShowActivityIndicator([SplashScreen Instance], style ? [style intValue] : -1 );
}
- (void)releaseViewHierarchy
{
	HideActivityIndicator();
	HideSplashScreen();
}

- (UnityView*)initUnityView
{
	_unityView = [self initUnityViewImpl];
	_unityView.contentScaleFactor = UnityScreenScaleFactor([UIScreen mainScreen]);
	_unityView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	return _unityView;
}

- (UIViewController*)createRootViewController
{
#if UNITY_IOS8_ORNEWER_SDK
	if(_ios80orNewer)
	{
		if(UnityRequestedScreenOrientation() == autorotation)
			return [self createAutorotatingUnityViewController];
		else
			return [self createUnityViewControllerForOrientation:(ScreenOrientation)UnityRequestedScreenOrientation()];
	}
#endif

	return [self createAutorotatingUnityViewController];
}


- (void)showGameUI
{
	HideActivityIndicator();
	HideSplashScreen();

	// this is called after level was loaded, so orientation constraints or resolution might have changed
	[self updateOrientationFromController:_rootController];

	// make sure that we start up with correctly created/inited rendering surface
	// NB: recreateGLESSurface won't go into rendering because _unityAppReady is false
	[_unityView recreateGLESSurface];

	// UI hierarchy
	[_window addSubview: _rootView];
	_window.rootViewController = _rootController;
	[_window bringSubviewToFront: _rootView];

	// why we set level ready only now:
	// surface recreate will try to repaint if this var is set (poking unity to do it)
	// but this frame now is actually the first one we want to process/draw
	// so all the recreateSurface before now (triggered by reorientation) should simply change extents

	_unityAppReady = true;

	// why we skip present:
	// this will be the first frame to draw, so Start methods will be called
	// and we want to properly handle resolution request in Start (which might trigger surface recreate)
	// NB: we want to draw right after showing window, to avoid black frame creeping in

	_skipPresent = true;

	// manually prepare rendering as we do player loop ourselves
	SetupUnityDefaultFBO(&GetMainDisplay()->surface);

	UnityPlayerLoop();
	_skipPresent = false;
	[self repaint];


	[UIView setAnimationsEnabled:YES];
}

- (void)orientUnity:(ScreenOrientation)orient
{
	if(_unityAppReady)
		UnityFinishRendering();

	[CATransaction begin];
	{
		[KeyboardDelegate StartReorientation];
		[self onForcedOrientation:orient];
		[UIApplication sharedApplication].statusBarOrientation = ConvertToIosScreenOrientation(orient);
	}
	[CATransaction commit];

	[CATransaction begin];
	[KeyboardDelegate FinishReorientation];
	[CATransaction commit];
}

- (void)updateOrientationFromController:(UIViewController*)controller
{
	ScreenOrientation newOrient = ConvertToUnityScreenOrientation(controller.interfaceOrientation,0);
	AppController_RenderPluginMethodWithArg(@selector(onOrientationChange:), (id)newOrient);
	[self orientUnity:newOrient];
}

@end
