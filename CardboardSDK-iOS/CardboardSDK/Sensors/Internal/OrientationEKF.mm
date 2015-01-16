//
//  OrientationEKF.mm
//  CardboardVR-iOS
//

#include "OrientationEKF.h"
#include "So3Util.h"
#include <cmath>
#include <algorithm>

static const double DEG_TO_RAD = M_PI / 180.0;
static const double RAD_TO_DEG = 180.0 / M_PI;

namespace {

GLKMatrix4 glMatrixFromSo3(Matrix3x3d *so3)
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



} // namespace

OrientationEKF::OrientationEKF() :
    previousAccelNorm_(0.0),
    movingAverageAccelNormChange_(0.0),
    timestepFilterInit_(false),
    gyroFilterValid_(true)
    
{
    reset();
}

OrientationEKF::~OrientationEKF()
{
}

void OrientationEKF::reset()
{
    sensorTimeStampGyro_ = 0.0;
    so3SensorFromWorld_.setIdentity();
    so3LastMotion_.setIdentity();
    mP_.setZero();
    mP_.setSameDiagonal(25.0);
    mQ_.setZero();
    mQ_.setSameDiagonal(1.0);
    mR_.setZero();
    mR_.setSameDiagonal(0.0625);
    mRaccel_.setZero();
    mRaccel_.setSameDiagonal(0.5625);
    mS_.setZero();
    mH_.setZero();
    mK_.setZero();
    mNu_.setZero();
    mz_.setZero();
    mh_.setZero();
    mu_.setZero();
    mx_.setZero();
    // Flipped from Android so it uses the same convention as CoreMotion
    // was: down_.set(0.0, 0.0, 9.81);
    down_.set(0.0, 0.0, -9.81);
    north_.set(0.0, 1.0, 0.0);
    alignedToGravity_ = false;
    alignedToNorth_ = false;
}

bool OrientationEKF::isReady()
{
    return alignedToGravity_;
}

double OrientationEKF::getHeadingDegrees()
{
    double x = so3SensorFromWorld_.get(2, 0);
    double y = so3SensorFromWorld_.get(2, 1);
    double mag = sqrt(x * x + y * y);
    if (mag < 0.1) {
        return 0.0;
    }
    double heading = -90.0 - atan2(y, x) * RAD_TO_DEG;
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
    double currentHeading = getHeadingDegrees();
    double deltaHeading = heading - currentHeading;
    double s = sin(deltaHeading * DEG_TO_RAD);
    double c = cos(deltaHeading * DEG_TO_RAD);
    Matrix3x3d deltaHeadingRotationMatrix(c, -s, 0.0, s, c, 0.0, 0.0, 0.0, 1.0);
    Matrix3x3d::mult(&so3SensorFromWorld_, &deltaHeadingRotationMatrix, &so3SensorFromWorld_);
}

GLKMatrix4 OrientationEKF::getGLMatrix()
{
    return glMatrixFromSo3(&so3SensorFromWorld_);
}

GLKMatrix4 OrientationEKF::getPredictedGLMatrix(double secondsAfterLastGyroEvent)
{
    double dT = secondsAfterLastGyroEvent;
    Vector3d pmu(lastGyro_.x * -dT, lastGyro_.y * -dT, lastGyro_.z * -dT);
    Matrix3x3d so3PredictedMotion;
    So3Util::sO3FromMu(&pmu, &so3PredictedMotion);
    Matrix3x3d so3PredictedState;
    Matrix3x3d::mult(&so3PredictedMotion, &so3SensorFromWorld_, &so3PredictedState);
    return glMatrixFromSo3(&so3PredictedState);
}

void OrientationEKF::processGyro(GLKVector3 gyro, double sensorTimeStamp)
{
    if (sensorTimeStampGyro_ != 0.0) {
        
        double dT = sensorTimeStamp - sensorTimeStampGyro_;
        if (dT > 0.04f) {
            dT = gyroFilterValid_ ? filteredGyroTimestep_ : 0.01;
        } else {
            filterGyroTimestep(dT);
        }
        
        mu_.set(gyro.x * -dT, gyro.y * -dT, gyro.z * -dT);
        So3Util::sO3FromMu(&mu_, &so3LastMotion_);
        Matrix3x3d::mult(&so3LastMotion_, &so3SensorFromWorld_, &so3SensorFromWorld_);
        updateCovariancesAfterMotion();
        Matrix3x3d temp;
        temp.set(&mQ_);
        temp.scale(dT * dT);
        mP_.plusEquals(&temp);
        
    }
    sensorTimeStampGyro_ = sensorTimeStamp;
    lastGyro_ = gyro;
}

void OrientationEKF::processAcc(GLKVector3 acc, double sensorTimeStamp)
{
    mz_.set(acc.x, acc.y, acc.z);
    updateAccelCovariance(mz_.length());
    if (alignedToGravity_)
    {
        accObservationFunctionForNumericalJacobian(&so3SensorFromWorld_, &mNu_);
        const double eps = 1.0E-7;
        for (int dof = 0; dof < 3; dof++)
        {
            Vector3d delta;
            delta.setZero();
            delta.setComponent(dof, eps);
            Matrix3x3d tempM;
            So3Util::sO3FromMu(&delta, &tempM);
            Matrix3x3d::mult(&tempM, &so3SensorFromWorld_, &tempM);
            Vector3d tempV;
            accObservationFunctionForNumericalJacobian(&tempM, &tempV);
            Vector3d::sub(&mNu_, &tempV, &tempV);
            tempV.scale(1.0/eps);
            mH_.setColumn(dof, &tempV);
        }
        
        
        Matrix3x3d mHt;
        mH_.transpose(&mHt);
        Matrix3x3d temp;
        Matrix3x3d::mult(&mP_, &mHt, &temp);
        Matrix3x3d::mult(&mH_, &temp, &temp);
        Matrix3x3d::add(&temp, &mRaccel_, &mS_);
        mS_.invert(&temp);
        Matrix3x3d::mult(&mHt, &temp, &temp);
        Matrix3x3d::mult(&mP_, &temp, &mK_);
        Matrix3x3d::mult(&mK_, &mNu_, &mx_);
        Matrix3x3d::mult(&mK_, &mH_, &temp);
        Matrix3x3d temp2;
        temp2.setIdentity();
        temp2.minusEquals(&temp);
        Matrix3x3d::mult(&temp2, &mP_, &mP_);
        So3Util::sO3FromMu(&mx_, &so3LastMotion_);
        Matrix3x3d::mult(&so3LastMotion_, &so3SensorFromWorld_, &so3SensorFromWorld_);
        updateCovariancesAfterMotion();
    }
    else
    {
        So3Util::sO3FromTwoVec(&down_, &mz_, &so3SensorFromWorld_);
        alignedToGravity_ = true;
    }
}

void OrientationEKF::filterGyroTimestep(double timestep)
{
    const double kFilterCoeff = 0.95;
    if (!timestepFilterInit_) {
        filteredGyroTimestep_ = timestep;
        numGyroTimestepSamples_ = 1;
        timestepFilterInit_ = true;
    }
    else {
        filteredGyroTimestep_ = kFilterCoeff * filteredGyroTimestep_ + (1.0-kFilterCoeff) * timestep;
        ++numGyroTimestepSamples_;
        gyroFilterValid_ = (numGyroTimestepSamples_ > 10);
    }
}

void OrientationEKF::updateCovariancesAfterMotion()
{
    Matrix3x3d temp;
    so3LastMotion_.transpose(&temp);
    Matrix3x3d::mult(&mP_, &temp, &temp);
    Matrix3x3d::mult(&so3LastMotion_, &temp, &mP_);
    so3LastMotion_.setIdentity();
}

void OrientationEKF::updateAccelCovariance(double currentAccelNorm)
{
    double currentAccelNormChange = fabs(currentAccelNorm - previousAccelNorm_);
    previousAccelNorm_ = currentAccelNorm;
    const double kSmoothingFactor = 0.5;
    movingAverageAccelNormChange_ = kSmoothingFactor * movingAverageAccelNormChange_ + (1.0-kSmoothingFactor) * currentAccelNormChange;
    const double kMaxAccelNormChange = 0.15;
    const double kMinAccelNoiseSigma = 0.75;
    const double kMaxAccelNoiseSigma = 7.0;
    double normChangeRatio = movingAverageAccelNormChange_ / kMaxAccelNormChange;
    double accelNoiseSigma = std::min(kMaxAccelNoiseSigma, kMinAccelNoiseSigma + normChangeRatio * (kMaxAccelNoiseSigma-kMinAccelNoiseSigma));
    mRaccel_.setSameDiagonal(accelNoiseSigma * accelNoiseSigma);
}

void OrientationEKF::accObservationFunctionForNumericalJacobian(Matrix3x3d* so3SensorFromWorldPred, Vector3d* result)
{
    Matrix3x3d::mult(so3SensorFromWorldPred, &down_, &mh_);
    Matrix3x3d temp;
    So3Util::sO3FromTwoVec(&mh_, &mz_, &temp);
    So3Util::muFromSO3(&temp, result);
}

