#pragma once

@class UnityView;

@interface UnityViewControllerBase : UIViewController
{
}
- (BOOL)shouldAutorotate;

- (BOOL)prefersStatusBarHidden;
- (UIStatusBarStyle)preferredStatusBarStyle;
@end

// for better handling of user-imposed screen orientation we will have specific ViewController implementations

// view controllers constrained to one orientation
//

@interface UnityPortraitOnlyViewController : UnityViewControllerBase
{
}
- (NSUInteger)supportedInterfaceOrientations;
@end
@interface UnityPortraitUpsideDownOnlyViewController : UnityViewControllerBase
{
}
- (NSUInteger)supportedInterfaceOrientations;
@end
@interface UnityLandscapeLeftOnlyViewController : UnityViewControllerBase
{
}
- (NSUInteger)supportedInterfaceOrientations;
@end
@interface UnityLandscapeRightOnlyViewController : UnityViewControllerBase
{
}
- (NSUInteger)supportedInterfaceOrientations;
@end


// this is default view controller implementation (autorotation enabled)
//

@interface UnityDefaultViewController : UnityViewControllerBase
{
}
- (NSUInteger)supportedInterfaceOrientations;
@end


// this is helper to add proper rotation handling methods depending on ios version
extern "C" void AddViewControllerRotationHandling(Class class_, IMP willRotateToInterfaceOrientation, IMP didRotateFromInterfaceOrientation, IMP viewWillTransitionToSize);
extern "C" void AddViewControllerDefaultRotationHandling(Class class_);
