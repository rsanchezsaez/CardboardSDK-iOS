//
//  MagnetSensor.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#ifndef __CardboardVR_iOS__MagnetSensor__
#define __CardboardVR_iOS__MagnetSensor__

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>
#include <vector>
#include "Structs.h"

NSString *const CBTriggerPressedNotification = @"CBTriggerPressedNotification";

class MagnetSensor
{
public:
    MagnetSensor();
    void start();
    void stop();
private:
    CMMotionManager *manager;
    std::vector<GLKVector3> sensorData;
private:
    void addData(GLKVector3 value);
    void evaluateModel();
    std::vector<float> computeOffsets(int start, GLKVector3 baseline);
    float computeMinimum(std::vector<float> offsets);
    float computeMaximum(std::vector<float> offsets);
};

#endif