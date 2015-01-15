//
//  HeadTracker.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
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
    GLKMatrix4 getLastHeadView();
    
private:
    CMMotionManager* motionManager_;
    OrientationEKF* tracker_;
    GLKMatrix4 deviceToDisplay_;
    GLKMatrix4 worldToInertialReferenceFrame_;
    NSTimeInterval lastGyroEventTimestamp_;
};

#endif
