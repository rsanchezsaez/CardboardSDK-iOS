//
//  So3Util.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-23.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "So3Util.h"

@implementation So3Util

const double HALF_ROOT_TWO = 0.7071067811865476;

+ (void)sO3FromTwoVec:(Vector3d*)a b:(Vector3d*)b result:(Matrix3x3d*)result
{
    Vector3d *sO3FromTwoVecN = [[Vector3d alloc] init];
    [Vector3d cross:a b:b result:sO3FromTwoVecN];
    if ([sO3FromTwoVecN length] == 0.0)
    {
        double dot = [Vector3d dot:a b:b];
        if (dot >= 0.0) {
            [result setIdentity];
        } else {
            Vector3d *sO3FromTwoVecRotationAxis = [[Vector3d alloc] init];
            [Vector3d ortho:a result:sO3FromTwoVecRotationAxis];
            [self rotationPiAboutAxis:sO3FromTwoVecRotationAxis result:result];
        }
        return;
    }
    
    Vector3d *sO3FromTwoVecA = [[Vector3d alloc] init];
    [sO3FromTwoVecA set:a];
    Vector3d *sO3FromTwoVecB = [[Vector3d alloc] init];
    [sO3FromTwoVecB set:b];
    
    [sO3FromTwoVecN normalize];
    [sO3FromTwoVecA normalize];
    [sO3FromTwoVecB normalize];
   
    Vector3d *tempVector = [[Vector3d alloc] init];
    Matrix3x3d *r1 = [[Matrix3x3d alloc] init];
    [r1 setColumn:0 v:sO3FromTwoVecA];
    [r1 setColumn:1 v:sO3FromTwoVecN];
    [Vector3d cross:sO3FromTwoVecN b:sO3FromTwoVecA result:tempVector];
    [r1 setColumn:2 v:tempVector];
    Matrix3x3d *r2 = [[Matrix3x3d alloc] init];
    [r2 setColumn:0 v:sO3FromTwoVecB];
    [r2 setColumn:1 v:sO3FromTwoVecN];
    [Vector3d cross:sO3FromTwoVecN b:sO3FromTwoVecB result:tempVector];
    [r2 setColumn:2 v:tempVector];
    [r1 transpose];
    [Matrix3x3d mult:r2 b:r1 result:result];
}

+ (void)rotationPiAboutAxis:(Vector3d*)v result:(Matrix3x3d*)result
{
    Vector3d *rotationPiAboutAxisTemp = [[Vector3d alloc] init];
    [rotationPiAboutAxisTemp set:v];
    [rotationPiAboutAxisTemp scale:M_PI / [rotationPiAboutAxisTemp length]];
    double kA = 0.0;
    double kB = 0.2026423672846756;
    [self rodriguesSo3Exp:rotationPiAboutAxisTemp kA:kA kB:kB result:result];
}

+ (void)sO3FromMu:(Vector3d*)w result:(Matrix3x3d*)result
{
    double thetaSq = [Vector3d dot:w b:w];
    double theta = sqrt(thetaSq);
    double kA, kB;
    if (thetaSq < 1.0E-08) {
        kA = 1.0 - 0.16666667163372 * thetaSq;
        kB = 0.5;
    }
    else
    {
        if (thetaSq < 1.0E-06) {
            kB = 0.5 - 0.0416666679084301 * thetaSq;
            kA = 1.0 - thetaSq * 0.16666667163372 * (1.0 - 0.16666667163372 * thetaSq);
        } else {
            double invTheta = 1.0 / theta;
            kA = sin(theta) * invTheta;
            kB = (1.0 - cos(theta)) * (invTheta * invTheta);
        }
    }
    [self rodriguesSo3Exp:w kA:kA kB:kB result:result];
}

+ (void)muFromSO3:(Matrix3x3d*)so3 result:(Vector3d*)result
{
    double cosAngle = ([so3 get:0 col:0] + [so3 get:1 col:1] + [so3 get:2 col:2] - 1.0) * 0.5;
    [result set:([so3 get:2 col:1] - [so3 get:1 col:2]) / 2.0 y:([so3 get:0 col:2] - [so3 get:2 col:0]) / 2.0 z:([so3 get:1 col:0] - [so3 get:0 col:1]) / 2.0];

    double sinAngleAbs = [result length];
    if (cosAngle > HALF_ROOT_TWO)
    {
        if (sinAngleAbs > 0.0) {
            [result scale:asin(sinAngleAbs) / sinAngleAbs];
        }
    }
    else if (cosAngle > -HALF_ROOT_TWO)
    {
        double angle = acos(cosAngle);
        [result scale:asin(angle) / sinAngleAbs];
    }
    else
    {
        double angle = M_PI - asin(sinAngleAbs);
        double d0 = [so3 get:0 col:0] - cosAngle;
        double d1 = [so3 get:1 col:1] - cosAngle;
        double d2 = [so3 get:2 col:2] - cosAngle;
        
        Vector3d *r2 = [[Vector3d alloc] init];
        if ((d0 * d0 > d1 * d1) && (d0 * d0 > d2 * d2))
        {
            [r2 set:d0 y:([so3 get:1 col:0] + [so3 get:0 col:1]) / 2.0 z:([so3 get:0 col:2] + [so3 get:2 col:0]) / 2.0];
        }
        else if (d1 * d1 > d2 * d2)
        {
            [r2 set:([so3 get:1 col:0] + [so3 get:0 col:1]) / 2.0 y:d1 z:([so3 get:2 col:1] + [so3 get:1 col:2]) / 2.0];
        }
        else
        {
            [r2 set:([so3 get:0 col:2] + [so3 get:2 col:0]) / 2.0 y:([so3 get:2 col:1] + [so3 get:1 col:2]) / 2.0 z:d2];
        }
        
        if ([Vector3d dot:r2 b:result] < 0.0) {
            [r2 scale:-1.0];
        }
        [r2 normalize];
        [r2 scale:angle];
        [result set:r2];
    }
}

+ (void)rodriguesSo3Exp:(Vector3d*)w kA:(double)kA kB:(double)kB result:(Matrix3x3d*)result
{
    double wx2 = w.x * w.x;
    double wy2 = w.y * w.y;
    double wz2 = w.z * w.z;
    [result set:0 col:0 value:1.0 - kB * (wy2 + wz2)];
    [result set:1 col:1 value:1.0 - kB * (wx2 + wz2)];
    [result set:2 col:2 value:1.0 - kB * (wx2 + wy2)];

    double a = kA * w.z;
    double b = kB * (w.x * w.y);
    [result set:0 col:1 value:b - a];
    [result set:1 col:0 value:b + a];
    
    a = kA * w.y;
    b = kB * (w.x * w.z);
    [result set:0 col:2 value:b + a];
    [result set:2 col:0 value:b - a];
    
    a = kA * w.x;
    b = kB * (w.y * w.z);
    [result set:1 col:2 value:b - a];
    [result set:2 col:1 value:b + a];
}

+ (void)generatorField:(int)i pos:(Matrix3x3d*)pos result:(Matrix3x3d*)result
{
    [result set:i col:0 value:0.0];
    [pos get:(i + 2) % 3 col:0];
    [result set:(i + 1) % 3 col:0 value:-[pos get:(i + 2) % 3 col:0]];
    [result set:(i + 2) % 3 col:0 value:[pos get:(i + 1) % 3 col:0]];
}

@end
