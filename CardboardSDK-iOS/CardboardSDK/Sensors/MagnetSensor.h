//
//  MagnetSensor.h
//  CardboardSDK-iOS
//
//

#ifndef __CardboardSDK_iOS__MagnetSensor__
#define __CardboardSDK_iOS__MagnetSensor__

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>
#include <vector>
 
NSString *const CBTriggerPressedNotification = @"CBTriggerPressedNotification";

class MagnetSensor
{
  public:
    MagnetSensor();
    void start();
    void stop();
    
  private:
    CMMotionManager *_manager;
    std::vector<GLKVector3> _sensorData;

    void addData(GLKVector3 value);
    void evaluateModel();
    std::vector<float> computeOffsets(int start, GLKVector3 baseline);
    float computeMinimum(std::vector<float> offsets);
    float computeMaximum(std::vector<float> offsets);
};

#endif