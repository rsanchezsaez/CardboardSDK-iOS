//
//  HeadTracker.mm
//  CardboardSDK-iOS
//

#include "HeadTracker.h"

#define HEAD_TRACKER_MODE_EKF 0
#define HEAD_TRACKER_MODE_CORE_MOTION 1
#define HEAD_TRACKER_MODE_CORE_MOTION_EKF 2

#define HEAD_TRACKER_MODE HEAD_TRACKER_MODE_CORE_MOTION_EKF

static const size_t kInitialSamplesToSkip = 10;

namespace {

GLKMatrix4 GetRotateEulerMatrix(float x, float y, float z)
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

#if HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION
GLKMatrix4 GLMatrixFromRotationMatrix(CMRotationMatrix rotationMatrix)
{
    GLKMatrix4 glRotationMatrix;
    
    glRotationMatrix.m00 = rotationMatrix.m11;
    glRotationMatrix.m01 = rotationMatrix.m12;
    glRotationMatrix.m02 = rotationMatrix.m13;
    glRotationMatrix.m03 = 0.0f;
    
    glRotationMatrix.m10 = rotationMatrix.m21;
    glRotationMatrix.m11 = rotationMatrix.m22;
    glRotationMatrix.m12 = rotationMatrix.m23;
    glRotationMatrix.m13 = 0.0f;
    
    glRotationMatrix.m20 = rotationMatrix.m31;
    glRotationMatrix.m21 = rotationMatrix.m32;
    glRotationMatrix.m22 = rotationMatrix.m33;
    glRotationMatrix.m23 = 0.0f;

    glRotationMatrix.m30 = 0.0f;
    glRotationMatrix.m31 = 0.0f;
    glRotationMatrix.m32 = 0.0f;
    glRotationMatrix.m33 = 1.0f;

    return glRotationMatrix;
}
#endif
    
} // namespace

HeadTracker::HeadTracker() :
    // this assumes the device is landscape with the home button on the right (UIDeviceOrientationLandscapeLeft)
    _deviceToDisplay(GetRotateEulerMatrix(0.f, 0.f, -90.f)),
    // the inertial reference frame has z up and x forward, while the world has z out and x right
    _worldToInertialReferenceFrame(GetRotateEulerMatrix(-90.f, 0.f, 90.f)),
    _lastGyroEventTimestamp(0),
    _orientationCorrectionAngle(0),
    _neckModelEnabled(false)
{
    _motionManager = [[CMMotionManager alloc] init];
    _tracker = new OrientationEKF();
    
    _neckModelTranslation = GLKMatrix4Identity;
    _neckModelTranslation = GLKMatrix4Translate(_neckModelTranslation, 0, -_defaultNeckVerticalOffset, _defaultNeckHorizontalOffset);
}

HeadTracker::~HeadTracker()
{
    delete _tracker;
}

void HeadTracker::startTracking()
{
    _tracker->reset();
    
    _sampleCount = 0; // used to skip bad data when core motion starts
    
  #if HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_EKF
    NSOperationQueue *accelerometerQueue = [[NSOperationQueue alloc] init];
    NSOperationQueue *gyroQueue = [[NSOperationQueue alloc] init];
    
    // Probably capped at less than 100Hz
    // (http://stackoverflow.com/questions/4790111/what-is-the-official-iphone-4-maximum-gyroscope-data-update-frequency)
    _motionManager.accelerometerUpdateInterval = 1.0/100.0;
    [_motionManager startAccelerometerUpdatesToQueue:accelerometerQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error)
    {
        ++_sampleCount;
        if (_sampleCount < kInitialSamplesToSkip) return;
        CMAcceleration acceleration = accelerometerData.acceleration;
        // note core motion uses units of G while the EKF uses ms^-2
        const float kG = 9.81f;
        _tracker->processAcceleration(GLKVector3Make(kG*acceleration.x, kG*acceleration.y, kG*acceleration.z), accelerometerData.timestamp);
    }];
    
    _motionManager.gyroUpdateInterval = 1.0/100.0;
    [_motionManager startGyroUpdatesToQueue:gyroQueue withHandler:^(CMGyroData *gyroData, NSError *error) {
        if (_sampleCount < kInitialSamplesToSkip) return;
        CMRotationRate rotationRate = gyroData.rotationRate;
        _tracker->processGyro(GLKVector3Make(rotationRate.x, rotationRate.y, rotationRate.z), gyroData.timestamp);
        _lastGyroEventTimestamp = gyroData.timestamp;
    }];
  #elif HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION
    if (_motionManager.isDeviceMotionAvailable && !_motionManager.isDeviceMotionActive)
    {
        [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
    }
  #elif HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION_EKF
    NSOperationQueue *deviceMotionQueue = [[NSOperationQueue alloc] init];
    _motionManager.deviceMotionUpdateInterval = 1.0/100.0;
    [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical toQueue:deviceMotionQueue withHandler:^(CMDeviceMotion *motion, NSError *error) {
        ++_sampleCount;
        if (_sampleCount < kInitialSamplesToSkip) return;
        CMAcceleration acceleration = motion.gravity;
        CMRotationRate rotationRate = motion.rotationRate;
        // note core motion uses units of G while the EKF uses ms^-2
        const float kG = 9.81f;
        _tracker->processAcceleration(GLKVector3Make(kG*acceleration.x, kG*acceleration.y, kG*acceleration.z), motion.timestamp);
        _tracker->processGyro(GLKVector3Make(rotationRate.x, rotationRate.y, rotationRate.z), motion.timestamp);
        _lastGyroEventTimestamp = motion.timestamp;
    }];
  #endif
    
}

void HeadTracker::stopTracking()
{
  #if HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_EKF
    [_motionManager stopAccelerometerUpdates];
    [_motionManager stopGyroUpdates];
  #elif HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION || HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION_EKF
    [_motionManager stopDeviceMotionUpdates];
  #endif
}

GLKMatrix4 HeadTracker::lastHeadView()
{
    bool isTrackerReady = false;
    
  #if HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_EKF || HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION_EKF
    
    NSTimeInterval currentTimestamp = CACurrentMediaTime();
    double secondsSinceLastGyroEvent = currentTimestamp - _lastGyroEventTimestamp;
    // 1/30 of a second prediction (shoud it be 1/60?)
    double secondsToPredictForward = secondsSinceLastGyroEvent + 1.0/30;
    GLKMatrix4 inertialReferenceFrameToDevice = _tracker->getPredictedGLMatrix(secondsToPredictForward);
    
    isTrackerReady = _tracker->isReady();
    
  #elif HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION
    
    CMDeviceMotion *motion = _motionManager.deviceMotion;
    CMRotationMatrix rotationMatrix = motion.attitude.rotationMatrix;
    GLKMatrix4 inertialReferenceFrameToDevice = GLKMatrix4Transpose(GLMatrixFromRotationMatrix(rotationMatrix)); // note the matrix inversion
    
    isTrackerReady = (motion != nil);
    
  #endif
    
    GLKMatrix4 worldToDevice = GLKMatrix4Multiply(inertialReferenceFrameToDevice, _worldToInertialReferenceFrame);
    GLKMatrix4 worldToDisplay = GLKMatrix4Multiply(_deviceToDisplay, worldToDevice);
    
//    if (_orientationCorrectionAngle == 0 && worldToDisplay.m00 != 0 && isTrackerReady)
//    {
//
//    GLKQuaternion worldToDisplayQuaternion = GLKQuaternionMakeWithMatrix4(worldToDisplay);
//        float q0 = worldToDisplayQuaternion.q[0];
//        float q1 = worldToDisplayQuaternion.q[1];
//        float q2 = worldToDisplayQuaternion.q[2];
//        float q3 = worldToDisplayQuaternion.q[3];
//        
//        // CGFloat phi = atan2f(2*(q0 * q1 + q2 * q3), 1 - 2 * (q1*q1 + q2*q2));
//        CGFloat theta = asinf(2*(q0 * q2 - q3 * q1));
//        CGFloat psi = atan2f(2*(q0 * q3 + q1 * q2), 1 - 2 * (q2*q2 + q3*q3));
//
////        float angleX = atan2f(worldToDisplay.m21, worldToDisplay.m22);
////        float angleY = atan2f(- worldToDisplay.m20,
////                              sqrtf(worldToDisplay.m21 * worldToDisplay.m21 + worldToDisplay.m22 * worldToDisplay.m22));
////        float angleZ = atan2f(worldToDisplay.m10, worldToDisplay.m00);
//
//        _orientationCorrectionAngle = (fabsf(psi) < M_PI_2) ? M_PI - theta : theta;
//
////        GLKMatrix4 desiredViewDirection = GLKMatrix4MakeTranslation(0, 0, -1);
////        GLKVector4 initVector = { 0, 0, 0, 1.0f };
////        desiredViewDirection = GLKMatrix4Multiply(worldToDisplay, desiredViewDirection);
////        GLKVector4 desiredVector = GLKMatrix4MultiplyVector4(desiredViewDirection, initVector);
////        float pitch = atan2f(desiredVector.y, -desiredVector.z);
////        float yaw = atan2f(desiredVector.x, -desiredVector.z);
////        
////        NSLog(@"%f   ( %f | %f | %f )",
////              theta,
////              (worldQuaternion.x * worldQuaternion.z - worldQuaternion.y * worldQuaternion.w),
////              (worldQuaternion.x * worldQuaternion.y - worldQuaternion.z * worldQuaternion.w),
////              (worldQuaternion.y * worldQuaternion.z - worldQuaternion.x * worldQuaternion.w));
////        _orientationCorrectionAngle = yaw;
////        
////        NSLog(@"%f %f %f", pitch, yaw, _orientationCorrectionAngle);
////        
////        GLKMatrix4 worldToDisplayP = GLKMatrix4Rotate(worldToDisplay, angleX, 1, 0, 0);
////        worldToDisplayP = GLKMatrix4Rotate(worldToDisplayP, angleZ, 0, 0, 1);
////        
////        float angleYP = atan2f(- worldToDisplayP.m20,
////                               sqrtf(worldToDisplayP.m21 * worldToDisplayP.m21 + worldToDisplayP.m22 * worldToDisplayP.m22));
////        
////        NSLog(@"  %6.2f %6.2f %6.2f", phi, theta, psi);
////        NSLog(@"  %6.2f", _orientationCorrectionAngle);
////        NSLog(@"%6.2f %6.2f %6.2f    |    %6.2f %6.2f %6.2f    |    %6.2f %6.2f", angleX, angleY, angleZ, phi, theta, psi, pitch, yaw);
////        NSLog(@"%6.2f %6.2f %6.2f", phi, theta, psi);
////        NSLog(@"%d - %6.2f %6.2f", _tracker->isReady(), theta, psi);
//    }
//
//    worldToDisplay = GLKMatrix4Rotate(worldToDisplay, _orientationCorrectionAngle, 0, 0, 1);

    // NSLog(@"%@", NSStringFromGLKMatrix4(worldToDisplay));
    if (_neckModelEnabled)
    {
        worldToDisplay = GLKMatrix4Multiply(_neckModelTranslation, worldToDisplay);
        worldToDisplay = GLKMatrix4Translate(worldToDisplay, 0.0f, _defaultNeckVerticalOffset, 0.0f);
    }
    
    return worldToDisplay;
}

void HeadTracker::updateDeviceOrientation(UIDeviceOrientation orientation)
{
    if (orientation == UIDeviceOrientationLandscapeLeft)
    {
        _deviceToDisplay = GetRotateEulerMatrix(0.f, 0.f, -90.f);
    }
    else if (orientation == UIDeviceOrientationLandscapeRight)
    {
        _deviceToDisplay = GetRotateEulerMatrix(0.f, 0.f, 90.f);
    }
}

bool HeadTracker::neckModelEnabled()
{
    return _neckModelEnabled;
}

void HeadTracker::setNeckModelEnabled(bool enabled)
{
    _neckModelEnabled = enabled;
}