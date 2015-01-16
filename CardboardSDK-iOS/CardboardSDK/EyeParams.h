//
//  EyeParams.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-26.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#ifndef __CardboardVR_iOS__EyeParams__
#define __CardboardVR_iOS__EyeParams__

#import <UIKit/UIKit.h>
#include "Viewport.h"
#include "FieldOfView.h"
#include "EyeTransform.h"

typedef enum
{
    EyeParamsTypeMonocular = 0,
    EyeParamsTypeLeft = 1,
    EyeParamsTypeRight = 2
} EyeParamsType;

class EyeParams
{
public:
    EyeParams(EyeParamsType eye);
    ~EyeParams();
    EyeParamsType getEye();
    Viewport* getViewport();
    FieldOfView* getFov();
    EyeTransform* getTransform();
private:
    EyeParamsType eye;
    Viewport *viewport;
    FieldOfView *fov;
    EyeTransform *eyeTransform;
};

#endif