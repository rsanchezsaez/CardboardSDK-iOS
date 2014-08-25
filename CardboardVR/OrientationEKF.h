//
//  OrientationEKF.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-22.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Matrix3x3d.h"
#import "Vector3d.h"
#import "So3Util.h"
#import <GLKit/GLKit.h>

@interface OrientationEKF : NSObject

- (void)reset;
- (bool)isReady;
- (double)getHeadingDegrees;
- (void)setHeadingDegrees:(double)heading;
- (GLKMatrix4)getGLMatrix;
- (GLKMatrix4)getPredictedGLMatrix:(double)secondsAfterLastGyroEvent;
- (void)processGyro:(float)x y:(float)y z:(float)z sensorTimeStamp:(double)sensorTimeStamp;
- (void)processAcc:(float)x y:(float)y z:(float)z sensorTimeStamp:(double)sensorTimeStamp;
//- (void)processMag:(float)x y:(float)y z:(float)z sensorTimeStamp:(double)sensorTimeStamp;

@end
