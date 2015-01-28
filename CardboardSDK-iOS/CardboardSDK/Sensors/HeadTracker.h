//
//  HeadTracker.h
//  CardboardSDK-iOS
//

#ifndef __CardboardSDK_iOS__HeadTracker__
#define __CardboardSDK_iOS__HeadTracker__

#include "OrientationEKF.h"

#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>


class HeadTracker
{
  public:
    HeadTracker();
    virtual ~HeadTracker();
    
    void startTracking();
    void stopTracking();
    GLKMatrix4 lastHeadView();
    
    void updateDeviceOrientation(UIDeviceOrientation orientation);

    bool neckModelEnabled();
    void setNeckModelEnabled(bool enabled);
    
  private:
    CMMotionManager *_motionManager;
    OrientationEKF *_tracker;
    GLKMatrix4 _deviceToDisplay;
    GLKMatrix4 _worldToInertialReferenceFrame;
    NSTimeInterval _lastGyroEventTimestamp;
    bool _neckModelEnabled;
    GLKMatrix4 _neckModelTranslation;
    float _orientationCorrectionAngle;

    const float _defaultNeckHorizontalOffset = 0.08f;
    const float _defaultNeckVerticalOffset = 0.075f;
};

#endif
