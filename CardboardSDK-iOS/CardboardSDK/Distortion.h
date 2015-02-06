//
//  Distortion.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__Distortion__
#define __CardboardSDK_iOS__Distortion__

#import <Foundation/Foundation.h>


namespace CardboardSDK
{

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
    
    NSString *toString();
    
  private:
    constexpr static int s_numberOfCoefficients = 2;
    float _coefficients[s_numberOfCoefficients];
};

}

#endif
