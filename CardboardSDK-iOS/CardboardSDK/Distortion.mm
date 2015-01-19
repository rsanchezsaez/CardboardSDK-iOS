//
//  Distortion.mm
//  CardboardSDK-iOS
//


#include "Distortion.h"
#include <cmath>

Distortion::Distortion()
{
    _coefficients[0] = 250.0f;
    _coefficients[1] = 50000.0f;
}

Distortion::Distortion(Distortion *other)
{
    _coefficients[0] = other->_coefficients[0];
    _coefficients[1] = other->_coefficients[1];
}

void Distortion::setCoefficients(float *coefficients)
{
    _coefficients[0] = coefficients[0];
    _coefficients[1] = coefficients[1];
}

float *Distortion::coefficients()
{
    return _coefficients;
}

float Distortion::distortionFactor(float radius)
{
    float squaredRadius = radius * radius;
    return 1.0f + _coefficients[0] * squaredRadius + _coefficients[1] * squaredRadius * squaredRadius;
}

float Distortion::distort(float radius)
{
    return radius * distortionFactor(radius);
}

float Distortion::distortInverse(float radius)
{
    float r0 = radius / 0.9f;
    float r1 = radius * 0.9f;
    float dr0 = radius - distort(r0);
    while (fabsf(r1 - r0) > 0.0001f)
    {
        float dr1 = radius - distort(r1);
        float r2 = r1 - dr1 * ((r1 - r0) / (dr1 - dr0));
        r0 = r1;
        r1 = r2;
        dr0 = dr1;
    }
    return r1;
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
    return (_coefficients[0] == other->_coefficients[0]) && (_coefficients[1] == other->_coefficients[1]);
}

NSString* Distortion::toString()
{
    return [NSString stringWithFormat:@"Distortion {%f, %f}", _coefficients[0], _coefficients[1]];
}