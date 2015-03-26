
#include "OrientationSupport.h"
#include "iAD.h"

#include "UnityAppController+ViewHandling.h"
#include "UnityView.h"

@implementation UnityADBanner

@synthesize view = _view;
@synthesize adVisible = _showingBanner;

- (void)initImpl:(UIView*)parent layout:(ADBannerLayout)layout type:(ADBannerType)type
{
	UnityRegisterViewControllerListener((id<UnityViewControllerListener>)self);

	_view = [[ADBannerView alloc] initWithAdType:(ADAdType)type];
	_view.contentScaleFactor = [UIScreen mainScreen].scale;
	_view.bounds = parent.bounds;
	_view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	_view.delegate = self;

	_bannerLayout	= layout;
	_showingBanner	= NO;

	[parent addSubview:_view];
	[self layoutBannerImpl];

	UnitySetViewTouchProcessing(_view, touchesTransformedToUnityViewCoords);
}

- (float)layoutXImpl:(UIView*)parent
{
	bool	rectBanner	= _view.adType == ADAdTypeMediumRectangle;
	float	x			= parent.bounds.size.width/2;
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

	bool	rectBanner	= _view.adType == ADAdTypeMediumRectangle;
	float	y			= 0;
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

	CGRect rect = _view.bounds;
	rect.size = [_view sizeThatFits:parent.bounds.size];

	_view.center = CGPointMake(cx,cy);
	_view.bounds = rect;

	[parent layoutSubviews];
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
	@autoreleasepool
	{
		UnityUnregisterViewControllerListener((id<UnityViewControllerListener>)self);
		UnityDropViewTouchProcessing(_view);

		_view.delegate = nil;
		[_view removeFromSuperview];
		_view = nil;
	}
}

- (void)interfaceWillChangeOrientation:(NSNotification*)notification
{
	_view.hidden = YES;
}
- (void)interfaceDidChangeOrientation:(NSNotification*)notification
{
	if(_showingBanner)
		_view.hidden = NO;

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
		UnityPause(1);
	return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView*)banner
{
	UnityPause(0);
	UnityADBannerViewWasClicked();
}

- (void)bannerViewDidLoadAd:(ADBannerView*)banner
{
	UnityADBannerViewWasLoaded();
}

- (void)bannerView:(ADBannerView*)banner didFailToReceiveAdWithError:(NSError*)error
{
	::printf("ADBannerView error: %s\n", [[error localizedDescription] UTF8String]);
	_showingBanner = NO;
	[self layoutBannerImpl];
}

@end

enum AdState
{
	kAdNone,
	kAdWillAppear,
	kAdVisible,
};

AdState gAdState = kAdNone;

@implementation UnityInterstitialAd

@synthesize view = _view;

- (id)initWithController:(UIViewController*)presentController autoReload:(BOOL)autoReload
{
	if( (self = [super init]) )
	{
		UnityRegisterViewControllerListener((id<UnityViewControllerListener>)self);

		_view = [[ADInterstitialAd alloc] init];
		_view.delegate = self;

		_presentController	= presentController;
		_autoReload			= autoReload;
	}

	return self;
}
- (void)dealloc
{
	UnityUnregisterViewControllerListener((id<UnityViewControllerListener>)self);
	// dtor might be called from a separate thread by a garbage collector
	// so we need a new autorelease pool in case threre are autoreleased objects
	@autoreleasepool
	{
		_view.delegate = nil;
		_view = nil;
	}
}

- (void)show
{
	gAdState = kAdWillAppear;
	[_view presentFromViewController:_presentController];
}

- (void)unloadAD
{
	if(_view)
		_view.delegate = nil;

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
	::printf("ADInterstitialAd error: %s\n", [[error localizedDescription] UTF8String]);
	[self reloadAD];
}

- (void)interstitialAdDidUnload:(ADInterstitialAd*)interstitialAd
{

	if(_autoReload)	[self reloadAD];
	else			[self unloadAD];
}

- (void)interstitialAdActionDidFinish:(ADInterstitialAd*)interstitialAd
{

	if(_autoReload)	[self reloadAD];
	else			[self unloadAD];
}

- (void)interstitialAdDidLoad:(ADInterstitialAd*)interstitialAd
{
	UnityADInterstitialADWasLoaded();
}

- (void)viewDidDisappear:(NSNotification*)notification
{
	// this view disappeared and ad view appeared
	if(gAdState == kAdWillAppear)
	{
		UnityPause(1);
		gAdState = kAdVisible;
	}
}

- (void)viewWillAppear:(NSNotification*)notification
{
	// this view will appear and ad view will disappear
	if(gAdState == kAdVisible)
	{
		UnityPause(0);
		gAdState = kAdNone;
	}
}

@end
