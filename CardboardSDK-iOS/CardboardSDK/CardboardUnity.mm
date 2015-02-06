//
//  CardboardUnity.cpp
//  CardboardSDK-iOS
//
//  Created by Ricardo Sánchez-Sáez on 03/02/2015.
//
//

#import "CardboardUnity.h"

#import "CBDViewController.h"


#ifdef __cplusplus
  extern "C" {
#endif

      
static CBDViewController *cardboardViewController = nil;
      
void _unity_getFrameParameters(float *frameParameters)
{
    if (!cardboardViewController)
    {
        cardboardViewController = [CBDViewController new];
    }
    
    [cardboardViewController getFrameParameters:frameParameters];
}

      
#ifdef __cplusplus
  }
#endif