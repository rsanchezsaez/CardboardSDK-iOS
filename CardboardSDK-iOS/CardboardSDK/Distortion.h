//
//  Distortion.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__Distortion__
#define __CardboardSDK_iOS__Distortion__

#import <UIKit/UIKit.h>

struct DistortionCoeffients
{
    float c[2];
};

class Distortion
{
  public:
    Distortion();
    Distortion(Distortion *other);
    
    void setCoefficients(float *coefficients);
    float *coefficients();
    
    float distortionFactor(float radius);
    float distort(float radius);
    float distortInverse(float radius);
    bool equals(Distortion *other);
    
    NSString* toString();
    
  private:
    float _coefficients[2];
};

#endif
