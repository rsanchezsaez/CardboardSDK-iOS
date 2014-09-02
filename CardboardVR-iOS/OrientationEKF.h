//
//  OrientationEKF.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

//#import <Foundation/Foundation.h>
//#import <CoreMotion/CoreMotion.h>


#ifndef __CardboardVR_iOS__OrientationEKF__
#define __CardboardVR_iOS__OrientationEKF__

#import <GLKit/GLKit.h>
#include "Matrix3x3d.h"
#include "Vector3d.h"
#include "Structs.h"

class OrientationEKF
{
private:
    double sensorTimeStampGyro;
    double sensorTimeStampAcc;
    Matrix3x3d *so3SensorFromWorld;
    Matrix3x3d *so3LastMotion;
    Matrix3x3d *currentMotion;
    Vector3d *down;
    Vector3d *north;
    GLKVector3 lastGyro;
    float filteredGyroTimestep;
    bool gyroFilterValid;
    bool timestepFilterInit;
    int numGyroTimestepSamples;
private:
    GLKMatrix4 glMatrixFromSo3(Matrix3x3d *so3);
public:
    OrientationEKF();
    ~OrientationEKF();
    void reset();
    bool isReady();
    double getHeadingDegrees();
    void setHeadingDegrees(double heading);
    GLKMatrix4 getGLMatrix();
    GLKMatrix4 getPredictedGLMatrix(double secondsAfterLastGyroEvent);
    void processGyro(GLKVector3 gyro, double sensorTimeStamp);
    void processAcc(GLKVector3 acc, double sensorTimeStamp);
};

#endif
