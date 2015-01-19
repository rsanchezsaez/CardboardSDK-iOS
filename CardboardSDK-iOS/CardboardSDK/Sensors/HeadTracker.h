//
//  HeadTracker.h
//  CardboardSDK-iOS
//

#ifndef __CardboardVR_iOS__HeadTracker__
#define __CardboardVR_iOS__HeadTracker__

#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>
#include "OrientationEKF.h"

class HeadTracker
{
  public:
    HeadTracker();
    virtual ~HeadTracker();
    
    void startTracking();
    void stopTracking();
    GLKMatrix4 lastHeadView();
    
  private:
    CMMotionManager *_motionManager;
    OrientationEKF *_tracker;
    GLKMatrix4 _deviceToDisplay;
    GLKMatrix4 _worldToInertialReferenceFrame;
    NSTimeInterval _lastGyroEventTimestamp;
    bool _neckModelEnabled;
    GLKMatrix4 _neckModelTranslation;
    
    const float _defaultNeckHorizontalOffset = 0.08f;
    const float _defaultNeckVerticalOffset = 0.075f;
};

#endif
