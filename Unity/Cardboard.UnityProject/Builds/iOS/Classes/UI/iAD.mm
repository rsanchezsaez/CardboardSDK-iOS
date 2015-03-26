
#include "iPhone_OrientationSupport.h"
#include "iAD.h"

#include "UnityAppController+ViewHandling.h"
#include "UnityView.h"


#if UNITY_PRE_IOS6_SDK
	enum ADAdType
	{
		ADAdTypeBanner,
		ADAdTypeMediumRectangle
	};
#endif

#if UNITY_PRE_IOS6_TARGET
	static void Banner_InitRequiredContentSizes(ADBannerView* view);
	static void Banner_UpdateCurrentContentSize(ADBannerView* view, UIInterfaceOrientation orient);
#endif

@implementation UnityADBanner

@synthesize view = _view;
@synthesize adVisible = _showingBanner;

- (void)initImpl:(UIView*)parent layout:(ADBannerLayout)layout type:(ADBannerType)type
{
	if([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)])
		_view = [[ADBannerView alloc] initWithAdType:(ADAdType)type];
	else
		_view = [[ADBannerView alloc] init];

	_view.contentScaleFactor = [UIScreen mainScreen].scale;
	_view.bounds = parent.bounds;
	_view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	_view.delegate = self;

#if UNITY_PRE_IOS6_TARGET
	Banner_InitRequiredContentSizes(_view);
#endif

	_bannerLayout	= layout;
	_showingBanner	= NO;

	[parent addSubview:_view];
	[self orientBannerImpl: [UIApplication sharedApplication].statusBarOrientation];
	[self layoutBannerImpl];


	[[NSNotificationCenter defaultCenter] 	addObserver:self
											selector:@selector(orientationWillChange:)
											name:kUnityViewWillRotate
											object:nil
	];
	[[NSNotificationCenter defaultCenter] 	addObserver:self
											selector:@selector(orientationDidChange:)
											name:kUnityViewDidRotate
											object:nil
	];

	UnitySetViewTouchProcessing(_view, touchesTransformedToUnityViewCoords);
}

- (float)layoutXImpl:(UIView*)parent
{
#if UNITY_PRE_IOS6_SDK
	bool rectBanner = false;
#else
	bool rectBanner = [ADBannerView instancesRespondToSelector:@selector(adType)] && _view.adType == ADAdTypeMediumRectangle;
#endif

	float x = parent.bounds.size.width/2;
	if(_bannerLayout == adbannerManual)
	{
		x = rectBanner ? _userLayoutCenter.x : parent.bounds.size.width/2;
	}
	else if(rectBanner)
	{
		int horz = (_bannerLayout & layoutMaskHorz) >> layoutShiftHorz;
		if(horz == layoutMaskLeft)			x = _view.bounds.size.width / 2;
		else if(horz == layoutMaskRight)	x = parent.bounds.size.width - _view.bounds.size.width / 2;
		else if(horz == layoutMaskCenter)	x = parent.bounds.size.width / 2;
		else								x = _userLayoutCenter.x;
	}

	return x;
}

- (float)layoutYImpl:(UIView*)parent
{
	if(!_showingBanner)
		return parent.bounds.size.height + _view.bounds.size.height;

#if UNITY_PRE_IOS6_SDK
	bool rectBanner = false;
#else
	bool rectBanner = [ADBannerView instancesRespondToSelector:@selector(adType)] && _view.adType == ADAdTypeMediumRectangle;
#endif

	float y = 0;
	if(_bannerLayout == adbannerManual)
	{
		y = _userLayoutCenter.y;
	}
	else
	{
		int vert = rectBanner ? (_bannerLayout & layoutMaskVert) : (_bannerLayout & 1);
		if(vert == layoutMaskTop)			y = _view.bounds.size.height / 2;
		else if(vert == layoutMaskBottom)	y = parent.bounds.size.height - _view.bounds.size.height / 2;
		else if(vert == layoutMaskCenter)	y = parent.bounds.size.height / 2;
		else								y = _userLayoutCenter.y;
	}

	return y;
}

- (void)layoutBannerImpl
{
	UIView* parent = _view.superview;

	float cx = [self layoutXImpl:parent];
	float cy = [self layoutYImpl:parent];

	const bool newAdAPI = [_view respondsToSelector:@selector(sizeThatFits:)];

	CGRect rect = _view.bounds;
	if(newAdAPI)
		rect.size = [_view sizeThatFits:parent.bounds.size];

#if UNITY_PRE_IOS6_TARGET
	if(!newAdAPI)
		rect.size = [ADBannerView sizeFromBannerContentSizeIdentifier: _view.currentContentSizeIdentifier];
#endif


	_view.center = CGPointMake(cx,cy);
	_view.bounds = rect;

	[parent layoutSubviews];
}

- (void)orientBannerImpl:(UIInterfaceOrientation)orient
{
#if UNITY_PRE_IOS6_TARGET
	Banner_UpdateCurrentContentSize(_view, orient);
#endif
}


- (id)initWithParent:(UIView*)parent layout:(ADBannerLayout)layout type:(ADBannerType)type
{
	if( (self = [super init]) )
		[self initImpl:parent layout:layout type:type];
	return self;
}
- (id)initWithParent:(UIView*)parent layout:(ADBannerLayout)layout;
{
	if( (self = [super init]) )
		[self initImpl:parent layout:layout type:adbannerBanner];
	return self;
}

- (void)dealloc
{
	// dtor might be called from a separate thread by a garbage collector
	// so we need a new autorelease pool in case threre are autoreleased objects
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[[NSNotificationCenter defaultCenter] removeObserver: self];

	UnityDropViewTouchProcessing(_view);

	_view.delegate = nil;
	[_view removeFromSuperview];
	[_view release];
	_view = nil;

	[pool release];
	[super dealloc];
}

- (void)orientationWillChange:(NSNotification*)notification
{
	_view.hidden = YES;
}

- (void)orientationDidChange:(NSNotification*)notification
{
	if(_showingBanner)
		_view.hidden = NO;

	[self orientBannerImpl: ConvertToIosScreenOrientation(((UnityView*)notification.object).contentOrientation)];
	[self layoutBannerImpl];
}

- (void)layoutBanner:(ADBannerLayout)layout
{
	_bannerLayout = layout;
	[self layoutBannerImpl];
}

- (void)positionForUserLayout:(CGPoint)center
{
	_userLayoutCenter = center;
	[self layoutBannerImpl];
}

- (void)showBanner:(BOOL)show
{
	_view.hidden = NO;
	_showingBanner = show;
	[self layoutBannerImpl];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView*)banner willLeaveApplication:(BOOL)willLeave
{
	if(!willLeave)
		UnityPause(true);
	return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView*)banner
{
	[GetAppController() updateOrientationFromController:UnityGetGLViewController()];
	UnityPause(false);
	UnityADBannerViewWasClicked();
}

- (void)bannerViewDidLoadAd:(ADBannerView*)banner
{
	UnityADBannerViewWasLoaded();
}

- (void)bannerView:(ADBannerView*)banner didFailToReceiveAdWithError:(NSError*)error
{
	::printf_console("ADBannerView error: %s\n", [[error localizedDescription] UTF8String]);
	_showingBanner = NO;
	[self layoutBannerImpl];
}

@end

enum AdState {
	kAdNone,
	kAdWillAppear,
	kAdVisible
};

AdState gAdState = kAdNone;

@implementation UnityInterstitialAd

@synthesize view = _view;

- (id)initWithController:(UIViewController*)presentController autoReload:(BOOL)autoReload
{
	if( (self = [super init]) )
	{
		UnityRegisterMainViewControllerListener((id<MainViewControllerListener>)self);

		_view = [[ADInterstitialAd alloc] init];
		_view.delegate = self;

		_presentController	= presentController;
		_autoReload			= autoReload;
	}

	return self;
}
- (void)dealloc
{
	UnityUnregisterMainViewControllerListener((id<MainViewControllerListener>)self);
	// dtor might be called from a separate thread by a garbage collector
	// so we need a new autorelease pool in case threre are autoreleased objects
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	_view.delegate = nil;
	[_view release];
	_view = nil;

	[pool release];
	[super dealloc];
}

- (void)show
{
	gAdState = kAdWillAppear;
	[_view presentFromViewController:_presentController];
}

- (void)unloadAD
{
	if (_view)
	{
		_view.delegate = nil;
		[_view release];
	}
	_view = nil;
}

- (void)reloadAD
{
	[self unloadAD];

	_view = [[ADInterstitialAd alloc] init];
	_view.delegate = self;
}

- (BOOL)interstitialAdActionShouldBegin:(ADInterstitialAd *)banner willLeaveApplication:(BOOL)willLeave
{
	return YES;
}

- (void)interstitialAd:(ADInterstitialAd*)interstitialAd didFailWithError:(NSError*)error
{
	::printf_console("ADInterstitialAd error: %s\n", [[error localizedDescription] UTF8String]);
	[self reloadAD];
}

- (void)interstitialAdDidUnload:(ADInterstitialAd*)interstitialAd
{
	[GetAppController() updateOrientationFromController:UnityGetGLViewController()];

	if(_autoReload)	[self reloadAD];
	else			[self unloadAD];
}

- (void)interstitialAdActionDidFinish:(ADInterstitialAd*)interstitialAd
{
	[GetAppController() updateOrientationFromController:UnityGetGLViewController()];

	if(_autoReload)	[self reloadAD];
	else			[self unloadAD];
}

- (void)interstitialAdDidLoad:(ADInterstitialAd*)interstitialAd
{
	UnityADInterstitialADWasLoaded();
}

- (void)viewDidDisappear:(BOOL)animated
{
	// this view disappeared and ad view appeared
	if (gAdState == kAdWillAppear)
	{
		UnityPause(true);
		gAdState = kAdVisible;
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	// this view will appear and ad view will disappear
	if (gAdState == kAdVisible)
	{
		UnityPause(false);
		gAdState = kAdNone;
	}
}

@end

//==============================================================================

#if UNITY_PRE_IOS6_TARGET
void Banner_InitRequiredContentSizes(ADBannerView* view)
{
	NSMutableSet* contentSize = [[NSMutableSet alloc] init];
	if(UnityIsOrientationEnabled(autorotPortrait) || UnityIsOrientationEnabled(autorotPortraitUpsideDown))
		[contentSize addObject: _ios42orNewer ? ADBannerContentSizeIdentifierPortrait : ADBannerContentSizeIdentifier320x50];
	if(UnityIsOrientationEnabled(autorotLandscapeLeft) || UnityIsOrientationEnabled(autorotLandscapeRight))
		[contentSize addObject: _ios42orNewer ? ADBannerContentSizeIdentifierLandscape : ADBannerContentSizeIdentifier480x32];

	view.requiredContentSizeIdentifiers = contentSize;
}

void Banner_UpdateCurrentContentSize(ADBannerView* view, UIInterfaceOrientation orient)
{
	if(orient == UIInterfaceOrientationPortrait || orient == UIInterfaceOrientationPortraitUpsideDown)
		view.currentContentSizeIdentifier = _ios42orNewer ? ADBannerContentSizeIdentifierPortrait : ADBannerContentSizeIdentifier320x50;
	else
		view.currentContentSizeIdentifier = _ios42orNewer ? ADBannerContentSizeIdentifierLandscape : ADBannerContentSizeIdentifier480x32;
}
#endif
