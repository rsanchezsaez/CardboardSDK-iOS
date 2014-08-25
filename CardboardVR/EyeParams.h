//
//  EyeParams.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Viewport.h"
#import "FieldOfView.h"
#import "EyeTransform.h"

@class EyeTransform;

@interface EyeParams : NSObject

typedef enum
{
    MONOCULAR = 0,
    LEFT = 1,
    RIGHT = 2
} EyeParamsEyeType;

- (id)initWithEye:(EyeParamsEyeType)eye;
- (EyeParamsEyeType)getEye;
- (Viewport*)getViewport;
- (FieldOfView*)getFov;
- (EyeTransform*)getTransform;

@end
