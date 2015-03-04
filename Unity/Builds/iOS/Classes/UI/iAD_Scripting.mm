#include "iAD.h"


extern "C" UIViewController*	UnityGetGLViewController();
extern "C" UIView*				UnityGetGLView();


//==============================================================================
//
//  iAD Unity Interface

bool UnityAD_BannerTypeAvailable(int type)
{
	if(type == adbannerBanner)
		return true; // since 4.0 (we enforce 4.0 as min target)
	else if(type == adbannerMediumRect)
		return _ios60orNewer && !UNITY_PRE_IOS6_SDK;

	return false;
}

void* UnityAD_CreateBanner(int type, int layout)
{
	return [[UnityADBanner alloc] initWithParent:UnityGetGLView() layout:(ADBannerLayout)layout type:(ADBannerType)type];
}

void UnityAD_DestroyBanner(void* target)
{
	[(UnityADBanner*)target release];
}

void UnityAD_ShowBanner(void* target, bool show)
{
	[(UnityADBanner*)target showBanner:show];
}

void UnityAD_MoveBanner(void* target, float /*x_*/, float y_)
{
	UIView* view   = ((UnityADBanner*)target).view;
	UIView* parent = view.superview;

	float x = parent.bounds.size.width/2;
	float h = view.bounds.size.height;
	float y = parent.bounds.size.height * y_ + h/2;

	[(UnityADBanner*)target positionForUserLayout:CGPointMake(x, y)];
	[(UnityADBanner*)target layoutBanner:adbannerManual];
	[parent layoutSubviews];
}

void UnityAD_BannerPosition(void* target, float* x, float* y)
{
	UIView* view   = ((UnityADBanner*)target).view;
	UIView* parent = view.superview;

	CGPoint c = view.center;
	CGSize ext = view.bounds.size, pext = parent.bounds.size;

	*x = (c.x - ext.width/2)  / pext.width;
	*y = (c.y - ext.height/2) / pext.height;
}

void UnityAD_BannerSize(void* target, float* w, float* h)
{
	UIView* view   = ((UnityADBanner*)target).view;
	UIView* parent = view.superview;

	CGSize ext = view.bounds.size, pext = parent.bounds.size;

	*w = ext.width  / pext.width;
	*h = ext.height / pext.height;
}

void UnityAD_LayoutBanner(void* target, int layout)
{
	[(UnityADBanner*)target layoutBanner:(ADBannerLayout)layout];
}

bool UnityAD_BannerAdLoaded(void* target)
{
	return ((UnityADBanner*)target).view.bannerLoaded;
}

bool UnityAD_BannerAdVisible(void* target)
{
	return ((UnityADBanner*)target).adVisible;
}


bool UnityAD_InterstitialAvailable()
{
	return _ios43orNewer && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

void* UnityAD_CreateInterstitial(bool autoReload)
{
	if(!UnityAD_InterstitialAvailable())
	{
		::printf_console("ADInterstitialAd is not available.\n");
		return 0;
	}
	return [[UnityInterstitialAd alloc] initWithController:UnityGetGLViewController() autoReload:autoReload];
}
void UnityAD_DestroyInterstitial(void* target)
{
	if(target)
		[(UnityInterstitialAd*)target release];
}

void UnityAD_ShowInterstitial(void* target)
{
	if(target)
		[(UnityInterstitialAd*)target show];
}

void UnityAD_ReloadInterstitial(void* target)
{
	if(target)
		[(UnityInterstitialAd*)target reloadAD];
}

bool UnityAD_InterstitialAdLoaded(void* target)
{
	return target ? ((UnityInterstitialAd*)target).view.loaded : false;
}


