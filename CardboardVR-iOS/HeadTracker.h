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
#include <vector>
#include "Structs.h"
#include "OrientationEKF.h"

class HeadTracker
{
public:
    HeadTracker();
    ~HeadTracker();
    void startTracking();
    void stopTracking();
    GLKMatrix4 getLastHeadView();
private:
    GLKMatrix4 getRotateEulerMatrix(float x, float y, float z);
private:
    CMMotionManager *manager;
    double lastGyroEventTimeSeconds;
    OrientationEKF *tracker;
    GLKMatrix4 ekfToHeadTracker;
};

#endif
