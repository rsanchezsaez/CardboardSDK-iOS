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
#include "Vector3d.h"
#include "Matrix3x3d.h"


class OrientationEKF
{
public:
    OrientationEKF();
    virtual ~OrientationEKF();
    
    void reset();
    bool isReady();
    
    void processGyro(GLKVector3 gyro, double sensorTimeStamp);
    void processAcc(GLKVector3 acc, double sensorTimeStamp);
    
    double getHeadingDegrees();
    void setHeadingDegrees(double heading);
    
    GLKMatrix4 getGLMatrix();
    GLKMatrix4 getPredictedGLMatrix(double secondsAfterLastGyroEvent);

    
private:

    Matrix3x3d so3SensorFromWorld_;
    Matrix3x3d so3LastMotion_;
    Matrix3x3d mP_;
    Matrix3x3d mQ_;
    Matrix3x3d mR_;
    Matrix3x3d mRaccel_;
    Matrix3x3d mS_;
    Matrix3x3d mH_;
    Matrix3x3d mK_;
    Vector3d mNu_;
    Vector3d mz_;
    Vector3d mh_;
    Vector3d mu_;
    Vector3d mx_;
    Vector3d down_;
    Vector3d north_;
    double sensorTimeStampGyro_;
    GLKVector3 lastGyro_;
    double previousAccelNorm_;
    double movingAverageAccelNormChange_;
    double filteredGyroTimestep_;
    bool timestepFilterInit_;
    int numGyroTimestepSamples_;
    bool gyroFilterValid_;
    bool alignedToGravity_;
    bool alignedToNorth_;
    
    void filterGyroTimestep(double timestep);
    void updateCovariancesAfterMotion();
    void updateAccelCovariance(double currentAccelNorm);
    void accObservationFunctionForNumericalJacobian(Matrix3x3d* so3SensorFromWorldPred, Vector3d* result);
    
};

#endif
