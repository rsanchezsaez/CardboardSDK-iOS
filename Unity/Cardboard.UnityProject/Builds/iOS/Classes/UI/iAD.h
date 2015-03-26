#pragma once

#import <iAd/iAd.h>
#include "PluginBase/UnityViewControllerListener.h"

extern "C" typedef void (*ADErrorDelegate)(void*, int, const char*, const char*);

enum
{
	// how the values are constructed:
	// top    = 0
	// bottom = 1
	// center = 2
	// left   = 0 << 2
	// right  = 1 << 2
	// center = 2 << 2
	// then we just or horz/vert
	// for banner we just & 0x1, so top->top, botton->bottom, center->top

	layoutMaskTop = 0,
	layoutMaskBottom = 1,
	layoutMaskLeft = 0,
	layoutMaskRight = 1,
	layoutMaskCenter = 2,
	layoutMaskUser = 3,

	layoutShiftHorz = 2,
	layoutMaskVert = 3,
	layoutMaskHorz = 3 << layoutShiftHorz,
};

typedef enum
{
	// these are for rect
	adbannerTopLeft			= layoutMaskTop | (layoutMaskLeft << layoutShiftHorz),
	adbannerTopRight		= layoutMaskTop | (layoutMaskRight << layoutShiftHorz),
	adbannerTopCenter		= layoutMaskTop | (layoutMaskCenter << layoutShiftHorz),

	adbannerBottomLeft		= layoutMaskBottom | (layoutMaskLeft << layoutShiftHorz),
	adbannerBottomRight		= layoutMaskBottom | (layoutMaskRight << layoutShiftHorz),
	adbannerBottomCenter	= layoutMaskBottom | (layoutMaskCenter << layoutShiftHorz),

	adbannerCenterLeft		= layoutMaskCenter | (layoutMaskLeft << layoutShiftHorz),
	adbannerCenterRight		= layoutMaskCenter | (layoutMaskRight << layoutShiftHorz),
	adbannerCenter			= layoutMaskCenter | (layoutMaskCenter << layoutShiftHorz),

	// these are for banner
	adbannerTop				= 0,
	adbannerBottom			= 1,

	adbannerManual			= -1
}
ADBannerLayout;

typedef enum
{
	adbannerBanner		= 0,
	adbannerMediumRect	= 1
}
ADBannerType;


@interface UnityADBanner : NSObject <ADBannerViewDelegate, UnityViewControllerListener>
{
	ADBannerView*	_view;

	CGPoint			_userLayoutCenter;
	ADBannerLayout	_bannerLayout;
	BOOL			_showingBanner;
}
- (id)initWithParent:(UIView*)parent layout:(ADBannerLayout)layout;
- (id)initWithParent:(UIView*)parent layout:(ADBannerLayout)layout type:(ADBannerType)type;

- (void)positionForUserLayout:(CGPoint)center;
- (void)layoutBanner:(ADBannerLayout)layout;
- (void)showBanner:(BOOL)show;

@property (readonly, copy, nonatomic) ADBannerView* view;
@property (readonly, nonatomic) BOOL adVisible;

@end

@interface UnityInterstitialAd : NSObject <ADInterstitialAdDelegate, UnityViewControllerListener>
{
	ADInterstitialAd*	_view;
	UIViewController*	_presentController;

	BOOL				_autoReload;
}
- (id)initWithController:(UIViewController*)presentController autoReload:(BOOL)autoReload;
- (void)show;
- (void)reloadAD;

@property (readonly, copy, nonatomic) ADInterstitialAd* view;

@end
