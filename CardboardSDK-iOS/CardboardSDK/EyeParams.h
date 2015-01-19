//
//  EyeParams.h
//  CardboardSDK-iOS
//
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

    EyeParamsType type();

    Viewport *viewport();
    FieldOfView *fov();
    EyeTransform *transform();
  private:
    EyeParamsType _type;
    Viewport *_viewport;
    FieldOfView *_fov;
    EyeTransform *_eyeTransform;
};

#endif