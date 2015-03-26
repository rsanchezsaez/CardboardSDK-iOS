#include "iAD.h"

//==============================================================================
//
//  iAD Unity Interface

bool UnityAD_BannerTypeAvailable(int type)
{
	if(type == adbannerBanner || type == adbannerMediumRect)
		return true;

	return false;
}

void* UnityAD_CreateBanner(int type, int layout)
{
	UnityADBanner* banner = [[UnityADBanner alloc] initWithParent:UnityGetGLView() layout:(ADBannerLayout)layout type:(ADBannerType)type];
	return (__bridge_retained void*)banner;
}

void UnityAD_DestroyBanner(void* target)
{
	UnityADBanner* banner = (__bridge_transfer UnityADBanner*)target;
	banner = nil;
}

void UnityAD_ShowBanner(void* target, bool show)
{
	[(__bridge UnityADBanner*)target showBanner:show];
}

void UnityAD_MoveBanner(void* target, float /*x_*/, float y_)
{
	UnityADBanner* banner = (__bridge UnityADBanner*)target;

	UIView* view   = banner.view;
	UIView* parent = view.superview;

	float x = parent.bounds.size.width/2;
	float h = view.bounds.size.height;
	float y = parent.bounds.size.height * y_ + h/2;

	[banner positionForUserLayout:CGPointMake(x, y)];
	[banner layoutBanner:adbannerManual];
	[parent layoutSubviews];
}

void UnityAD_BannerPosition(void* target, float* x, float* y)
{
	UIView* view   = ((__bridge UnityADBanner*)target).view;
	UIView* parent = view.superview;

	CGPoint	c	= view.center;
	CGSize	ext	= view.bounds.size, pext = parent.bounds.size;

	*x = (c.x - ext.width/2)  / pext.width;
	*y = (c.y - ext.height/2) / pext.height;
}

void UnityAD_BannerSize(void* target, float* w, float* h)
{
	UIView* view   = ((__bridge UnityADBanner*)target).view;
	UIView* parent = view.superview;

	CGSize ext = view.bounds.size, pext = parent.bounds.size;

	*w = ext.width  / pext.width;
	*h = ext.height / pext.height;
}

void UnityAD_LayoutBanner(void* target, int layout)
{
	[(__bridge UnityADBanner*)target layoutBanner:(ADBannerLayout)layout];
}

bool UnityAD_BannerAdLoaded(void* target)
{
	return ((__bridge UnityADBanner*)target).view.bannerLoaded;
}

bool UnityAD_BannerAdVisible(void* target)
{
	return ((__bridge UnityADBanner*)target).adVisible;
}


bool UnityAD_InterstitialAvailable()
{
	return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

void* UnityAD_CreateInterstitial(bool autoReload)
{
	if(!UnityAD_InterstitialAvailable())
	{
		::printf("ADInterstitialAd is not available.\n");
		return 0;
	}

	UnityInterstitialAd* ad = [[UnityInterstitialAd alloc] initWithController:UnityGetGLViewController() autoReload:autoReload];
	return (__bridge_retained void*)ad;
}
void UnityAD_DestroyInterstitial(void* target)
{
	if(target)
	{
		UnityInterstitialAd* ad = (__bridge_transfer UnityInterstitialAd*)target;
		ad = nil;
	}
}

void UnityAD_ShowInterstitial(void* target)
{
	if(target)
		[(__bridge UnityInterstitialAd*)target show];
}

void UnityAD_ReloadInterstitial(void* target)
{
	if(target)
		[(__bridge UnityInterstitialAd*)target reloadAD];
}

bool UnityAD_InterstitialAdLoaded(void* target)
{
	return target ? ((__bridge UnityInterstitialAd*)target).view.loaded : false;
}
