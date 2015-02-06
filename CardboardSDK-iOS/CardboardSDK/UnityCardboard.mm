//
//  UnityCardboardViewController.m
//  CardboardSDK-iOS
//
//  Created by Carden Bagwell on 2/2/15.
//
//

#import "UnityCardboard.h"



extern void UnitySendMessage(const char *className, const char *methodName, const char *params);
static CardboardViewController *CBVC = nil;

extern "C" {
  
    CardboardViewController *getCBVC() {
        if( !CBVC ) {
            CBVC = [CardboardViewController new];
        }
        return CBVC;
    }

    void _initFromUnity(const char *unityObjectName) {
        //UnitySendMessage(unityObjectName, "OnInsertedCardboardInternal", "");
        //ucVC = [[UnityCardboardViewController alloc] init];
        [getCBVC() initFromUnity:unityObjectName];
    }

    void getFrameParams(float *frameParams, float near, float far) {

        //run calculate frame params before this
        [getCBVC() getFrameParameters:frameParams near:near far:far];

    }
    
    void convertTapIntoTrigger(BOOL enabled) {
        [getCBVC() setConvertTapIntoTrigger:enabled];
    }
    
};

