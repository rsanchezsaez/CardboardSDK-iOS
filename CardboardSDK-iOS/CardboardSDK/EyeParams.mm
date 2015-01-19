//
//  EyeParams.mm
//  CardboardSDK-iOS
//
//

#include "EyeParams.h"

EyeParams::EyeParams(EyeParamsType eye)
{
    _type = eye;
    _viewport = new Viewport();
    _fov = new FieldOfView();
    _eyeTransform = new EyeTransform(this);
}

EyeParams::~EyeParams()
{
    delete _viewport;
    delete _fov;
    delete _eyeTransform;
}

EyeParamsType EyeParams::type()
{
    return _type;
}

Viewport* EyeParams::viewport()
{
    return _viewport;
}

FieldOfView* EyeParams::fov()
{
    return _fov;
}

EyeTransform* EyeParams::transform()
{
    return _eyeTransform;
}