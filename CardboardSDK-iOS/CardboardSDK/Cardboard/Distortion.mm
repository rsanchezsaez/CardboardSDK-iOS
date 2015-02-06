//
//  Distortion.mm
//  CardboardSDK-iOS
//


#include "Distortion.h"


namespace CardboardSDK
{

Distortion::Distortion()
{
    _coefficients[0] = 0.441f;
    _coefficients[1] = 0.156f;
}

Distortion::Distortion(Distortion *other)
{
    for (int i = 0; i < s_numberOfCoefficients; i++)
    {
        _coefficients[i] = other->_coefficients[i];
    }
}

void Distortion::setCoefficients(float *coefficients)
{
    for (int i = 0; i < s_numberOfCoefficients; i++)
    {
        _coefficients[i] = coefficients[i];
    }
}

float *Distortion::coefficients()
{
    return _coefficients;
}

float Distortion::distortionFactor(float radius)
{
    float result = 1.0f;
    float rFactor = 1.0f;
    float squaredRadius = radius * radius;
    for (int i = 0; i < s_numberOfCoefficients; i++)
    {
        rFactor *= squaredRadius;
        result += _coefficients[i] * rFactor;
    }
    return result;
}

float Distortion::distort(float radius)
{
    return radius * distortionFactor(radius);
}

float Distortion::distortInverse(float radius)
{
    float r0 = radius / 0.9f;
    float r = radius * 0.9f;
    float dr0 = radius - distort(r0);
    while (fabsf(r - r0) > 0.0001f)
    {
        float dr = radius - distort(r);
        float r2 = r - dr * ((r - r0) / (dr - dr0));
        r0 = r;
        r = r2;
        dr0 = dr;
    }
    return r;
}

bool Distortion::equals(Distortion *other)
{
    if (other == nullptr)
    {
        return false;
    }
    else if (other == this)
    {
        return true;
    }

    for (int i = 0; i < s_numberOfCoefficients; i++)
    {
        if (_coefficients[i] != other->_coefficients[i])
        {
            return false;
        }
    }

    return true;
}

NSString *Distortion::toString()
{
    return [NSString stringWithFormat:@"{%f, %f}", _coefficients[0], _coefficients[1]];
}

}