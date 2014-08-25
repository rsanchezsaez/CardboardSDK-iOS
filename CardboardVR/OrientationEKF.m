//
//  OrientationEKF.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-22.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "OrientationEKF.h"

@interface OrientationEKF ()

@property (nonatomic, assign) double sensorTimeStampGyro;
@property (nonatomic, assign) double sensorTimeStampAcc;
@property (nonatomic, assign) double sensorTimeStampMag;

@property (nonatomic, strong) Matrix3x3d *so3SensorFromWorld;
@property (nonatomic, strong) Matrix3x3d *so3LastMotion;
@property (nonatomic, strong) Matrix3x3d *currentMotion;

@property (nonatomic, strong) Vector3d *down;
@property (nonatomic, strong) Vector3d *north;

@property (nonatomic, assign) float lastGyroX;
@property (nonatomic, assign) float lastGyroY;
@property (nonatomic, assign) float lastGyroZ;

@property (nonatomic, assign) float filteredGyroTimestep;

@property (nonatomic, assign) bool gyroFilterValid;
@property (nonatomic, assign) bool timestepFilterInit;

@property (nonatomic, assign) int numGyroTimestepSamples;

@end

@implementation OrientationEKF

- (id)init
{
    self = [super init];
    if (self)
    {
        self.so3SensorFromWorld = [[Matrix3x3d alloc] init];
        self.so3LastMotion = [[Matrix3x3d alloc] init];
        self.currentMotion = [[Matrix3x3d alloc] init];

        self.down = [[Vector3d alloc] init];
        self.north = [[Vector3d alloc] init];

        self.gyroFilterValid = true;

        [self reset];
    }
    return self;
}

- (void)reset
{
    self.sensorTimeStampGyro = 0.0;
    self.sensorTimeStampAcc = 0.0;
    self.sensorTimeStampMag = 0.0;
    
    [self.so3SensorFromWorld setIdentity];
    [self.so3LastMotion setIdentity];
    
    [self.currentMotion setSameDiagonal:25.0];

    [self.down set:0.0 y:0.0 z:9.810000000000001];
    [self.north set:0.0 y:1.0 z:0.0];
}

- (bool)isReady
{
    return self.sensorTimeStampAcc != 0;
}

- (double)getHeadingDegrees
{
    double x = [self.so3SensorFromWorld get:2 col:0];
    double y = [self.so3SensorFromWorld get:2 col:1];
    double mag = sqrt(x * x + y * y);
    if (mag < 0.1)
    {
        return 0.0;
    }
    double heading = -90.0 - atan2(y, x) / M_PI * 180.0;
    if (heading < 0.0)
    {
        heading += 360.0;
    }
    if (heading >= 360.0)
    {
        heading -= 360.0;
    }
    return heading;
}

- (void)setHeadingDegrees:(double)heading
{
    double currentHeading = [self getHeadingDegrees];
    double deltaHeading = heading - currentHeading;
    double s = sin(deltaHeading / 180.0 * M_PI);
    double c = cos(deltaHeading / 180.0 * M_PI);
    Matrix3x3d *deltaHeadingRotationMatrix = [[Matrix3x3d alloc] initWithM00:c m01:-s m02:0.0 m10:s m11:c m12:0.0 m20:0.0 m21:0.0 m22:0.1];
    [Matrix3x3d mult:self.so3SensorFromWorld b:deltaHeadingRotationMatrix result:self.so3SensorFromWorld];
}

- (GLKMatrix4)getGLMatrix
{
    return [self glMatrixFromSo3:self.so3SensorFromWorld];
}

- (GLKMatrix4)getPredictedGLMatrix:(double)secondsAfterLastGyroEvent
{
    double dT = secondsAfterLastGyroEvent;
    Vector3d *pmu = [[Vector3d alloc] initWithX:self.lastGyroX * -dT y:self.lastGyroY * -dT z:self.lastGyroZ * -dT];
    Matrix3x3d *so3PredictedMotion = [[Matrix3x3d alloc] init];
    [So3Util sO3FromMu:pmu result:so3PredictedMotion];
    Matrix3x3d *so3PredictedState = [[Matrix3x3d alloc] init];
    [Matrix3x3d mult:so3PredictedMotion b:self.so3SensorFromWorld result:so3PredictedState];
    return [self glMatrixFromSo3:so3PredictedState];
}

- (GLKMatrix4)glMatrixFromSo3:(Matrix3x3d*)so3
{
    GLKMatrix4 rotationMatrix;
    for (int r = 0; r < 3; r++)
    {
        for (int c = 0; c < 3; c++)
        {
            rotationMatrix.m[(4 * c + r)] = [so3 get:r col:c];
        }
    }
    rotationMatrix.m[3] = 0.0;
    rotationMatrix.m[7] = 0.0;
    rotationMatrix.m[11] = 0.0;
    rotationMatrix.m[12] = 0.0;
    rotationMatrix.m[13] = 0.0;
    rotationMatrix.m[14] = 0.0;
    rotationMatrix.m[15] = 1.0;
    return rotationMatrix;
}

- (void)processGyro:(float)x y:(float)y z:(float)z sensorTimeStamp:(double)sensorTimeStamp
{
    if (self.sensorTimeStampGyro != 0.0) {
        float dT = (float)(sensorTimeStamp - self.sensorTimeStampGyro);
        if (dT > 0.04f)
            dT = self.gyroFilterValid ? self.filteredGyroTimestep : 0.01f;
        else {
            if (!self.timestepFilterInit) {
                self.filteredGyroTimestep = dT;
                self.numGyroTimestepSamples = 1;
                self.timestepFilterInit = true;
            }
            else {
                self.filteredGyroTimestep = (0.95f * self.filteredGyroTimestep + 0.05000001f * dT);
                if (++self.numGyroTimestepSamples > 10.0f)
                {
                    self.gyroFilterValid = true;
                }
            }
        }
        Vector3d *processGyroV1 = [[Vector3d alloc] initWithX:x * -dT y:y * -dT z:z * - dT];
        [So3Util sO3FromMu:processGyroV1 result:self.so3LastMotion];
        [Matrix3x3d mult:self.so3LastMotion b:self.so3SensorFromWorld result:self.so3SensorFromWorld];
        
        Matrix3x3d *processGyroM1 = [[Matrix3x3d alloc] init];
        [self.so3LastMotion transpose:processGyroM1];
        Matrix3x3d *processGyroM2 = [[Matrix3x3d alloc] init];
        [Matrix3x3d mult:self.currentMotion b:processGyroM1 result:processGyroM2];
        [Matrix3x3d mult:self.so3LastMotion b:processGyroM2 result:self.currentMotion];
        [self.so3LastMotion setIdentity];
        
        Matrix3x3d *processGyroM3 = [[Matrix3x3d alloc] init];
        [processGyroM3 setSameDiagonal:1.0];
        [processGyroM3 scale:dT * dT];
        [self.currentMotion plusEquals:processGyroM3];
    }
    self.sensorTimeStampGyro = sensorTimeStamp;
    self.lastGyroX = x;
    self.lastGyroY = y;
    self.lastGyroZ = z;
}

- (void)processAcc:(float)x y:(float)y z:(float)z sensorTimeStamp:(double)sensorTimeStamp
{
    Vector3d *processAccV1 = [[Vector3d alloc] initWithX:x y:y z:z];
    
    Matrix3x3d *processAccM5 = [[Matrix3x3d alloc] init];

    if (self.sensorTimeStampAcc != 0.0)
    {
        Vector3d *processAccV3 = [[Vector3d alloc] init];
        [Matrix3x3d mult:self.so3SensorFromWorld v:self.down result:processAccV3];
        Matrix3x3d *processAccM1 = [[Matrix3x3d alloc] init];
        [So3Util sO3FromTwoVec:processAccV3 b:processAccV1 result:processAccM1];
        Vector3d *processAccV2 = [[Vector3d alloc] init];
        [So3Util muFromSO3:processAccM1 result:processAccV2];
        
        double eps = 1.0E-07;
        for (int dof = 0; dof < 3; dof++)
        {
            Vector3d *processAccV4 = [[Vector3d alloc] init];
            [processAccV4 setComponent:dof val:eps];
            
            Matrix3x3d *processAccM2 = [[Matrix3x3d alloc] init];
            [So3Util sO3FromMu:processAccV4 result:processAccM2];
            Matrix3x3d *processAccM3 = [[Matrix3x3d alloc] init];
            [Matrix3x3d mult:processAccM2 b:self.so3SensorFromWorld result:processAccM3];
            
            [Matrix3x3d mult:processAccM3 v:self.down result:processAccV3];
            Matrix3x3d *processAccM4 = [[Matrix3x3d alloc] init];
            [So3Util sO3FromTwoVec:processAccV3 b:processAccV1 result:processAccM4];
            Vector3d *processAccV5 = [[Vector3d alloc] init];
            [So3Util muFromSO3:processAccM4 result:processAccV5];
            
            Vector3d *processAccV6 = [[Vector3d alloc] init];
            [Vector3d sub:processAccV2 b:processAccV5 result:processAccV6];
            [processAccV6 scale:1.0 / eps];
            
            [processAccM5 setColumn:dof v:processAccV6];
        }

        Matrix3x3d *processAccM6 = [[Matrix3x3d alloc] init];
        [processAccM5 transpose:processAccM6];
        Matrix3x3d *processAccM7 = [[Matrix3x3d alloc] init];
        [Matrix3x3d mult:self.currentMotion b:processAccM6 result:processAccM7];
        Matrix3x3d *processAccM8 = [[Matrix3x3d alloc] init];
        [Matrix3x3d mult:self.currentMotion b:processAccM7 result:processAccM8];
        
        Matrix3x3d *processAccM10 = [[Matrix3x3d alloc] init];
        [processAccM10 setSameDiagonal:0.5625];
        Matrix3x3d *processAccM9 = [[Matrix3x3d alloc] init];
        [Matrix3x3d add:processAccM8 b:processAccM10 result:processAccM9];
        
        [processAccM9 invert:processAccM6];
        [processAccM5 transpose:processAccM7];
        [Matrix3x3d mult:processAccM6 b:processAccM7 result:processAccM8];
        Matrix3x3d *processAccM11 = [[Matrix3x3d alloc] init];
        [Matrix3x3d mult:self.currentMotion b:processAccM8 result:processAccM11];
        
        Vector3d *processAccV7 = [[Vector3d alloc] init];
        [Matrix3x3d mult:processAccM11 v:processAccV2 result:processAccV7];
    
        [Matrix3x3d mult:processAccM11 b:processAccM5 result:processAccM6];
        [processAccM7 setIdentity];
        [processAccM7 minusEquals:processAccM6];
        [Matrix3x3d mult:processAccM7 b:self.currentMotion result:processAccM6];
        [self.currentMotion set:processAccM6];
        
        [So3Util sO3FromMu:processAccV7 result:self.so3LastMotion];
        
        [Matrix3x3d mult:self.so3LastMotion b:self.so3SensorFromWorld result:self.so3SensorFromWorld];
        
        Matrix3x3d *processAccM12 = [[Matrix3x3d alloc] init];
        [self.so3LastMotion transpose:processAccM12];
        Matrix3x3d *processAccM13 = [[Matrix3x3d alloc] init];
        [Matrix3x3d mult:self.currentMotion b:processAccM12 result:processAccM13];
        [Matrix3x3d mult:self.so3LastMotion b:processAccM13 result:self.currentMotion];
        [self.so3LastMotion setIdentity];
    }
    else
    {
        [So3Util sO3FromTwoVec:self.down b:processAccV1 result:self.so3SensorFromWorld];
    }
    self.sensorTimeStampAcc = sensorTimeStamp;
}

//- (void)processMag:(float)x y:(float)y z:(float)z  sensorTimeStamp:(double)sensorTimeStamp
//{
//    Vector3d *processMagV1 = [[Vector3d alloc] init];
//    [processMagV1 set:x yy:y zz:z];
//    [processMagV1 normalize];
//    
//    Vector3d *processMagV2 = [[Vector3d alloc] init];
//    [self.so3SensorFromWorld getColumn:2 v:processMagV2];
//    
//    Vector3d *processMagV3 = [[Vector3d alloc] init];
//    [Vector3d cross:processMagV1 b:processMagV2 result:processMagV3];
//    Vector3d *processMagV4 = [[Vector3d alloc] init];
//    [processMagV4 set:processMagV3];
//    [processMagV4 normalize];
//    
//    Vector3d *processMagV5 = [[Vector3d alloc] init];
//    [Vector3d cross:processMagV2 b:processMagV4 result:processMagV5];
//    Vector3d *magHorizontal = [[Vector3d alloc] init];
//    [magHorizontal set:processMagV5];
//    [magHorizontal normalize];
//    [processMagV1 set:magHorizontal];
//    
//    Matrix3x3d *processMagM5 = [[Matrix3x3d alloc] init];
//    
//    if (self.sensorTimeStampMag != 0.0) {
//        
//        Vector3d *processMagV6 = [[Vector3d alloc] init];
//        [Matrix3x3d mult:self.so3SensorFromWorld v:self.north result:processMagV6];
//        Matrix3x3d *processMagM1 = [[Matrix3x3d alloc] init];
//        [So3Util sO3FromTwoVec:processMagV6 b:processMagV1 result:processMagM1];
//        Vector3d *processMagV7 = [[Vector3d alloc] init];
//        [So3Util muFromSO3:processMagM1 result:processMagV7];
//        
//        double eps = 1.0E-07;
//        for (int dof = 0; dof < 3; dof++) {
//            Vector3d *processMagV7 = [[Vector3d alloc] init];
//            [processMagV7 setComponent:dof val:eps];
//            
//            Matrix3x3d *processMagM2 = [[Matrix3x3d alloc] init];
//            [So3Util sO3FromMu:processMagV7 result:processMagM2];
//            Matrix3x3d *processMagM3 = [[Matrix3x3d alloc] init];
//            [Matrix3x3d mult:processMagM2 b:self.so3SensorFromWorld result:processMagM3];
//            
//            Vector3d *tempVector1 = [[Vector3d alloc] init];
//            [Matrix3x3d mult:processMagM3 v:self.north result:processMagV6];
//            Matrix3x3d *processMagM4 = [[Matrix3x3d alloc] init];
//            [So3Util sO3FromTwoVec:processMagV6 b:processMagV1 result:processMagM4];
//            [So3Util muFromSO3:processMagM4 result:tempVector1];
//            
//            Vector3d *tempVector2 = [[Vector3d alloc] init];
//            [Vector3d sub:processMagV7 b:tempVector1 result:tempVector2];
//            [tempVector2 scale:1.0 / eps];
//            
//            [processMagM5 setColumn:dof v:tempVector2];
//        }
//        
//        Matrix3x3d *processMagM6 = [[Matrix3x3d alloc] init];
//        [processMagM5 transpose:processMagM6];
//        
//        Matrix3x3d *processMagM7 = [[Matrix3x3d alloc] init];
//        [Matrix3x3d mult:self.currentMotion b:processMagM6 result:processMagM7];
//        Matrix3x3d *processMagM8 = [[Matrix3x3d alloc] init];
//        [Matrix3x3d mult:processMagM5 b:processMagM7 result:processMagM8];
//        
//        Matrix3x3d *processMagM9 = [[Matrix3x3d alloc] init];
//        [processMagM9 setSameDiagonal:0.0625];
//        Matrix3x3d *processMagM10 = [[Matrix3x3d alloc] init];
//        [Matrix3x3d add:processMagM8 b:processMagM9 result:processMagM10];
//        
//        [processMagM10 invert:processMagM6];
//        [processMagM5 transpose: processMagM7];
//        [Matrix3x3d mult:processMagM7 b:processMagM6 result:processMagM8];
//        Matrix3x3d *processMagM11 = [[Matrix3x3d alloc] init];
//        [Matrix3x3d mult:self.currentMotion b:processMagM8 result:processMagM11];
//        
//        Vector3d *processMagV8 = [[Vector3d alloc] init];
//        [Matrix3x3d mult:processMagM11 v:processMagV7 result:processMagV8];
//        [Matrix3x3d mult:processMagM11 b:processMagM5 result:processMagM6];
//        
//        [processMagM7 setIdentity];
//        [processMagM7 minusEquals:processMagM6];
//        [Matrix3x3d mult:processMagM7 b:self.currentMotion result:processMagM6];
//        [self.currentMotion set:processMagM6];
//        
//        [So3Util sO3FromMu:processMagV8 result:self.so3LastMotion];
//        
//        [Matrix3x3d mult:self.so3LastMotion b:self.so3SensorFromWorld result:processMagM6];
//        [self.so3SensorFromWorld set:processMagM6];
//        
//        Matrix3x3d *processMagM12 = [[Matrix3x3d alloc] init];
//        [self.so3LastMotion transpose:processMagM12];
//        Matrix3x3d *processMagM13 = [[Matrix3x3d alloc] init];
//        [Matrix3x3d mult:self.currentMotion b:processMagM12 result:processMagM13];
//        [Matrix3x3d mult:self.so3LastMotion b:processMagM13 result:self.currentMotion];
//        [self.so3LastMotion setIdentity];
//    }
//    else
//    {
//        //Vector3d *processMagV7 = [[Vector3d alloc] init];
//        //[Matrix3x3d mult:self.so3SensorFromWorld v:self.north result:processMagV7];
//        //Matrix3x3d *processMagM13 = [[Matrix3x3d alloc] init];
//        //[So3Util sO3FromTwoVec:processMagV7 b:processMagV1 result:processMagM13];
//        //[So3Util muFromSO3:processMagM13 result:processMagV8]; //this not used
//        
//        Vector3d *processMagV9 = [[Vector3d alloc] init];
//        [So3Util sO3FromMu:processMagV9 result:self.so3LastMotion]; // can this be simplified
//        
//        Matrix3x3d *processMagM14 = [[Matrix3x3d alloc] init];
//        [Matrix3x3d mult:self.so3LastMotion b:self.so3SensorFromWorld result:processMagM14];
//        [self.so3SensorFromWorld set:processMagM14];
//        
//        Matrix3x3d *processMagM15 = [[Matrix3x3d alloc] init];
//        [self.so3LastMotion transpose:processMagM15];
//        Matrix3x3d *processMagM16 = [[Matrix3x3d alloc] init];
//        [Matrix3x3d mult:self.currentMotion b:processMagM15 result:processMagM16];
//        [Matrix3x3d mult:self.so3LastMotion b:processMagM16 result:self.currentMotion];
//        [self.so3LastMotion setIdentity];
//    }
//    self.sensorTimeStampMag = sensorTimeStamp;
//}

@end
