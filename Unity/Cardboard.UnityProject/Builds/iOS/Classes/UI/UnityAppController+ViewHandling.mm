#include "UnityAppController+ViewHandling.h"
#include "UnityAppController+Rendering.h"

#include "UI/OrientationSupport.h"
#include "UI/UnityView.h"
#include "UI/UnityViewControllerBase.h"
#include "Unity/DisplayManager.h"


// TEMP: ?
#include "UI/ActivityIndicator.h"
#include "UI/SplashScreen.h"
#include "UI/Keyboard.h"

extern bool _skipPresent;
extern bool _unityAppReady;


@implementation UnityAppController (ViewHandling)

// ios is not sending "change orientation" notifications on startup, so we should handle it manually
- (void)handleStartupOrientation:(UIInterfaceOrientation)orientation
{
	NSAssert(_curOrientation == UIInterfaceOrientationUnknown, @"handleStartupOrientation should be called only before orientation is known");

	_curOrientation = orientation;
	[_unityView willRotateToOrientation:orientation fromOrientation:(UIInterfaceOrientation)UIInterfaceOrientationUnknown];
	[_unityView didRotate];
}

- (UnityView*)createUnityView
{
	return [[UnityView alloc] initFromMainScreen];
}
- (UIViewController*)createAutorotatingUnityViewController
{
	return [[UnityDefaultViewController alloc] init];
}
- (UIViewController*)createUnityViewControllerForOrientation:(UIInterfaceOrientation)orient
{
	switch(orient)
	{
		case UIInterfaceOrientationPortrait:			return [[UnityPortraitOnlyViewController alloc] init];
		case UIInterfaceOrientationPortraitUpsideDown:	return [[UnityPortraitUpsideDownOnlyViewController alloc] init];
		case UIInterfaceOrientationLandscapeLeft:		return [[UnityLandscapeLeftOnlyViewController alloc] init];
		case UIInterfaceOrientationLandscapeRight:		return [[UnityLandscapeRightOnlyViewController alloc] init];

		default:										NSAssert(false, @"bad UIInterfaceOrientation provided");
	}
	return nil;
}
- (UIViewController*)createRootViewControllerForOrientation:(UIInterfaceOrientation)orientation
{
	NSAssert(orientation != 0, @"Bad UIInterfaceOrientation provided");
	if(_viewControllerForOrientation[orientation] == nil)
		_viewControllerForOrientation[orientation] = [self createUnityViewControllerForOrientation:orientation];
	return _viewControllerForOrientation[orientation];

}
- (UIViewController*)createRootViewController
{
	UIViewController* ret = nil;
	if(UnityShouldAutorotate())
	{
		if(_viewControllerForOrientation[0] == nil)
			_viewControllerForOrientation[0] = [self createAutorotatingUnityViewController];
		ret = _viewControllerForOrientation[0];
	}
	else
	{
		UIInterfaceOrientation orientation = ConvertToIosScreenOrientation((ScreenOrientation)UnityRequestedScreenOrientation());
		ret = [self createRootViewControllerForOrientation:orientation];
	}

	if(_curOrientation == UIInterfaceOrientationUnknown)
		[self handleStartupOrientation:ret.interfaceOrientation];

	return ret;
}

- (void)willStartWithViewController:(UIViewController*)controller
{
	_unityView.contentScaleFactor	= UnityScreenScaleFactor([UIScreen mainScreen]);
	_unityView.autoresizingMask		= UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	_rootController.view = _rootView = _unityView;
	_rootController.wantsFullScreenLayout = TRUE;
}
- (void)willTransitionToViewController:(UIViewController*)toController fromViewController:(UIViewController*)fromController
{
	fromController.view	= nil;
	toController.view	= _rootView;
}

-(void)interfaceWillChangeOrientationTo:(UIInterfaceOrientation)toInterfaceOrientation
{
	UIInterfaceOrientation fromInterfaceOrientation = _curOrientation;

	_curOrientation = toInterfaceOrientation;
	[_unityView willRotateToOrientation:toInterfaceOrientation fromOrientation:fromInterfaceOrientation];
}
-(void)interfaceDidChangeOrientationFrom:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[_unityView didRotate];
}


- (void)createUI
{
	NSAssert(_unityView != nil, @"_unityView should be inited at this point");
	NSAssert(_window != nil, @"_window should be inited at this point");

	_rootController = [self createRootViewController];

	[self willStartWithViewController:_rootController];

	NSAssert(_rootView != nil, @"_rootView  should be inited at this point");
	NSAssert(_rootController != nil, @"_rootController should be inited at this point");

	[_window makeKeyAndVisible];
	[UIView setAnimationsEnabled:NO];

	// TODO: extract it?

	ShowSplashScreen(_window);

	NSNumber* style = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Unity_LoadingActivityIndicatorStyle"];
	ShowActivityIndicator([SplashScreen Instance], style ? [style intValue] : -1 );
}

- (void)showGameUI
{
	HideActivityIndicator();
	HideSplashScreen();

	// make sure that we start up with correctly created/inited rendering surface
	// NB: recreateGLESSurface won't go into rendering because _unityAppReady is false
	[_unityView recreateGLESSurface];

	// UI hierarchy
	[_window addSubview: _rootView];
	_window.rootViewController = _rootController;
	[_window bringSubviewToFront:_rootView];

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

	if (!UnityIsPaused())
		UnityRepaint();

	_skipPresent = false;
	[self repaint];

	[UIView setAnimationsEnabled:YES];
}

- (void)transitionToViewController:(UIViewController*)vc
{
	[self willTransitionToViewController:vc fromViewController:_rootController];
	_rootController = vc;
	_window.rootViewController = vc;

	[_rootView layoutSubviews];
}

- (void)orientInterface:(UIInterfaceOrientation)orient
{
	if(_curOrientation == orient)
		return;

	if(_unityAppReady)
		UnityFinishRendering();

	[KeyboardDelegate StartReorientation];

	[CATransaction begin];
	{
		UIInterfaceOrientation oldOrient = _curOrientation;
		UIInterfaceOrientation newOrient = orient;

		[self interfaceWillChangeOrientationTo:newOrient];
		[self transitionToViewController:[self createRootViewControllerForOrientation:newOrient]];
		[self interfaceDidChangeOrientationFrom:oldOrient];

		[UIApplication sharedApplication].statusBarOrientation = orient;
	}
	[CATransaction commit];

	[KeyboardDelegate FinishReorientation];
}

- (void)orientUnity:(ScreenOrientation)orient
{
	[self orientInterface:ConvertToIosScreenOrientation(orient)];
}

- (void)checkOrientationRequest
{
	if(UnityShouldAutorotate())
	{
		if(_rootController != _viewControllerForOrientation[0])
		{
			[self transitionToViewController:[self createRootViewController]];
			[UIViewController attemptRotationToDeviceOrientation];
		}
	}
	else
	{
		ScreenOrientation requestedOrient = (ScreenOrientation)UnityRequestedScreenOrientation();
		if(requestedOrient != _unityView.contentOrientation)
			[self orientUnity:requestedOrient];
	}
}

@end
