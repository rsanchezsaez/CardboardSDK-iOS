
#include "VideoViewController.h"
#include "UnityAppController.h"
#include "UnityView.h"
#include "UnityViewControllerBase.h"
#include "iPhone_OrientationSupport.h"


@implementation UnityVideoViewController

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[GetAppController().unityView willRotateTo:ConvertToUnityScreenOrientation(toInterfaceOrientation, 0)];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[GetAppController().rootView layoutSubviews];
	[GetAppController().unityView didRotate];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        NSArray *array = touch.gestureRecognizers;
        for (UIGestureRecognizer *gesture in array)
        {
            if (gesture.enabled && [gesture isMemberOfClass:[UIPinchGestureRecognizer class]])
                gesture.enabled = NO;
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    UnityPause(false);
}

+ (void)Initialize
{
    static bool _ClassInited = false;
    if(!_ClassInited)
    {
        AddOrientationSupportDefaultImpl([UnityVideoViewController class]);
        _ClassInited = true;
    }
}

@end
