#include "iPhone_OrientationSupport.h"

#include <algorithm>


CGAffineTransform TransformForOrientation(ScreenOrientation orient)
{
	switch(orient)
	{
		case portrait:              return CGAffineTransformIdentity;
		case portraitUpsideDown:    return CGAffineTransformMakeRotation(M_PI);
		case landscapeLeft:         return CGAffineTransformMakeRotation(M_PI_2);
		case landscapeRight:        return CGAffineTransformMakeRotation(-M_PI_2);

		default:                    return CGAffineTransformIdentity;
	}
	return CGAffineTransformIdentity;
}
CGAffineTransform TransformBetweenOrientations(ScreenOrientation fromOrient, ScreenOrientation toOrient)
{
	CGAffineTransform fromTransform	= TransformForOrientation(fromOrient);
	CGAffineTransform toTransform	= TransformForOrientation(toOrient);

	return CGAffineTransformConcat(CGAffineTransformInvert(fromTransform), toTransform);
}


UIInterfaceOrientation ConvertToIosScreenOrientation(ScreenOrientation orient)
{
	switch( orient )
	{
		case portrait:              return UIInterfaceOrientationPortrait;
		case portraitUpsideDown:    return UIInterfaceOrientationPortraitUpsideDown;
		// landscape left/right have switched values in device/screen orientation
		// though unity docs are adjusted with device orientation values, so swap here
		case landscapeLeft:         return UIInterfaceOrientationLandscapeRight;
		case landscapeRight:        return UIInterfaceOrientationLandscapeLeft;

		default:                    return UIInterfaceOrientationPortrait;
	}

	return UIInterfaceOrientationPortrait;
}

ScreenOrientation ConvertToUnityScreenOrientation(UIInterfaceOrientation hwOrient, EnabledOrientation* outAutorotOrient)
{
	EnabledOrientation autorotOrient     = autorotPortrait;
	ScreenOrientation  unityScreenOrient = portrait;

	switch (hwOrient)
	{
		case UIInterfaceOrientationPortrait:
			autorotOrient     = autorotPortrait;
			unityScreenOrient = portrait;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			autorotOrient     = autorotPortraitUpsideDown;
			unityScreenOrient = portraitUpsideDown;
			break;
		// landscape left/right have switched values in device/screen orientation
		// though unity docs are adjusted with device orientation values, so swap here
		case UIInterfaceOrientationLandscapeLeft:
			autorotOrient     = autorotLandscapeRight;
			unityScreenOrient = landscapeRight;
			break;
		case UIInterfaceOrientationLandscapeRight:
			autorotOrient     = autorotLandscapeLeft;
			unityScreenOrient = landscapeLeft;
			break;
	}

	if (outAutorotOrient)
		*outAutorotOrient = autorotOrient;

	return unityScreenOrient;
}

void OrientView(UIViewController* host, UIView* view, ScreenOrientation to)
{
	ScreenOrientation fromController = ConvertToUnityScreenOrientation(host.interfaceOrientation,0);

	// before ios8 view transform is relative to portrait, while on ios8 it is relative to window/controller
	// caveat: if app was built with pre-ios8 sdk it will hit "backward compatibility" path
	const bool newRotationLogic = UNITY_IOS8_ORNEWER_SDK && _ios80orNewer;

	CGAffineTransform transform = newRotationLogic ? TransformBetweenOrientations(fromController, to) : TransformForOrientation(to);


	// this is for unity-inited orientation. In that case we need to manually adjust bounds if changing portrait/landscape
	// the easiest way would be to manually rotate current bounds (to acknowledge the fact that we do NOT rotate controller itself)
	// NB: as we use current view bounds we need to use view transform to properly adjust them
	CGRect rect	= view.bounds;
	CGSize ext	= CGSizeApplyAffineTransform(rect.size, CGAffineTransformConcat(CGAffineTransformInvert(view.transform), transform));

	view.transform	= transform;
	view.bounds		= CGRectMake(0, 0, ::fabs(ext.width), ::fabs(ext.height));
}


extern "C" __attribute__((visibility ("default"))) NSString * const kUnityViewWillRotate = @"kUnityViewWillRotate";
extern "C" __attribute__((visibility ("default"))) NSString * const kUnityViewDidRotate  = @"kUnityViewDidRotate";
