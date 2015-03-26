#include "UnityAppController.h"


@interface UnityAppController (ViewHandling)

// override this to tweak unity view hierarchy
// _unityView will be inited at this point
// you need to init _rootView and _rootController
- (void)createViewHierarchyImpl;

// override this only if you need customized unityview
- (UnityView*)initUnityViewImpl;

// these will have special meaning only on ios8+ and when built with ios8 sdk
// for view controllers we have 2 cases:
// properly auto-rotating one VS the one fixed orientation
// having special ViewController is a must to play nicely with ios8+ releases
// you are free to tweak your ViewController and return same object, though
// _unityView will be inited at the point of calling any of these methods
// please note that these methods might be called during normal app operation
// so if you want to override createViewHierarchyImpl you most likely want to override thise two and call them from createViewHierarchyImpl

- (UIViewController*)createAutorotatingUnityViewController;
- (UIViewController*)createUnityViewControllerForOrientation:(ScreenOrientation)orient;


// you should not override these methods in usual case
- (void)createViewHierarchy;
- (void)releaseViewHierarchy;
- (UnityView*)initUnityView;
- (UIViewController*)createRootViewController;
- (void)showGameUI;


- (void)orientUnity:(ScreenOrientation)orient;
- (void)updateOrientationFromController:(UIViewController*)controller;

@end
