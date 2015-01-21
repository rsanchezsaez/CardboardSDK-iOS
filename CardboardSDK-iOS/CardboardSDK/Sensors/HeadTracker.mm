//
//  HeadTracker.mm
//  CardboardSDK-iOS
//

#include "HeadTracker.h"

#define HEAD_TRACKER_MODE_EKF 0
#define HEAD_TRACKER_MODE_CORE_MOTION 1
#define HEAD_TRACKER_MODE_CORE_MOTION_EKF 2

#define HEAD_TRACKER_MODE HEAD_TRACKER_MODE_CORE_MOTION_EKF

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
    // this assumes the device is landscape with the home button on the right
    _deviceToDisplay(GetRotateEulerMatrix(0.f, 0.f, -90.f)),
    // the inertial reference frame has z up and x forward, while the world has z out and x right
    _worldToInertialReferenceFrame(GetRotateEulerMatrix(-90.f, 0.f, 90.f)),
    _lastGyroEventTimestamp(0),
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

  #if HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_EKF
    NSOperationQueue *accelerometerQueue = [[NSOperationQueue alloc] init];
    NSOperationQueue *gyroQueue = [[NSOperationQueue alloc] init];
    
    // Probably capped at less than 100Hz
    // (http://stackoverflow.com/questions/4790111/what-is-the-official-iphone-4-maximum-gyroscope-data-update-frequency)
    _motionManager.accelerometerUpdateInterval = 1.0/100.0;
    [_motionManager startAccelerometerUpdatesToQueue:accelerometerQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error)
    {
        CMAcceleration acceleration = accelerometerData.acceleration;
        // note core motion uses units of G while the EKF uses ms^-2
        const float kG = 9.81f;
        _tracker->processAcceleration(GLKVector3Make(kG*acceleration.x, kG*acceleration.y, kG*acceleration.z), accelerometerData.timestamp);
    }];
    
    _motionManager.gyroUpdateInterval = 1.0/100.0;
    [_motionManager startGyroUpdatesToQueue:gyroQueue withHandler:^(CMGyroData *gyroData, NSError *error) {
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
  #if HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_EKF || HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION_EKF
    NSTimeInterval currentTimestamp = CACurrentMediaTime();
    double secondsSinceLastGyroEvent = currentTimestamp - _lastGyroEventTimestamp;
    // 1/30 of a second prediction (shoud it be 1/60?)
    double secondsToPredictForward = secondsSinceLastGyroEvent + 1.0/30;
    GLKMatrix4 inertialReferenceFrameToDevice = _tracker->getPredictedGLMatrix(secondsToPredictForward);
  #elif HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION
    CMDeviceMotion *motion = _motionManager.deviceMotion;
    CMRotationMatrix rotationMatrix = motion.attitude.rotationMatrix;
    GLKMatrix4 inertialReferenceFrameToDevice = GLKMatrix4Transpose(GLMatrixFromRotationMatrix(rotationMatrix)); // note the matrix inversion
  #endif
    
    GLKMatrix4 worldToDevice = GLKMatrix4Multiply(inertialReferenceFrameToDevice, _worldToInertialReferenceFrame);
    GLKMatrix4 worldToDisplay = GLKMatrix4Multiply(_deviceToDisplay, worldToDevice);
    
    // NSLog(@"%@", NSStringFromGLKMatrix4(worldToDisplay));
    if (_neckModelEnabled)
    {
        worldToDisplay = GLKMatrix4Multiply(_neckModelTranslation, worldToDisplay);
        worldToDisplay = GLKMatrix4Translate(worldToDisplay, 0.0f, _defaultNeckVerticalOffset, 0.0f);
    }
    
    return worldToDisplay;
}

bool HeadTracker::neckModelEnabled()
{
    return _neckModelEnabled;
}

void HeadTracker::setNeckModelEnabled(bool enabled)
{
    _neckModelEnabled = enabled;
}