//
//  Distortion.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-26.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "Distortion.h"
#include <cmath>

Distortion::Distortion()
{
    this->coefficients.c[0] = 250.0f;
    this->coefficients.c[1] = 50000.0f;
}

Distortion::Distortion(Distortion *other)
{
    DistortionCoeffients coefficients = other->getCoefficients();
    this->coefficients.c[0] = coefficients.c[0];
    this->coefficients.c[1] = coefficients.c[1];
}

void Distortion::setCoefficients(DistortionCoeffients coefficients)
{
    this->coefficients.c[0] = coefficients.c[0];
    this->coefficients.c[1] = coefficients.c[1];
}

DistortionCoeffients Distortion::getCoefficients()
{
    return this->coefficients;
}

float Distortion::distortionFactor(float radius)
{
    float rSq = radius * radius;
    return 1.0F + this->coefficients.c[0] * rSq + this->coefficients.c[1] * rSq * rSq;
}

float Distortion::distort(float radius)
{
    return radius * this->distortionFactor(radius);
}

float Distortion::distortInverse(float radius)
{
    float r0 = radius / 0.9f;
    float r1 = radius * 0.9f;
    float dr0 = radius - this->distort(r0);
    while (fabs(r1 - r0) > 0.0001)
    {
        float dr1 = radius - this->distort(r1);
        float r2 = r1 - dr1 * ((r1 - r0) / (dr1 - dr0));
        r0 = r1;
        r1 = r2;
        dr0 = dr1;
    }
    return r1;
}

bool Distortion::equals(Distortion *other)
{
    if (other == nullptr) {
        return false;
    }
    if (other == this) {
        return true;
    }
    return (this->coefficients.c[0] == other->getCoefficients().c[0]) && (this->coefficients.c[1] == other->getCoefficients().c[1]);
}

NSString* Distortion::toString()
{
    return [NSString stringWithFormat:@"Distortion {%f, %f}", this->coefficients.c[0], this->coefficients.c[1]];
}