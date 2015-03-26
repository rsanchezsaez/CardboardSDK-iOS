#ifndef _TRAMPOLINE_PLUGINBASE_MAIN_VIEW_CONTROLLER_LISTENER_H_
#define _TRAMPOLINE_PLUGINBASE_MAIN_VIEW_CONTROLLER_LISTENER_H_

#import <Foundation/NSNotification.h>

// view changes on the main view controller

@protocol UnityViewControllerListener<NSObject>
@optional
- (void)viewDidDisappear:(NSNotification*)notification;
- (void)viewWillDisappear:(NSNotification*)notification;
- (void)viewDidAppear:(NSNotification*)notification;
- (void)viewWillAppear:(NSNotification*)notification;

- (void)interfaceWillChangeOrientation:(NSNotification*)notification;
- (void)interfaceDidChangeOrientation:(NSNotification*)notification;
@end

void UnityRegisterViewControllerListener(id<UnityViewControllerListener> obj);
void UnityUnregisterViewControllerListener(id<UnityViewControllerListener> obj);

extern "C" __attribute__((visibility ("default"))) NSString* const kUnityViewDidDisappear;
extern "C" __attribute__((visibility ("default"))) NSString* const kUnityViewDidAppear;
extern "C" __attribute__((visibility ("default"))) NSString* const kUnityViewWillDisappear;
extern "C" __attribute__((visibility ("default"))) NSString* const kUnityViewWillAppear;
extern "C" __attribute__((visibility ("default"))) NSString* const kUnityInterfaceWillChangeOrientation;
extern "C" __attribute__((visibility ("default"))) NSString* const kUnityInterfaceDidChangeOrientation;

#endif // _TRAMPOLINE_PLUGINBASE_LIFECYCLELISTENER_H_
