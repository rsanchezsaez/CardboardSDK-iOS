//
//  CardboardUnity.cpp
//  CardboardSDK-iOS
//
//  Created by Ricardo Sánchez-Sáez on 03/02/2015.
//
//

#import "CardboardUnity.h"

#import "CardboardViewController.h"


#ifdef __cplusplus
  extern "C" {
#endif

      
static CardboardViewController *cardboardViewController = nil;
      
void _unity_getFrameParameters(float *frameParameters)
{
    if (!cardboardViewController)
    {
        cardboardViewController = [CardboardViewController new];
    }
    
    [cardboardViewController getFrameParameters:frameParameters];
}

      
#ifdef __cplusplus
  }
#endif