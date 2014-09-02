//
//  HeadTracker.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "HeadTracker.h"

HeadTracker::HeadTracker()
{
    this->manager = nil;
    this->tracker = new OrientationEKF();
    this->ekfToHeadTracker = this->getRotateEulerMatrix(-90, 0, 0);
}

HeadTracker::~HeadTracker()
{
    delete this->tracker;
}

GLKMatrix4 HeadTracker::getRotateEulerMatrix(float x, float y, float z)
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

void HeadTracker::startTracking()
{
    if (this->manager != nil) {
        return;
    }
    this->tracker->reset();
    this->manager = [[CMMotionManager alloc] init];
    if (this->manager.isMagnetometerAvailable) {
        this->manager.magnetometerUpdateInterval = 1.0f / 100.0f;
        [this->manager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            GLKVector3 motionVector;
            motionVector.x = -accelerometerData.acceleration.y;
            motionVector.y = accelerometerData.acceleration.x;
            motionVector.z = accelerometerData.acceleration.z;
            this->tracker->processAcc(motionVector, accelerometerData.timestamp);
        }];
        [this->manager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData *gyroData, NSError *error) {
            GLKVector3 motionVector;
            motionVector.x = -gyroData.rotationRate.y;
            motionVector.y = gyroData.rotationRate.x;
            motionVector.z = gyroData.rotationRate.z;
            this->lastGyroEventTimeSeconds = gyroData.timestamp;
            this->tracker->processAcc(motionVector, gyroData.timestamp);
        }];
    }
}

void HeadTracker::stopTracking()
{
    if (this->manager == nil) {
        return;
    }
    [this->manager stopAccelerometerUpdates];
    [this->manager stopGyroUpdates];
    this->manager = nil;
}

GLKMatrix4 HeadTracker::getLastHeadView()
{
    double secondsSinceLastGyroEvent = [[NSDate date] timeIntervalSince1970] - this->lastGyroEventTimeSeconds;
    double secondsToPredictForward = secondsSinceLastGyroEvent + 0.03333333333333333;
    GLKMatrix4 tempHeadView = this->tracker->getPredictedGLMatrix(secondsToPredictForward);
    return GLKMatrix4Multiply(tempHeadView, this->ekfToHeadTracker);
}