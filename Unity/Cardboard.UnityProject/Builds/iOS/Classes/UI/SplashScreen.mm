
#include "SplashScreen.h"
#include "UnityViewControllerBase.h"
#include "OrientationSupport.h"
#include "Unity/ObjCRuntime.h"
#include <cstring>

extern "C" const char* UnityGetLaunchScreenXib();

#include <utility>

static SplashScreen*			_splash      = nil;
static SplashScreenController*	_controller  = nil;
static bool						_isOrientable = false; // true for iPads and iPhone 6+
static bool						_usesLaunchscreen = false;
static ScreenOrientation		_nonOrientableDefaultOrientation = portrait;

// we will create and show splash before unity is inited, so we can use only plist settings
static bool	_canRotateToPortrait			= false;
static bool	_canRotateToPortraitUpsideDown	= false;
static bool	_canRotateToLandscapeLeft		= false;
static bool	_canRotateToLandscapeRight		= false;

typedef id (*WillRotateToInterfaceOrientationSendFunc)(struct objc_super*, SEL, UIInterfaceOrientation, NSTimeInterval);
typedef id (*DidRotateFromInterfaceOrientationSendFunc)(struct objc_super*, SEL, UIInterfaceOrientation);
typedef id (*ViewWillTransitionToSizeSendFunc)(struct objc_super*, SEL, CGSize, id<UIViewControllerTransitionCoordinator>);


@implementation SplashScreen

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	return self;
}

/* The following launch images are produced by Xcode6:

	LaunchImage.png
	LaunchImage@2x.png
	LaunchImage-568h@2x.png
	LaunchImage-700@2x.png
	LaunchImage-700-568h@2x.png
	LaunchImage-700-Landscape@2x~ipad.png
	LaunchImage-700-Landscape~ipad.png
	LaunchImage-700-Portrait@2x~ipad.png
	LaunchImage-700-Portrait~ipad.png
	LaunchImage-800-667h@2x.png
	LaunchImage-800-Landscape-736h@3x.png
	LaunchImage-800-Portrait-736h@3x.png
	LaunchImage-Landscape@2x~ipad.png
	LaunchImage-Landscape~ipad.png
	LaunchImage-Portrait@2x~ipad.png
	LaunchImage-Portrait~ipad.png
*/
- (void)updateOrientation:(ScreenOrientation)orient
{
	const char* ipadSuffix = "";
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone)
		ipadSuffix = "~ipad";

	bool orientPortrait  = (orient == portrait || orient == portraitUpsideDown);
	bool orientLandscape = (orient == landscapeLeft || orient == landscapeRight);

	bool rotateToPortrait  = _canRotateToPortrait || _canRotateToPortraitUpsideDown;
	bool rotateToLandscape = _canRotateToLandscapeLeft || _canRotateToLandscapeRight;

	const char* orientSuffix = "";
	if (_isOrientable)
	{
		if (orientPortrait && rotateToPortrait)
			orientSuffix = "-Portrait";
		else if (orientLandscape && rotateToLandscape)
			orientSuffix = "-Landscape";
		else if (rotateToPortrait)
			orientSuffix = "-Portrait";
		else
			orientSuffix = "-Landscape";
	}

	const char* szSuffix = "";
	CGFloat scale = [UIScreen mainScreen].scale;
	if (scale > 2.0f)
		szSuffix = "@3x";
	else if (scale > 1.0f)
		szSuffix = "@2x";

	const char* iOSSuffix = _ios70orNewer ? "-700" : "";
	const char* rezolutionSuffix = "";

	CGSize size = [[UIScreen mainScreen] bounds].size;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		if (size.height == 568 || size.width == 568) // iPhone5
			rezolutionSuffix = "-568h";
		if (size.height == 667 || size.width == 667) // iPhone6
		{
			rezolutionSuffix = "-667h";
			iOSSuffix = "-800";

			if (scale > 2.0) // iPhone6+ in display zoom mode
				szSuffix = "@2x";
		}
		if (size.height == 736 || size.width == 736) // iPhone6+
		{
			rezolutionSuffix = "-736h";
			iOSSuffix = "-800";
		}
	}

	if (_usesLaunchscreen)
	{
		// Launch screen uses the same aspect-filled image for all iPhones. So,
		// we need a special case if there's a launch screen and iOS is configured
		// to use it.
		// Note that we don't use launch screens for iPads since there's no way
		// to use different layouts epending on orientation.

		iOSSuffix = "-800";
		rezolutionSuffix = "-736h";
		if (!_isOrientable)
		{
			if (rotateToPortrait)
				orientSuffix = "-Portrait";
			else
				orientSuffix = "-Landscape"; // Launch screens use landscape if portrait is disabled
		}
		szSuffix = "@3x";
		self.contentMode = UIViewContentModeScaleAspectFill;
	}

	// we will use imageWithContentsOfFile so we need fully qualified path
	// we need to retain path because seems like imageWithContentsOfFile will be done on another thread
	// so we need to preserve path to be used with it until next runloop
	NSString* imageName = [NSString stringWithFormat:@"LaunchImage%s%s%s%s%s",
													 iOSSuffix, orientSuffix, rezolutionSuffix, szSuffix, ipadSuffix];
	NSString* imagePath = [[NSBundle mainBundle] pathForResource: imageName ofType: @"png"];

	self.image = [UIImage imageWithContentsOfFile: imagePath];
}

+ (SplashScreen*)Instance
{
	return _splash;
}

@end

@implementation SplashScreenController

static void WillRotateToInterfaceOrientation_DefaultImpl(id self_, SEL _cmd, UIInterfaceOrientation toInterfaceOrientation, NSTimeInterval duration)
{
	if(_isOrientable)
		[_splash updateOrientation: ConvertToUnityScreenOrientation(toInterfaceOrientation)];

	UNITY_OBJC_FORWARD_TO_SUPER(self_, [UIViewController class], @selector(willRotateToInterfaceOrientation:duration:), WillRotateToInterfaceOrientationSendFunc, toInterfaceOrientation, duration);
}
static void DidRotateFromInterfaceOrientation_DefaultImpl(id self_, SEL _cmd, UIInterfaceOrientation fromInterfaceOrientation)
{
	if(!_isOrientable)
		OrientView((SplashScreenController*)self_, _splash, _nonOrientableDefaultOrientation);

	UNITY_OBJC_FORWARD_TO_SUPER(self_, [UIViewController class], @selector(didRotateFromInterfaceOrientation:), DidRotateFromInterfaceOrientationSendFunc, fromInterfaceOrientation);
}
static void ViewWillTransitionToSize_DefaultImpl(id self_, SEL _cmd, CGSize size, id<UIViewControllerTransitionCoordinator> coordinator)
{
#if UNITY_IOS8_ORNEWER_SDK
	UIViewController* self = (UIViewController*)self_;

	ScreenOrientation curOrient = ConvertToUnityScreenOrientation(self.interfaceOrientation);
	ScreenOrientation newOrient = OrientationAfterTransform(curOrient, [coordinator targetTransform]);

	if(_isOrientable)
		[_splash updateOrientation:newOrient];

	[coordinator
		animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
		{
		}
		completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
		{
			if(!_isOrientable)
				OrientView(self, _splash, portrait);
		}
	];
#endif
	UNITY_OBJC_FORWARD_TO_SUPER(self_, [UIViewController class], @selector(viewWillTransitionToSize:withTransitionCoordinator:), ViewWillTransitionToSizeSendFunc, size, coordinator);
}


- (id)init
{
	if( (self = [super init]) )
	{
		AddViewControllerRotationHandling(
			[SplashScreenController class],
			(IMP)&WillRotateToInterfaceOrientation_DefaultImpl, (IMP)&DidRotateFromInterfaceOrientation_DefaultImpl,
			(IMP)&ViewWillTransitionToSize_DefaultImpl
		);
	}
	return self;
}

- (void)create:(UIWindow*)window
{
	NSArray* supportedOrientation = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UISupportedInterfaceOrientations"];

	// splash will be shown way before unity is inited so we need to override autorotation handling with values read from info.plist
	_canRotateToPortrait			= [supportedOrientation containsObject: @"UIInterfaceOrientationPortrait"];
	_canRotateToPortraitUpsideDown	= [supportedOrientation containsObject: @"UIInterfaceOrientationPortraitUpsideDown"];
	_canRotateToLandscapeLeft		= [supportedOrientation containsObject: @"UIInterfaceOrientationLandscapeRight"];
	_canRotateToLandscapeRight		= [supportedOrientation containsObject: @"UIInterfaceOrientationLandscapeLeft"];

	CGSize size = [[UIScreen mainScreen] bounds].size;

	// iPads and iPhone 6+ have orientable splash screen
	_isOrientable = UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone || (size.height == 736 || size.width == 736);

	// Launch screens are used only on iOS8+ iPhones
	const char* xib = UnityGetLaunchScreenXib();
	_usesLaunchscreen = (_ios80orNewer && xib != NULL && std::strcmp(xib, "LaunchScreen") == 0 &&
						 UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);

	if (_usesLaunchscreen && !(_canRotateToPortrait || _canRotateToPortraitUpsideDown))
		_nonOrientableDefaultOrientation = landscapeLeft;
	else
		_nonOrientableDefaultOrientation = portrait;

	_splash = [[SplashScreen alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
	_splash.contentScaleFactor = [UIScreen mainScreen].scale;

	if (_isOrientable)
	{
		_splash.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_splash.autoresizesSubviews = YES;
	}
	else if (_canRotateToPortrait || _canRotateToPortraitUpsideDown)
	{
		_canRotateToLandscapeLeft = false;
		_canRotateToLandscapeRight = false;
	}
	// launch screens always use landscapeLeft in landscape
	if (_usesLaunchscreen && _canRotateToLandscapeLeft)
		_canRotateToLandscapeRight = false;

	self.view = _splash;

	self.wantsFullScreenLayout = TRUE;

	[window addSubview: _splash];
	window.rootViewController = self;
	[window bringSubviewToFront: _splash];

	ScreenOrientation orient = ConvertToUnityScreenOrientation(self.interfaceOrientation);
	[_splash updateOrientation: orient];

	if (!_isOrientable)
		orient = _nonOrientableDefaultOrientation;
	OrientView([SplashScreenController Instance], _splash, orient);
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	NSUInteger ret = 0;

	if(_canRotateToPortrait)			ret |= (1 << UIInterfaceOrientationPortrait);
	if(_canRotateToPortraitUpsideDown)	ret |= (1 << UIInterfaceOrientationPortraitUpsideDown);
	if(_canRotateToLandscapeLeft)		ret |= (1 << UIInterfaceOrientationLandscapeRight);
	if(_canRotateToLandscapeRight)		ret |= (1 << UIInterfaceOrientationLandscapeLeft);

	return ret;
}

+ (SplashScreenController*)Instance
{
	return _controller;
}

@end

void ShowSplashScreen(UIWindow* window)
{
	_controller = [[SplashScreenController alloc] init];
	[_controller create:window];
}

void HideSplashScreen()
{
	if(_splash)
	{
		[_splash removeFromSuperview];
		_splash.image = nil;
	}

	_splash = nil;
	_controller = nil;
}
