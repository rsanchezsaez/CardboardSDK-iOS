//
//  HeadTransform.mm
//  CardboardSDK-iOS
//


#include "HeadTransform.h"


namespace CardboardSDK
{

HeadTransform::HeadTransform() :
    _headView(GLKMatrix4Identity)
{
}

void HeadTransform::setHeadView(GLKMatrix4 headview)
{
    _headView = headview;
}

GLKMatrix4 HeadTransform::headView()
{
    return _headView;
}

GLKVector3 HeadTransform::translation()
{
    return GLKVector3Make(_headView.m[12], _headView.m[13], _headView.m[14]);
}

GLKVector3 HeadTransform::forwardVector()
{
    return GLKVector3Make(-_headView.m[8], -_headView.m[9], -_headView.m[10]);
}

GLKVector3 HeadTransform::upVector()
{
    return GLKVector3Make(_headView.m[4], _headView.m[5], _headView.m[6]);
}

GLKVector3 HeadTransform::rightVector()
{
    return GLKVector3Make(_headView.m[0], _headView.m[1], _headView.m[2]);
}

GLKQuaternion HeadTransform::quaternion()
{
    float t = _headView.m[0] + _headView.m[5] + _headView.m[10];
    float s, w, x, y, z;
    if (t >= 0.0f)
    {
        s = sqrtf(t + 1.0f);
        w = 0.5f * s;
        s = 0.5f / s;
        x = (_headView.m[9] - _headView.m[6]) * s;
        y = (_headView.m[2] - _headView.m[8]) * s;
        z = (_headView.m[4] - _headView.m[1]) * s;
    }
    else if ((_headView.m[0] > _headView.m[5]) && (_headView.m[0] > _headView.m[10]))
        {
            s = sqrtf(1.0f + _headView.m[0] - _headView.m[5] - _headView.m[10]);
            x = s * 0.5f;
            s = 0.5f / s;
            y = (_headView.m[4] + _headView.m[1]) * s;
            z = (_headView.m[2] + _headView.m[8]) * s;
            w = (_headView.m[9] - _headView.m[6]) * s;
        }
    else if (_headView.m[5] > _headView.m[10])
    {
        s = sqrtf(1.0f + _headView.m[5] - _headView.m[0] - _headView.m[10]);
        y = s * 0.5f;
        s = 0.5f / s;
        x = (_headView.m[4] + _headView.m[1]) * s;
        z = (_headView.m[9] + _headView.m[6]) * s;
        w = (_headView.m[2] - _headView.m[8]) * s;
    }
    else
    {
        s = sqrtf(1.0f + _headView.m[10] - _headView.m[0] - _headView.m[5]);
        z = s * 0.5f;
        s = 0.5f / s;
        x = (_headView.m[2] + _headView.m[8]) * s;
        y = (_headView.m[9] + _headView.m[6]) * s;
        w = (_headView.m[4] - _headView.m[1]) * s;
    }
    
    return GLKQuaternionMake(x, y, z, w);
}

GLKVector3 HeadTransform::eulerAngles()
{
    float yaw = 0;
    float roll = 0;
    float pitch = asinf(_headView.m[6]);
    if (sqrtf(1.0f - _headView.m[6] * _headView.m[6]) >= 0.01f)
    {
        yaw = atan2f(-_headView.m[2], _headView.m[10]);
        roll = atan2f(-_headView.m[4], _headView.m[5]);
    }
    else
    {
        yaw = 0.0f;
        roll = atan2f(_headView.m[1], _headView.m[0]);
    }
    return GLKVector3Make(-pitch, -yaw, -roll);
}

}