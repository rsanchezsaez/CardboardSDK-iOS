//
//  MagnetSensor.h
//  CardboardSDK-iOS
//
//

#ifndef __CardboardSDK_iOS__MagnetSensor__
#define __CardboardSDK_iOS__MagnetSensor__

#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>

#include <vector>


namespace CardboardSDK
{

NSString *const CBDTriggerPressedNotification = @"CBTriggerPressedNotification";

class MagnetSensor
{
  public:
    MagnetSensor();
    virtual ~MagnetSensor() {}
    void start();
    void stop();
    
  private:
    CMMotionManager *_manager;
    size_t _sampleIndex;
    GLKVector3 _baseline;
    std::vector<GLKVector3> _sensorData;
    std::vector<float> _offsets;
    

    void addData(GLKVector3 value);
    void evaluateModel();
    void computeOffsets(int start, GLKVector3 baseline);
    
    static const size_t numberOfSamples = 20;
};

}

#endif