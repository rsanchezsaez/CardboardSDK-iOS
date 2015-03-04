#ifndef _TRAMPOLINE_PLUGINBASE_MAIN_VIEW_CONTROLLER_LISTENER_H_
#define _TRAMPOLINE_PLUGINBASE_MAIN_VIEW_CONTROLLER_LISTENER_H_

#import <Foundation/NSNotification.h>

// view changes on the main view controller

@protocol MainViewControllerListener<NSObject>
@optional
- (void)viewDidDisappear:(NSNotification*)notification;
- (void)viewWillDisappear:(NSNotification*)notification;
- (void)viewDidAppear:(NSNotification*)notification;
- (void)viewWillAppear:(NSNotification*)notification;
@end

void UnityRegisterMainViewControllerListener(id<MainViewControllerListener> obj);
void UnityUnregisterMainViewControllerListener(id<MainViewControllerListener> obj);

extern "C" __attribute__((visibility ("default"))) NSString* const kUnityMainViewDidDisappear;
extern "C" __attribute__((visibility ("default"))) NSString* const kUnityMainViewDidAppear;
extern "C" __attribute__((visibility ("default"))) NSString* const kUnityMainViewWillDisappear;
extern "C" __attribute__((visibility ("default"))) NSString* const kUnityMainViewWillAppear;

#endif // _TRAMPOLINE_PLUGINBASE_LIFECYCLELISTENER_H_
