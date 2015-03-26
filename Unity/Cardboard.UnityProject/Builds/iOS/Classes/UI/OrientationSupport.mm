#include "OrientationSupport.h"
#include <math.h>

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
	switch(orient)
	{
		case portrait:				return UIInterfaceOrientationPortrait;
		case portraitUpsideDown:	return UIInterfaceOrientationPortraitUpsideDown;
		// landscape left/right have switched values in device/screen orientation
		// though unity docs are adjusted with device orientation values, so swap here
		case landscapeLeft:			return UIInterfaceOrientationLandscapeRight;
		case landscapeRight:		return UIInterfaceOrientationLandscapeLeft;

		case orientationUnknown:	return (UIInterfaceOrientation)UIInterfaceOrientationUnknown;

		default:					return UIInterfaceOrientationPortrait;
	}

	return UIInterfaceOrientationPortrait;
}

ScreenOrientation ConvertToUnityScreenOrientation(UIInterfaceOrientation orient)
{
	switch(orient)
	{
		case UIInterfaceOrientationPortrait:			return portrait;
		case UIInterfaceOrientationPortraitUpsideDown:	return portraitUpsideDown;
		// landscape left/right have switched values in device/screen orientation
		// though unity docs are adjusted with device orientation values, so swap here
		case UIInterfaceOrientationLandscapeLeft:		return landscapeRight;
		case UIInterfaceOrientationLandscapeRight:		return landscapeLeft;

		case UIInterfaceOrientationUnknown:				return orientationUnknown;

		default:										return portrait;
	}
}

ScreenOrientation OrientationAfterTransform(ScreenOrientation curOrient, CGAffineTransform transform)
{
	int rotDeg = (int)::roundf(::atan2f(transform.b, transform.a) * (180 / M_PI));
	assert(rotDeg == 0 || rotDeg == 90 || rotDeg == -90 || rotDeg == 180 || rotDeg == -180);

	if(rotDeg == 0)
	{
		return curOrient;
	}
	else if((rotDeg == 180) || (rotDeg == -180))
	{
		if(curOrient == portrait)					return portraitUpsideDown;
		else if(curOrient == portraitUpsideDown)	return portrait;
		else if(curOrient == landscapeRight)		return landscapeLeft;
		else if(curOrient == landscapeLeft)			return landscapeRight;
	}
	else if(rotDeg == 90)
	{
		if(curOrient == portrait)					return landscapeLeft;
		else if(curOrient == portraitUpsideDown)	return landscapeRight;
		else if(curOrient == landscapeRight)		return portrait;
		else if(curOrient == landscapeLeft)			return portraitUpsideDown;
	}
	else if(rotDeg == -90)
	{
		if(curOrient == portrait)					return landscapeRight;
		else if(curOrient == portraitUpsideDown)	return landscapeLeft;
		else if(curOrient == landscapeRight)		return portraitUpsideDown;
		else if(curOrient == landscapeLeft)			return portrait;
	}

	::printf("rotation unhandled: %d\n", rotDeg);
	return curOrient;
}


void OrientView(UIViewController* host, UIView* view, ScreenOrientation to)
{
	ScreenOrientation fromController = ConvertToUnityScreenOrientation(host.interfaceOrientation);

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
