//
//  EyeParams.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-26.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "EyeParams.h"

EyeParams::EyeParams(EyeParamsType eye)
{
    this->eye = eye;
    this->viewport = new Viewport();
    this->fov = new FieldOfView();
    this->eyeTransform = new EyeTransform(this);
}

EyeParams::~EyeParams()
{
    delete this->viewport;
    delete this->fov;
    delete this->eyeTransform;
}

EyeParamsType EyeParams::getEye()
{
    return this->eye;
}

Viewport* EyeParams::getViewport()
{
    return this->viewport;
}

FieldOfView* EyeParams::getFov()
{
    return this->fov;
}

EyeTransform* EyeParams::getTransform()
{
    return this->eyeTransform;
}