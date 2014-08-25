//
//  HeadMountedDisplay.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScreenParams.h"
#import "CardboardDeviceParams.h"

@interface HeadMountedDisplay : NSObject

- (id)initWithDisplay:(UIScreen*)screen;
- (id)initWithHeadMountedDisplay:(HeadMountedDisplay*)hmd;
- (void)setScreen:(ScreenParams*)screen;
- (ScreenParams*)getScreen;
- (void)setCardboard:(CardboardDeviceParams*)cardboard;
- (CardboardDeviceParams *)getCardboard;
- (bool)equals:(id)other;

@end
