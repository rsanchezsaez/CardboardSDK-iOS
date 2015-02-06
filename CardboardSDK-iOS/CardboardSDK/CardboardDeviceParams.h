//
//  CardboardDeviceParams.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__CardboardDeviceParams__
#define __CardboardSDK_iOS__CardboardDeviceParams__

#import <Foundation/Foundation.h>


namespace CardboardSDK
{

class Distortion;
class FieldOfView;


class CardboardDeviceParams
{
  public:
    CardboardDeviceParams();
    CardboardDeviceParams(CardboardDeviceParams* params);
    ~CardboardDeviceParams();
    
    NSString *vendor();
    NSString *model();
    
    float interLensDistance();
    
    float verticalDistanceToLensCenter();
  
    float screenToLensDistance();
    
    FieldOfView *maximumLeftEyeFOV();
    Distortion *distortion();
    
    bool equals(CardboardDeviceParams *other);
    
private:
    NSString *_vendor;
    NSString *_model;
    NSString *_version;
    float _interLensDistance;
    float _verticalDistanceToLensCenter;
    float _screenToLensDistance;

    FieldOfView *_maximumLeftEyeFOV;
    Distortion *_distortion;
};

}

#endif
