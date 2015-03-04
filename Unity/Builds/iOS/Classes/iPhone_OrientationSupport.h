
#ifndef _TRAMPOLINE_IPHONE_ORIENTATIONSUPPORT_H_
#define _TRAMPOLINE_IPHONE_ORIENTATIONSUPPORT_H_

#import <QuartzCore/QuartzCore.h>


ScreenOrientation       ConvertToUnityScreenOrientation(UIInterfaceOrientation hwOrient, EnabledOrientation* outAutorotOrient);
UIInterfaceOrientation  ConvertToIosScreenOrientation(ScreenOrientation orient);

CGAffineTransform       TransformForOrientation(ScreenOrientation curOrient);
CGAffineTransform		TransformBetweenOrientations(ScreenOrientation fromOrient, ScreenOrientation toOrient);

void					OrientView(UIViewController* host, UIView* view, ScreenOrientation target);


extern "C" __attribute__((visibility ("default"))) NSString * const kUnityViewWillRotate;
extern "C" __attribute__((visibility ("default"))) NSString * const kUnityViewDidRotate;


#endif // _TRAMPOLINE_IPHONE_ORIENTATIONSUPPORT_H_
