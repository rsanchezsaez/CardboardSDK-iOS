#pragma once

#include "UnityAppController.h"
#include <AvailabilityMacros.h>


@interface UnityAppController (ViewHandling)

// tweaking view hierarchy and handling of orientation

// there are 3 main uses cases regarding UI handling:
//
// 1. normal game case: you shouldnt care about all this at all
//
// 2. you need some not-so-trivial overlayed views and/or minor UI tweaking
//    most likely all you need is to subscribe to "orientation changed" notification
//    or in case you have per-orientation UI logic override willTransitionToViewController
//
// 3. you create UI-rich app where uinty view is just one of many
//    in that case you might want to create your own controllers and implement transitions on top
//    also instead of orientUnity: (and Screen.orientation in script) you should use orientInterface


// override this if you need customized unityview (subclassing)
// if you simply want different root view, tweak view hierarchy in createAutorotatingUnityViewController
- (UnityView*)createUnityView;

// for view controllers we have 2 cases:
// properly auto-rotating one VS the one with fixed orientation
// having special ViewController is a must to play nicely with ios8+ releases
// you are free to tweak your ViewController and return same object, though
// _unityView will be inited at the point of calling any of these methods
// please note that these are actual "create" methods: there is no need to tweak hierarchy right away

- (UIViewController*)createAutorotatingUnityViewController;
- (UIViewController*)createUnityViewControllerForOrientation:(UIInterfaceOrientation)orient;

// handling of changing ViewControllers:
// willStartWithViewController: will be called on startup, when creating view hierarchy
// transitionToViewController:fromViewController: will be called when user changes Screen.orientation
//   and we are forced to change root controller.
// by default:
// willStartWithViewController: will make _unityView as root view
// transitionToViewController:fromViewController: will simply move _rootView to a different controller
// you can use both to tweak view hierarchy if needed

- (void)willStartWithViewController:(UIViewController*)controller;
- (void)willTransitionToViewController:(UIViewController*)toController fromViewController:(UIViewController*)fromController;


// if you override these you need to call super

// if your root controller is not subclassed from UnityViewControllerBase, call these when rotation is happening
- (void)interfaceWillChangeOrientationTo:(UIInterfaceOrientation)toInterfaceOrientation;
- (void)interfaceDidChangeOrientationFrom:(UIInterfaceOrientation)fromInterfaceOrientation;


// you should not override these methods

// creates initial UI hierarchy (e.g. splash screen) and calls willStartWithViewController
- (void)createUI;
// shows game itself (hides splash, and bring _rootView to front)
- (void)showGameUI;

// will create or return from cache correct view controller for requested orientation
- (UIViewController*)createRootViewController;
// will create or return from cache correct view controller for given orientation
- (UIViewController*)createRootViewControllerForOrientation:(UIInterfaceOrientation)orientation;

// forcibly orient interface
- (void)orientInterface:(UIInterfaceOrientation)orient;

// use this one in case of simple view hierarchy (e.g. when unity view is root)
// this will fail if unity content orientation do not match actual ViewController orientation (e.g. portrait view inside landscape VC)
// this one is called when you change Screen.orientation in script
- (void)orientUnity:(ScreenOrientation)orient;

// check unity requested orientation and applies it
- (void)checkOrientationRequest;

// old deprecated methods: no longer used
// the caveat is: there are some issues in clang related to method deprecation
// which results in warnings not being generated for overriding deprecated methods (in some circumstances).
// so instead of deprecating these methods we just remove them and will check at runtime if user have them and whine about it

//- (UnityView*)createUnityViewImpl DEPRECATED_MSG_ATTRIBUTE("Will not be called. Override createUnityView");
//- (void)createViewHierarchyImpl DEPRECATED_MSG_ATTRIBUTE("Will not be called. Override willStartWithViewController");
//- (void)createViewHierarchy DEPRECATED_MSG_ATTRIBUTE("Is not implemented. Use createUI");


@end
