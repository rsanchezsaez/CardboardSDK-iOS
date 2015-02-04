//
//  AppDelegate.m
//  CardboardSDK-iOS
//
//

#import "AppDelegate.h"

#import "CardboardSDK/CardboardSDK.h"
#import "TreasureViewController.h"

//#import "CardboardUnity.h"
//void _unity_getFrameParameters(float *frameParameters);


@interface AppDelegate ()

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    // Google's treasure example
    TreasureViewController *cardboardViewController = [TreasureViewController new];
    
//    float *frameParameters = calloc(80, sizeof(float));
//    _unity_getFrameParameters(frameParameters);
    
    self.window.rootViewController = cardboardViewController;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
