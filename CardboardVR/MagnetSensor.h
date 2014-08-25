//
//  MagnetSensor.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-20.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MagnetSensor;

@protocol MagnetSensorDelegate

-(void)triggerClicked:(MagnetSensor *)magnetSensor;

@end

@interface MagnetSensor : NSObject

@property (nonatomic, assign) id delegate;

- (void)start;
- (void)stop;

@end
