//
//  OrientationEKF.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "OrientationEKF.h"
#include "So3Util.h"
#include <cmath>

OrientationEKF::OrientationEKF()
{
    this->so3SensorFromWorld = new Matrix3x3d();
    this->so3LastMotion = new Matrix3x3d();
    this->currentMotion = new Matrix3x3d();
    this->down = new Vector3d();
    this->north = new Vector3d();
    this->gyroFilterValid = true;
    this->reset();
}

OrientationEKF::~OrientationEKF()
{
    delete this->so3SensorFromWorld;
    delete this->so3LastMotion;
    delete this->currentMotion;
    delete this->down;
    delete this->north;
}

void OrientationEKF::reset()
{
    this->sensorTimeStampGyro = 0.0;
    this->sensorTimeStampAcc = 0.0;
    this->so3SensorFromWorld->setIdentity();
    this->so3LastMotion->setIdentity();
    this->currentMotion->setSameDiagonal(25.0);
    this->down->set(0.0, 0.01, 9.810000000000001);
    this->north->set(0.0, 1.0, 0.0);
}

bool OrientationEKF::isReady()
{
    return this->sensorTimeStampAcc != 0;
}

double OrientationEKF::getHeadingDegrees()
{
    double x = this->so3SensorFromWorld->get(2, 0);
    double y = this->so3SensorFromWorld->get(2, 1);
    double mag = sqrt(x * x + y * y);
    if (mag < 0.1) {
        return 0.0;
    }
    double heading = -90.0 - atan2(y, x) / M_PI * 180.0;
    if (heading < 0.0) {
        heading += 360.0;
    }
    if (heading >= 360.0) {
        heading -= 360.0;
    }
    return heading;
}

void OrientationEKF::setHeadingDegrees(double heading)
{
    double currentHeading = this->getHeadingDegrees();
    double deltaHeading = heading - currentHeading;
    double s = sin(deltaHeading / 180.0 * M_PI);
    double c = cos(deltaHeading / 180.0 * M_PI);
    Matrix3x3d *deltaHeadingRotationMatrix = new Matrix3x3d(c, -s, 0.0, s, c, 0.0, 0.0, 0.0, 1.0);
    Matrix3x3d::mult(so3SensorFromWorld, deltaHeadingRotationMatrix, this->so3SensorFromWorld);
    delete deltaHeadingRotationMatrix;
}

GLKMatrix4 OrientationEKF::getGLMatrix()
{
    return this->glMatrixFromSo3(so3SensorFromWorld);
}

GLKMatrix4 OrientationEKF::getPredictedGLMatrix(double secondsAfterLastGyroEvent)
{
    double dT = secondsAfterLastGyroEvent;
    Vector3d *pmu = new Vector3d(this->lastGyro.x * -dT, this->lastGyro.y * -dT, this->lastGyro.z * -dT);
    Matrix3x3d *so3PredictedMotion = new Matrix3x3d();
    So3Util::sO3FromMu(pmu, so3PredictedMotion);
    delete pmu;
    Matrix3x3d *so3PredictedState = new Matrix3x3d();
    Matrix3x3d::mult(so3PredictedMotion, this->so3SensorFromWorld, so3PredictedState);
    delete so3PredictedMotion;
    GLKMatrix4 result = this->glMatrixFromSo3(so3PredictedState);
    delete so3PredictedState;
    return result;
}

GLKMatrix4 OrientationEKF::glMatrixFromSo3(Matrix3x3d *so3)
{
    GLKMatrix4 rotationMatrix;
    for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
            rotationMatrix.m[(4 * c + r)] = so3->get(r, c);
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

void OrientationEKF::processGyro(GLKVector3 gyro, double sensorTimeStamp)
{
    if (this->sensorTimeStampGyro != 0.0) {
        
        float dT = (float)(sensorTimeStamp - this->sensorTimeStampGyro);
        if (dT > 0.04f) {
            dT = this->gyroFilterValid ? this->filteredGyroTimestep : 0.01f;
        } else {
            if (!this->timestepFilterInit) {
                this->filteredGyroTimestep = dT;
                this->numGyroTimestepSamples = 1;
                this->timestepFilterInit = true;
            } else {
                this->filteredGyroTimestep = (0.95f * this->filteredGyroTimestep + 0.05000001f * dT);
                if (++this->numGyroTimestepSamples > 10.0f) {
                    this->gyroFilterValid = true;
                }
            }
        }
        
        Vector3d *motionVector = new Vector3d(gyro.x * -dT, gyro.y * -dT, gyro.z * -dT);
        
        Matrix3x3d *processGyroM1 = new Matrix3x3d();
        Matrix3x3d *processGyroM2 = new Matrix3x3d();
        Matrix3x3d *processGyroM3 = new Matrix3x3d();
        Matrix3x3d *processGyroM4 = new Matrix3x3d();
        
        So3Util::sO3FromMu(motionVector, this->so3LastMotion);
        processGyroM1->set(this->so3SensorFromWorld);
        Matrix3x3d::mult(this->so3LastMotion, this->so3SensorFromWorld, processGyroM1);
        this->so3SensorFromWorld->set(processGyroM1);
        this->so3LastMotion->transpose(processGyroM2);
        Matrix3x3d::mult(this->currentMotion, processGyroM2, processGyroM3);
        Matrix3x3d::mult(this->so3LastMotion, processGyroM3, this->currentMotion);
        this->so3LastMotion->setIdentity();
        processGyroM4->setSameDiagonal(1.0);
        processGyroM4->scale(dT * dT);
        this->currentMotion->plusEquals(processGyroM4);
        
        delete motionVector;
        
        delete processGyroM1;
        delete processGyroM2;
        delete processGyroM3;
        delete processGyroM4;
        
    }
    this->sensorTimeStampGyro = sensorTimeStamp;
    this->lastGyro = gyro;
}

void OrientationEKF::processAcc(GLKVector3 acc, double sensorTimeStamp)
{
    Vector3d *motionVector = new Vector3d(acc.x, acc.y, acc.z);
    
    if (this->sensorTimeStampAcc != 0.0)
    {
        Vector3d *outerVector1 = new Vector3d();
        Vector3d *outerVector2 = new Vector3d();
        Vector3d *outerVector3 = new Vector3d();
        
        Matrix3x3d *outerMatrix1 = new Matrix3x3d();
        Matrix3x3d *outerMatrix2 = new Matrix3x3d();
        Matrix3x3d *outerMatrix3 = new Matrix3x3d();
        Matrix3x3d *outerMatrix4 = new Matrix3x3d();
        Matrix3x3d *outerMatrix5 = new Matrix3x3d();
        Matrix3x3d *outerMatrix6 = new Matrix3x3d();
        Matrix3x3d *outerMatrix7 = new Matrix3x3d();
        Matrix3x3d *outerMatrix8 = new Matrix3x3d();
        Matrix3x3d *outerMatrix9 = new Matrix3x3d();
        Matrix3x3d *outerMatrix10 = new Matrix3x3d();
        Matrix3x3d *outerMatrix11 = new Matrix3x3d();
        
        Matrix3x3d::mult(this->so3SensorFromWorld, this->down, outerVector1);
        So3Util::sO3FromTwoVec(outerVector1, motionVector, outerMatrix1);
        So3Util::muFromSO3(outerMatrix1, outerVector2);
        
        for (int dof = 0; dof < 3; dof++)
        {
            Vector3d *innerVector1 = new Vector3d();
            Vector3d *innerVector2 = new Vector3d();
            Vector3d *innerVector3 = new Vector3d();
            
            Matrix3x3d *innerMatrix1 = new Matrix3x3d();
            Matrix3x3d *innerMatrix2 = new Matrix3x3d();
            Matrix3x3d *innerMatrix3 = new Matrix3x3d();
            
            innerVector1->setComponent(dof, 1.0E-07);
            So3Util::sO3FromMu(innerVector1, innerMatrix1);
            Matrix3x3d::mult(innerMatrix1, this->so3SensorFromWorld, innerMatrix2);
            Matrix3x3d::mult(innerMatrix2, this->down, outerVector3);
            So3Util::sO3FromTwoVec(outerVector1, motionVector, innerMatrix3);
            So3Util::muFromSO3(innerMatrix3, innerVector2);
            Vector3d::sub(outerVector2, innerVector2, innerVector3);
            innerVector3->scale(1.0 / 1.0E-07);
            outerMatrix2->setColumn(dof, innerVector3);
            
            delete innerVector1;
            delete innerVector2;
            delete innerVector3;
            
            delete innerMatrix1;
            delete innerMatrix2;
            delete innerMatrix3;
        }

        outerMatrix2->transpose(outerMatrix4);
        Matrix3x3d::mult(this->currentMotion, outerMatrix3, outerMatrix4);
        Matrix3x3d::mult(this->currentMotion, outerMatrix4, outerMatrix5);
        outerMatrix7->setSameDiagonal(0.5625);
        Matrix3x3d::mult(outerMatrix5, outerMatrix7, outerMatrix6);
        outerMatrix6->invert(outerMatrix3);
        outerMatrix2->transpose(outerMatrix4);
        Matrix3x3d::mult(outerMatrix3, outerMatrix4, outerMatrix5);
        Matrix3x3d::mult(this->currentMotion, outerMatrix5, outerMatrix8);
        Matrix3x3d::mult(outerMatrix8, outerVector2, outerVector3);
        Matrix3x3d::mult(outerMatrix8, outerMatrix2, outerMatrix3);
        outerMatrix4->setIdentity();
        outerMatrix4->minusEquals(outerMatrix3);
        Matrix3x3d::mult(outerMatrix4, this->currentMotion, outerMatrix3);
        this->currentMotion->set(outerMatrix3);
        So3Util::sO3FromMu(outerVector3, this->so3LastMotion);
        outerMatrix9->set(this->so3SensorFromWorld);
        Matrix3x3d::mult(this->so3LastMotion, this->so3SensorFromWorld, outerMatrix9);
        this->so3SensorFromWorld->set(outerMatrix9);
        this->so3LastMotion->transpose(outerMatrix10);
        Matrix3x3d::mult(this->currentMotion, outerMatrix10, outerMatrix11);
        Matrix3x3d::mult(this->so3LastMotion, outerMatrix11, this->currentMotion);
        this->so3LastMotion->setIdentity();
        
        delete outerVector1;
        delete outerVector2;
        delete outerVector3;
        
        delete outerMatrix1;
        delete outerMatrix2;
        delete outerMatrix3;
        delete outerMatrix4;
        delete outerMatrix5;
        delete outerMatrix6;
        delete outerMatrix7;
        delete outerMatrix8;
        delete outerMatrix9;
        delete outerMatrix10;
        delete outerMatrix11;
    }
    else
    {
        So3Util::sO3FromTwoVec(this->down, motionVector, this->so3SensorFromWorld);
    }
    
    delete motionVector;
    this->sensorTimeStampAcc = sensorTimeStamp;
}