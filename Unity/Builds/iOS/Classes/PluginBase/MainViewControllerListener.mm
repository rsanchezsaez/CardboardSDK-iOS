
#include "MainViewControllerListener.h"
#include <UIKit/UIApplication.h>

#define DEFINE_NOTIFICATION(name) extern "C" __attribute__((visibility ("default"))) NSString* const name = @#name;

DEFINE_NOTIFICATION(kUnityMainViewDidDisappear);
DEFINE_NOTIFICATION(kUnityMainViewDidAppear);
DEFINE_NOTIFICATION(kUnityMainViewWillDisappear);
DEFINE_NOTIFICATION(kUnityMainViewWillAppear);

#undef DEFINE_NOTIFICATION

void UnityRegisterMainViewControllerListener(id<MainViewControllerListener> obj)
{
	#define REGISTER_SELECTOR(sel, notif_name)					\
	if([obj respondsToSelector:sel])							\
		[[NSNotificationCenter defaultCenter] 	addObserver:obj	\
												selector:sel	\
												name:notif_name	\
												object:nil		\
		];														\

	REGISTER_SELECTOR(@selector(viewDidDisappear:), kUnityMainViewDidDisappear);
	REGISTER_SELECTOR(@selector(viewWillDisappear:), kUnityMainViewDidAppear);
	REGISTER_SELECTOR(@selector(viewDidAppear:), kUnityMainViewWillDisappear);
	REGISTER_SELECTOR(@selector(viewWillAppear:), kUnityMainViewWillAppear);

	#undef REGISTER_SELECTOR
}

void UnityUnregisterMainViewControllerListener(id<MainViewControllerListener> obj)
{
	[[NSNotificationCenter defaultCenter] removeObserver:obj name:kUnityMainViewDidDisappear object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:obj name:kUnityMainViewDidAppear object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:obj name:kUnityMainViewWillDisappear object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:obj name:kUnityMainViewWillAppear object:nil];
}
