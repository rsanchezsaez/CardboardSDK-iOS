//
//  CardboardDeviceParams.h
//  CardboardSDK-iOS
//
//

#ifndef __CardboardSDK_iOS__CardboardDeviceParams__
#define __CardboardSDK_iOS__CardboardDeviceParams__

#import <UIKit/UIKit.h>
#include "Distortion.h"

class CardboardDeviceParams
{
  public:
    CardboardDeviceParams();
    CardboardDeviceParams(CardboardDeviceParams* params);
    ~CardboardDeviceParams();
    
    void setVendor(NSString* vendor);
    NSString *vendor();
    
    void setModel(NSString* model);
    NSString *model();
    
    void setVersion(NSString* version);
    NSString *version();
    
    void setInterLensDistance(float interLensDistance);
    float interLensDistance();
    
    void setVerticalDistanceToLensCenter(float verticalDistanceToLensCenter);
    float verticalDistanceToLensCenter();
    
    void setVisibleViewportSize(float visibleViewportSize);
    float visibleViewportSize();
    
    void setFovY(float fovY);
    float fovY();
    
    void setLensDiameter(float lensDiameter);
    float lensDiameter();
    
    void setScreenToLensDistance(float screenToLensDistance);
    float screenToLensDistance();
    
    void setEyeToLensDistance(float eyeToLensDistance);
    float eyeToLensDistance();

    Distortion* getDistortion();
    
    bool equals(CardboardDeviceParams *other);
    
private:
    NSString *_vendor;
    NSString *_model;
    NSString *_version;
    float _interLensDistance;
    float _verticalDistanceToLensCenter;
    float _lensDiameter;
    float _screenToLensDistance;
    float _eyeToLensDistance;
    float _visibleViewportSize;
    float _fovY;
    Distortion *_distortion;
};

#endif
