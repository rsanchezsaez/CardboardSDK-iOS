#import "UnityAppController.h"
#import "UnityAppController+ViewHandling.h"
#import "UnityAppController+Rendering.h"
#import "iPhone_Sensors.h"

#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CADisplayLink.h>
#import <UIKit/UIKit.h>
#import <Availability.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#include <mach/mach_time.h>

// MSAA_DEFAULT_SAMPLE_COUNT was moved to iPhone_GlesSupport.h
// ENABLE_INTERNAL_PROFILER and related defines were moved to iPhone_Profiler.h
// kFPS define for removed: you can use Application.targetFrameRate (30 fps by default)
// DisplayLink is the only run loop mode now - all others were removed

#include "CrashReporter.h"
#include "iPhone_OrientationSupport.h"
#include "iPhone_Profiler.h"

#include "UI/Keyboard.h"
#include "UI/UnityView.h"
#include "UI/SplashScreen.h"
#include "Unity/DisplayManager.h"
#include "Unity/EAGLContextHelper.h"
#include "Unity/GlesHelper.h"
#include "PluginBase/AppDelegateListener.h"


extern "C" void UnityRunUnitTests();

bool	_ios42orNewer			= false;
bool	_ios43orNewer			= false;
bool	_ios50orNewer			= false;
bool	_ios60orNewer			= false;
bool	_ios70orNewer			= false;
bool	_ios80orNewer			= false;
bool	_ios81orNewer			= false;
bool	_ios82orNewer			= false;

bool	_supportsDiscard		= false;
bool	_supportsMSAA			= false;
bool	_supportsPackedStencil	= false;

bool	_glesContextCreated		= false;
bool	_unityAppReady			= false;
bool	_skipPresent			= false;
bool	_didResignActive		= false;

static bool	_isAutorotating		= false;

void UnityInitJoysticks();


@implementation UnityAppController

@synthesize unityView			= _unityView;
@synthesize unityDisplayLink	= _unityDisplayLink;

@synthesize rootView			= _rootView;
@synthesize rootViewController	= _rootController;
@synthesize mainDisplay			= _mainDisplay;
@synthesize renderDelegate		= _renderDelegate;

- (void)setWindow:(id)object		{}
- (UIWindow*)window					{ return _window; }



- (void)shouldAttachRenderDelegate	{}
- (void)preStartUnity				{}

- (void)startUnity:(UIApplication*)application
{
	UnityInitApplicationGraphics();

	// we make sure that first level gets correct display list and orientation
	[[DisplayManager Instance] updateDisplayListInUnity];
	[self updateOrientationFromController:[SplashScreenController Instance]];

	UnityLoadApplication();
	Profiler_InitProfiler();

	[self showGameUI];
	[self createDisplayLink];

	UnitySetPlayerFocus(1);
}

- (void)transitionToViewController:(UIViewController*)vc
{
	_rootController.view = nil;
	vc.view = _rootView;
	_rootController = vc;
	_window.rootViewController = vc;

	[_rootView layoutSubviews];
}

- (void)checkOrientationRequest
{
	ScreenOrientation requestedOrient = (ScreenOrientation)UnityRequestedScreenOrientation();
	if(requestedOrient == autorotation)
	{
		if(!_isAutorotating)
		{
			[self transitionToViewController:[self createRootViewController]];
			[UIViewController attemptRotationToDeviceOrientation];
		}
		_isAutorotating = true;
	}
	else
	{
		if(requestedOrient != _unityView.contentOrientation)
			[self orientUnity:requestedOrient];
		_isAutorotating = false;
	}
}


- (void)onForcedOrientation:(ScreenOrientation)orient
{
	[_unityView willRotateTo:orient];
	[self transitionToViewController:[self createRootViewController]];
	[_unityView didRotate];
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
	// UIInterfaceOrientationMaskAll
	// it is the safest way of doing it:
	// - GameCenter and some other services might have portrait-only variant
	//     and will throw exception if portrait is not supported here
	// - When you change allowed orientations if you end up forbidding current one
	//     exception will be thrown
	// Anyway this is intersected with values provided from UIViewController, so we are good
	return   (1 << UIInterfaceOrientationPortrait) | (1 << UIInterfaceOrientationPortraitUpsideDown)
		   | (1 << UIInterfaceOrientationLandscapeRight) | (1 << UIInterfaceOrientationLandscapeLeft);
}

- (void)application:(UIApplication*)application didReceiveLocalNotification:(UILocalNotification*)notification
{
	AppController_SendNotificationWithArg(kUnityDidReceiveLocalNotification, notification);
	UnitySendLocalNotification(notification);
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
	AppController_SendNotificationWithArg(kUnityDidReceiveRemoteNotification, userInfo);
	UnitySendRemoteNotification(userInfo);
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	AppController_SendNotificationWithArg(kUnityDidRegisterForRemoteNotificationsWithDeviceToken, deviceToken);
	UnitySendDeviceToken(deviceToken);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	AppController_SendNotificationWithArg(kUnityDidFailToRegisterForRemoteNotificationsWithError, error);
	UnitySendRemoteNotificationError(error);
}

- (BOOL)application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation
{
	NSMutableArray* keys	= [NSMutableArray arrayWithCapacity:3];
	NSMutableArray* values	= [NSMutableArray arrayWithCapacity:3];

	#define ADD_ITEM(item)	do{ if(item) {[keys addObject:@#item]; [values addObject:item];} }while(0)

	ADD_ITEM(url);
	ADD_ITEM(sourceApplication);
	ADD_ITEM(annotation);

	#undef ADD_ITEM

	NSDictionary* notifData = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	AppController_SendNotificationWithArg(kUnityOnOpenURL, notifData);
	return YES;
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	printf_console("-> applicationDidFinishLaunching()\n");
	// get local notification
	if (&UIApplicationLaunchOptionsLocalNotificationKey != nil)
	{
		UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
		if (notification)
			UnitySendLocalNotification(notification);
	}

	// get remote notification
	if (&UIApplicationLaunchOptionsRemoteNotificationKey != nil)
	{
		NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
		if (notification)
			UnitySendRemoteNotification(notification);
	}

	if ([UIDevice currentDevice].generatesDeviceOrientationNotifications == NO)
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

	UnityInitApplicationNoGraphics([[[NSBundle mainBundle] bundlePath]UTF8String]);

	[DisplayManager Initialize];
	_mainDisplay	= [[[DisplayManager Instance] mainDisplay] createView:YES showRightAway:NO];
	_window			= _mainDisplay->window;

	[KeyboardDelegate Initialize];

	[self createViewHierarchy];
	[self preStartUnity];

	return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	printf_console("-> applicationDidEnterBackground()\n");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	printf_console("-> applicationWillEnterForeground()\n");

	// if we were showing video before going to background - the view size may be changed while we are in background
	[GetAppController().unityView recreateGLESSurfaceIfNeeded];
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
	printf_console("-> applicationDidBecomeActive()\n");

	if(_unityAppReady)
	{
		if(_didResignActive)
			UnityPause(false);
		UnitySetPlayerFocus(1);
	}
	else
	{
		[self performSelector:@selector(startUnity:) withObject:application afterDelay:0];
	}

	_didResignActive = false;
}

- (void)applicationWillResignActive:(UIApplication*)application
{
	printf_console("-> applicationWillResignActive()\n");

	if(_unityAppReady)
	{
		UnitySetPlayerFocus(0);
		UnityPause(true);

		extern void UnityStopVideoIfPlaying();
		UnityStopVideoIfPlaying();

		// Force player to do one more frame, so scripts get a chance to render custom screen for
		// minimized app in task manager.
		UnityForcedPlayerLoop();
		[self repaintDisplayLink];
	}

	_didResignActive = true;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication*)application
{
	printf_console("WARNING -> applicationDidReceiveMemoryWarning()\n");
}

- (void)applicationWillTerminate:(UIApplication*)application
{
	printf_console("-> applicationWillTerminate()\n");

	Profiler_UninitProfiler();
	UnityCleanup();
}

- (void)dealloc
{
	extern void SensorsCleanup();
	SensorsCleanup();

	[self releaseViewHierarchy];
	[super dealloc];
}
@end


void AppController_RenderPluginMethod(SEL method)
{
	id delegate = GetAppController().renderDelegate;
	if([delegate respondsToSelector:method])
		[delegate performSelector:method];
}
void AppController_RenderPluginMethodWithArg(SEL method, id arg)
{
	id delegate = GetAppController().renderDelegate;
	if([delegate respondsToSelector:method])
		[delegate performSelector:method withObject:arg];
}

void AppController_SendNotification(NSString* name)
{
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:GetAppController()];
}
void AppController_SendNotificationWithArg(NSString* name, id arg)
{
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:GetAppController() userInfo:arg];
}

void AppController_SendMainViewControllerNotification(NSString* name)
{
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:UnityGetGLViewController()];
}

extern "C" UIWindow*			UnityGetMainWindow()		{ return GetAppController().mainDisplay->window; }
extern "C" UIViewController*	UnityGetGLViewController()	{ return GetAppController().rootViewController; }
extern "C" UIView*				UnityGetGLView()			{ return GetAppController().unityView; }
extern "C" ScreenOrientation	UnityCurrentOrientation()	{ return [GetAppController().unityView contentOrientation]; }



bool LogToNSLogHandler(LogType logType, const char* log, va_list list)
{
	NSLogv([NSString stringWithUTF8String:log], list);
	return true;
}

void UnityInitTrampoline()
{
#if ENABLE_CRASH_REPORT_SUBMISSION
	SubmitCrashReportsAsync();
#endif
	InitCrashHandling();

	_ios42orNewer = [[[UIDevice currentDevice] systemVersion] compare: @"4.2" options: NSNumericSearch] != NSOrderedAscending;
	_ios43orNewer = [[[UIDevice currentDevice] systemVersion] compare: @"4.3" options: NSNumericSearch] != NSOrderedAscending;
	_ios50orNewer = [[[UIDevice currentDevice] systemVersion] compare: @"5.0" options: NSNumericSearch] != NSOrderedAscending;
	_ios60orNewer = [[[UIDevice currentDevice] systemVersion] compare: @"6.0" options: NSNumericSearch] != NSOrderedAscending;
	_ios70orNewer = [[[UIDevice currentDevice] systemVersion] compare: @"7.0" options: NSNumericSearch] != NSOrderedAscending;
	_ios80orNewer = [[[UIDevice currentDevice] systemVersion] compare: @"8.0" options: NSNumericSearch] != NSOrderedAscending;
	_ios81orNewer = [[[UIDevice currentDevice] systemVersion] compare: @"8.1" options: NSNumericSearch] != NSOrderedAscending;
	_ios82orNewer = [[[UIDevice currentDevice] systemVersion] compare: @"8.2" options: NSNumericSearch] != NSOrderedAscending;

	// Try writing to console and if it fails switch to NSLog logging
	fprintf(stdout, "\n");
	if (ftell(stdout) < 0)
		SetLogEntryHandler(LogToNSLogHandler);

    // Fix home directory environment variable.
    const char *newHomeDirectory = ([[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] UTF8String]);
    setenv("XDG_CONFIG_HOME", newHomeDirectory, 1);
    
	UnityInitJoysticks();
}

extern "C" const char* const* UnityFontDirs()
{
	static const char* const dirs[] = {
		"/System/Library/Fonts/Cache",		// before iOS 8.2
		"/System/Library/Fonts/AppFonts",	// iOS 8.2
		"/System/Library/Fonts/Core",		// iOS 8.2
		"/System/Library/Fonts/Extra",		// iOS 8.2
		NULL
	};
	return dirs;
}
