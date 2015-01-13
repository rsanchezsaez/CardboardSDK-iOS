//
//  AppDelegate.m
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "AppDelegate.h"

#import "GLCubeViewController.h"
#import "CardboardViewController.h"
#import "StereoCubeViewController.h"
#import "TreasureViewController.h"

@interface AppDelegate ()

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    // Non-stereo plain OpenGL example
//    GLCubeViewController *cardboardViewController = [GLCubeViewController new];

    // Stereo cube example (wip)
    StereoCubeViewController *cardboardViewController = [StereoCubeViewController new];

    // Google's treasure example
//    TreasureViewController *cardboardViewController = [TreasureViewController new];
    
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
