#pragma once

#include <CoreGraphics/CGAffineTransform.h>


ScreenOrientation		ConvertToUnityScreenOrientation(UIInterfaceOrientation hwOrient);
UIInterfaceOrientation	ConvertToIosScreenOrientation(ScreenOrientation orient);

CGAffineTransform		TransformForOrientation(ScreenOrientation curOrient);
CGAffineTransform		TransformBetweenOrientations(ScreenOrientation fromOrient, ScreenOrientation toOrient);

ScreenOrientation		OrientationAfterTransform(ScreenOrientation curOrient, CGAffineTransform transform);

void					OrientView(UIViewController* host, UIView* view, ScreenOrientation to);


#if !UNITY_IOS8_ORNEWER_SDK
	static const NSInteger UIInterfaceOrientationUnknown = 0;
#endif
