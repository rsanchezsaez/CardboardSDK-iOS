//
//  EyeTransform.mm
//  CardboardSDK-iOS
//
//

#include "EyeTransform.h"

EyeTransform::EyeTransform(EyeParams *params)
{
    _eyeParams = params;
    _eyeView = GLKMatrix4Identity;
    _perspective = GLKMatrix4Identity;
}

GLKMatrix4 EyeTransform::eyeView()
{
    return _eyeView;
}

void EyeTransform::setEyeView(GLKMatrix4 eyeView)
{
    _eyeView = eyeView;
}

GLKMatrix4 EyeTransform::perspective()
{
    return _perspective;
}

void EyeTransform::setPerspective(GLKMatrix4 perspective)
{
    _perspective = perspective;
}

EyeParams* EyeTransform::eyeParams()
{
    return _eyeParams;
}
