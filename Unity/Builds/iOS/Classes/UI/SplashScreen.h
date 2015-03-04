#ifndef _TRAMPOLINE_UI_SPLASHSCREEN_H_
#define _TRAMPOLINE_UI_SPLASHSCREEN_H_

#import <UIKit/UIKit.h>


@interface SplashScreen : UIImageView { }
+ (SplashScreen*)Instance;
@end

@interface SplashScreenController : UIViewController {}
+ (SplashScreenController*)Instance;
@end

void    ShowSplashScreen(UIWindow* window);
void    HideSplashScreen();

#endif // _TRAMPOLINE_UI_SPLASHSCREEN_H_
