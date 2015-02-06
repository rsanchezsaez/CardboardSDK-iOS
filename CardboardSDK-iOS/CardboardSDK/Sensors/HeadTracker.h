//
//  HeadTracker.h
//  CardboardSDK-iOS
//

#ifndef __CardboardSDK_iOS__HeadTracker__
#define __CardboardSDK_iOS__HeadTracker__

#include "OrientationEKF.h"

#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>


namespace CardboardSDK
{

class HeadTracker
{
  public:
    HeadTracker();
    virtual ~HeadTracker();
    
    void startTracking(UIInterfaceOrientation orientation);
    void stopTracking();
    GLKMatrix4 lastHeadView();
    
    void updateDeviceOrientation(UIInterfaceOrientation orientation);

    bool neckModelEnabled();
    void setNeckModelEnabled(bool enabled);
    
    bool isReady();
    
  private:
    CMMotionManager *_motionManager;
    size_t _sampleCount;
    OrientationEKF *_tracker;
    GLKMatrix4 _displayFromDevice;
    GLKMatrix4 _inertialReferenceFrameFromWorld;
    GLKMatrix4 _correctedInertialReferenceFrameFromWorld;
    GLKMatrix4 _lastHeadView;
    NSTimeInterval _lastGyroEventTimestamp;
    bool _headingCorrectionComputed;
    bool _neckModelEnabled;
    GLKMatrix4 _neckModelTranslation;
    float _orientationCorrectionAngle;

    const float _defaultNeckHorizontalOffset = 0.08f;
    const float _defaultNeckVerticalOffset = 0.075f;
};

}

#endif
