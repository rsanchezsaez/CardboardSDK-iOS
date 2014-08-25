//
//  HeadMountedDisplay.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "HeadMountedDisplay.h"

@interface HeadMountedDisplay ()

@property (nonatomic, strong) ScreenParams *screen;
@property (nonatomic, strong) CardboardDeviceParams *cardboard;

@end

@implementation HeadMountedDisplay

- (id)initWithDisplay:(UIScreen*)screen
{
    self = [super init];
    if (self)
    {
        self.screen = [[ScreenParams alloc] initWithScreen:screen];
        self.cardboard = [[CardboardDeviceParams alloc] init];
        
    }
    return self;
}

- (id)initWithHeadMountedDisplay:(HeadMountedDisplay*)hmd
{
    self = [super init];
    if (self)
    {
        self.screen = [[ScreenParams alloc] initWithScreenParams:[hmd getScreen]];
        self.cardboard = [[CardboardDeviceParams alloc] initWithCardboardDeviceParams:[hmd getCardboard]];
    }
    return self;
}

- (void)setScreen:(ScreenParams*)screen
{
    self.screen = [[ScreenParams alloc] initWithScreenParams:screen];
}

- (ScreenParams*)getScreen
{
    return self.screen;
}

- (void)setCardboard:(CardboardDeviceParams*)cardboard
{
    self.cardboard = [[CardboardDeviceParams alloc] initWithCardboardDeviceParams:cardboard];
}

- (CardboardDeviceParams *)getCardboard
{
    return self.cardboard;
}

- (bool)equals:(id)other
{
    if (other == nil)
    {
        return false;
    }
    if (other == self)
    {
        return true;
    }
    if (![other isKindOfClass:[Distortion class]])
    {
        return false;
    }
    HeadMountedDisplay *o = (HeadMountedDisplay *)other;
    return ([self.screen equals:[o getScreen]]) && ([self.cardboard equals:[o getCardboard]]);
}

@end
