//
//  HeadTracker.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-22.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "HeadTracker.h"
#import <CoreMotion/CoreMotion.h>
#import "OrientationEKF.h"

@interface HeadTracker ()

@property (nonatomic,strong) CMMotionManager *manager;
@property (nonatomic,strong) NSMutableArray *sensorData;
@property (nonatomic,assign) float lastGyroEventTimeSeconds;
@property (nonatomic,strong) OrientationEKF *tracker;
@property (nonatomic,assign) GLKMatrix4 ekfToHeadTracker;

@end

@implementation HeadTracker

- (id)init
{
    self = [super init];
    if (self)
    {
        self.ekfToHeadTracker = [self getRotateEulerMatrix:-90 y:0 z:0];;
    }
    return self;
}

- (GLKMatrix4)getRotateEulerMatrix:(float)x y:(float)y z:(float)z
{
    x *= (float)(M_PI / 180.0f);
    y *= (float)(M_PI / 180.0f);
    z *= (float)(M_PI / 180.0f);
    float cx = (float) cos(x);
    float sx = (float) sin(x);
    float cy = (float) cos(y);
    float sy = (float) sin(y);
    float cz = (float) cos(z);
    float sz = (float) sin(z);
    float cxsy = cx * sy;
    float sxsy = sx * sy;
    GLKMatrix4 matrix;
    matrix.m[0] = cy * cz;
    matrix.m[1] = -cy * sz;
    matrix.m[2] = sy;
    matrix.m[3] = 0.0f;
    matrix.m[4] = cxsy * cz + cx * sz;
    matrix.m[5] = -cxsy * sz + cx * cz;
    matrix.m[6] = -sx * cy;
    matrix.m[7] = 0.0f;
    matrix.m[8] = -sxsy * cz + sx * sz;
    matrix.m[9] = sxsy * sz + sx * cz;
    matrix.m[10] = cx * cy;
    matrix.m[11] = 0.0f;
    matrix.m[12] = 0.0f;
    matrix.m[13] = 0.0f;
    matrix.m[14] = 0.0f;
    matrix.m[15] = 1.0f;
    return matrix;
}

- (void)startTracking
{
    if (self.tracker == nil) {
        self.tracker = [[OrientationEKF alloc] init];
    }
    [self.tracker reset];
    if (self.sensorData == nil) {
        self.sensorData = [[NSMutableArray alloc] init];
    }
    if (self.manager == nil) {
        self.manager = [[CMMotionManager alloc] init];
    }
    if (self.manager.isMagnetometerAvailable) {
        self.manager.magnetometerUpdateInterval = 1.0f / 100.0f;
        [self.manager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            float x = -accelerometerData.acceleration.y;
            float y = accelerometerData.acceleration.x;
            float z = accelerometerData.acceleration.z;
            [self.tracker processAcc:x y:y z:z sensorTimeStamp:accelerometerData.timestamp];
        }];
        [self.manager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData *gyroData, NSError *error) {
            float x = -gyroData.rotationRate.y;
            float y = gyroData.rotationRate.x;
            float z = gyroData.rotationRate.z;
            [self setLastGyroEventTimeSeconds:gyroData.timestamp];
            [self.tracker processGyro:x y:y z:z sensorTimeStamp:gyroData.timestamp];
        }];
    }
}

-(void)stopTracking
{
    if (self.manager == nil) {
        return;
    }
    [self.manager stopAccelerometerUpdates];
    [self.manager stopGyroUpdates];
    self.manager = nil;
}

- (GLKMatrix4)getLastHeadView
{
    double secondsSinceLastGyroEvent = [[NSDate date] timeIntervalSince1970] - self.lastGyroEventTimeSeconds;
    double secondsToPredictForward = secondsSinceLastGyroEvent + 0.03333333333333333;
    GLKMatrix4 tempHeadView = [self.tracker getPredictedGLMatrix:secondsToPredictForward];
    return GLKMatrix4Multiply(tempHeadView, self.ekfToHeadTracker);
}

@end
