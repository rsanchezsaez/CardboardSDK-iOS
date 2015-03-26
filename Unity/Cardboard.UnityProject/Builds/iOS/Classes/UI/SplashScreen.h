#pragma once

#include "UnityViewControllerBase.h"


@interface SplashScreen : UIImageView { }
+ (SplashScreen*)Instance;
@end

@interface SplashScreenController : UnityViewControllerBase	{}
+ (SplashScreenController*)Instance;
@end

void	ShowSplashScreen(UIWindow* window);
void	HideSplashScreen();
