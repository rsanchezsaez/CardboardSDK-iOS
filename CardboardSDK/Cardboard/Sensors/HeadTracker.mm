//
//  HeadTracker.mm
//  CardboardSDK-iOS
//

#include "HeadTracker.h"


namespace CardboardSDK
{

#define HEAD_TRACKER_MODE_EKF 0
#define HEAD_TRACKER_MODE_CORE_MOTION 1
#define HEAD_TRACKER_MODE_CORE_MOTION_EKF 2
    
#define HEAD_TRACKER_MODE HEAD_TRACKER_MODE_CORE_MOTION_EKF

#if !TARGET_IPHONE_SIMULATOR
static const size_t CBDInitialSamplesToSkip = 10;
#endif
    
namespace
{

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
    
} // anonymous namespace

HeadTracker::HeadTracker() :
    // this assumes the device is landscape with the home button on the right (UIInterfaceOrientationLandscapeRight)
    _displayFromDevice(GetRotateEulerMatrix(0.f, 0.f, -90.f)),
    // the inertial reference frame has z up and x forward, while the world has -z forward and x right
    _inertialReferenceFrameFromWorld(GetRotateEulerMatrix(-90.f, 0.f, 90.f)),
    _lastGyroEventTimestamp(0),
    _orientationCorrectionAngle(0),
    _neckModelEnabled(false)
{
    _motionManager = [[CMMotionManager alloc] init];
    _tracker = new OrientationEKF();
    
    _correctedInertialReferenceFrameFromWorld = _inertialReferenceFrameFromWorld;
    _lastHeadView = GLKMatrix4Identity;
    _neckModelTranslation = GLKMatrix4Identity;
    _neckModelTranslation = GLKMatrix4Translate(_neckModelTranslation, 0, -_defaultNeckVerticalOffset, _defaultNeckHorizontalOffset);
}

HeadTracker::~HeadTracker()
{
    delete _tracker;
}

void HeadTracker::startTracking(UIInterfaceOrientation orientation)
{
    updateDeviceOrientation(orientation);
    
    _tracker->reset();
    
    _headingCorrectionComputed = false;
    _sampleCount = 0; // used to skip bad data when core motion starts
    
#if !TARGET_IPHONE_SIMULATOR
  #if HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_EKF
    NSOperationQueue *accelerometerQueue = [[NSOperationQueue alloc] init];
    NSOperationQueue *gyroQueue = [[NSOperationQueue alloc] init];
    
    // Probably capped at less than 100Hz
    // (http://stackoverflow.com/questions/4790111/what-is-the-official-iphone-4-maximum-gyroscope-data-update-frequency)
    _motionManager.accelerometerUpdateInterval = 1.0/100.0;
    [_motionManager startAccelerometerUpdatesToQueue:accelerometerQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error)
    {
        ++_sampleCount;
        if (_sampleCount <= kInitialSamplesToSkip) { return; }
        CMAcceleration acceleration = accelerometerData.acceleration;
        // note core motion uses units of G while the EKF uses ms^-2
        const float kG = 9.81f;
        _tracker->processAcceleration(GLKVector3Make(kG*acceleration.x, kG*acceleration.y, kG*acceleration.z), accelerometerData.timestamp);
    }];
    
    _motionManager.gyroUpdateInterval = 1.0/100.0;
    [_motionManager startGyroUpdatesToQueue:gyroQueue withHandler:^(CMGyroData *gyroData, NSError *error) {
        if (_sampleCount <= kInitialSamplesToSkip) { return; }
        CMRotationRate rotationRate = gyroData.rotationRate;
        _tracker->processGyro(GLKVector3Make(rotationRate.x, rotationRate.y, rotationRate.z), gyroData.timestamp);
        _lastGyroEventTimestamp = gyroData.timestamp;
    }];
  #elif HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION
    if (_motionManager.isDeviceMotionAvailable)
    {
        [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
        _sampleCount = kInitialSamplesToSkip + 1;
    }
  #elif HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION_EKF
    NSOperationQueue *deviceMotionQueue = [[NSOperationQueue alloc] init];
    _motionManager.deviceMotionUpdateInterval = 1.0/100.0;
    [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical toQueue:deviceMotionQueue withHandler:^(CMDeviceMotion *motion, NSError *error) {
        ++_sampleCount;
        if (_sampleCount <= CBDInitialSamplesToSkip) { return; }
        CMAcceleration acceleration = motion.gravity;
        CMRotationRate rotationRate = motion.rotationRate;
        // note core motion uses units of G while the EKF uses ms^-2
        const float kG = 9.81f;
        _tracker->processAcceleration(GLKVector3Make(kG*acceleration.x, kG*acceleration.y, kG*acceleration.z), motion.timestamp);
        _tracker->processGyro(GLKVector3Make(rotationRate.x, rotationRate.y, rotationRate.z), motion.timestamp);
        _lastGyroEventTimestamp = motion.timestamp;
    }];
  #endif
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

bool HeadTracker::isReady()
{
    #if TARGET_IPHONE_SIMULATOR
        return true;
    #else
        bool isTrackerReady = (_sampleCount > CBDInitialSamplesToSkip);
        #if HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_EKF || HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION_EKF
            isTrackerReady = isTrackerReady && _tracker->isReady();
        #endif
        return isTrackerReady;
    #endif
}

GLKMatrix4 HeadTracker::lastHeadView()
{
  #if HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_EKF || HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION_EKF
    
    NSTimeInterval currentTimestamp = CACurrentMediaTime();
    double secondsSinceLastGyroEvent = currentTimestamp - _lastGyroEventTimestamp;
    // 1/30 of a second prediction (shoud it be 1/60?)
    double secondsToPredictForward = secondsSinceLastGyroEvent + 1.0/30;
    GLKMatrix4 deviceFromInertialReferenceFrame = _tracker->getPredictedGLMatrix(secondsToPredictForward);
    
  #elif HEAD_TRACKER_MODE == HEAD_TRACKER_MODE_CORE_MOTION
    
    CMDeviceMotion *motion = _motionManager.deviceMotion;
    CMRotationMatrix rotationMatrix = motion.attitude.rotationMatrix;
    GLKMatrix4 deviceFromInertialReferenceFrame = GLKMatrix4Transpose(GLMatrixFromRotationMatrix(rotationMatrix)); // note the matrix inversion
    
    if (!motion) { return _lastHeadView; }
    
  #endif
  
    if (!isReady()) { return _lastHeadView; }

    if (!_headingCorrectionComputed)
    {
        // fix the heading by aligning world -z with the projection 
        // of the device -z on the ground plane
        
        GLKMatrix4 deviceFromWorld = GLKMatrix4Multiply(deviceFromInertialReferenceFrame, _inertialReferenceFrameFromWorld);
        GLKMatrix4 worldFromDevice = GLKMatrix4Transpose(deviceFromWorld);
        
        GLKVector3 deviceForward = GLKVector3Make(0.f, 0.f, -1.f);
        GLKVector3 deviceForwardWorld = GLKMatrix4MultiplyVector3(worldFromDevice, deviceForward);
        
        if (fabsf(deviceForwardWorld.y) < 0.99f)
        {
            deviceForwardWorld.y = 0.f;  // project onto ground plane
            
            deviceForwardWorld = GLKVector3Normalize(deviceForwardWorld);
            
            // want to find R such that
            // deviceForwardWorld = R * [0 0 -1]'
            // where R is a rotation matrix about y, i.e.:
            //     [ c  0  s]
            // R = [ 0  1  0]
            //     [-s  0  c]
            
            float c = -deviceForwardWorld.z;
            float s = -deviceForwardWorld.x;
            // note we actually want to use the inverse, so
            // transpose when building
            GLKMatrix4 Rt = GLKMatrix4Make(
                  c, 0.f,  -s, 0.f,
                0.f, 1.f, 0.f, 0.f,
                  s, 0.f,   c, 0.f,
                0.f, 0.f, 0.f, 1.f );
            
            _correctedInertialReferenceFrameFromWorld = GLKMatrix4Multiply(
                _inertialReferenceFrameFromWorld,
                Rt);
        }
        _headingCorrectionComputed = true;
    }
    
    GLKMatrix4 deviceFromWorld = GLKMatrix4Multiply(
        deviceFromInertialReferenceFrame,
        _correctedInertialReferenceFrameFromWorld);
    GLKMatrix4 displayFromWorld = GLKMatrix4Multiply(_displayFromDevice, deviceFromWorld);
    
    if (_neckModelEnabled)
    {
        displayFromWorld = GLKMatrix4Multiply(_neckModelTranslation, displayFromWorld);
        displayFromWorld = GLKMatrix4Translate(displayFromWorld, 0.0f, _defaultNeckVerticalOffset, 0.0f);
    }
    
    _lastHeadView = displayFromWorld;
    
    return _lastHeadView;
}

void HeadTracker::updateDeviceOrientation(UIInterfaceOrientation orientation)
{
    if (orientation == UIInterfaceOrientationLandscapeLeft)
    {
        _displayFromDevice = GetRotateEulerMatrix(0.f, 0.f, 90.f);
    }
    else if (orientation == UIInterfaceOrientationLandscapeRight)
    {
        _displayFromDevice = GetRotateEulerMatrix(0.f, 0.f, -90.f);
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
    
}
