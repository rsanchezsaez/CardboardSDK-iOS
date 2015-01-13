//
//  EyeTransform.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-26.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "EyeTransform.h"

EyeTransform::EyeTransform(EyeParams *params)
{
    this->eyeParams = params;
    this->eyeView = GLKMatrix4Identity;
    this->perspective = GLKMatrix4Identity;
}

GLKMatrix4 EyeTransform::getEyeView()
{
    return this->eyeView;
}

void EyeTransform::setEyeView(GLKMatrix4 eyeView)
{
    this->eyeView = eyeView;
}

GLKMatrix4 EyeTransform::getPerspective()
{
    return this->perspective;
}

void EyeTransform::setPerspective(GLKMatrix4 perspective)
{
    this->perspective = perspective;
}

EyeParams* EyeTransform::getParams()
{
    return this->eyeParams;
}
