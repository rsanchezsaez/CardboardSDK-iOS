//
//  Distortion.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-24.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "Distortion.h"

@interface Distortion ()

@property (nonatomic, assign) DistortionCoeffients coefficients;

@end

@implementation Distortion

- (id)init
{
    self = [super init];
    if (self)
    {
        DistortionCoeffients coeffients;
        coeffients.c[0] = 250.0f;
        coeffients.c[1] = 50000.0f;
        self.coefficients = coeffients;
    }
    return self;
}

- (id)initWithDistortion:(Distortion*)other
{
    self = [super init];
    if (self)
    {
        DistortionCoeffients coefficients = [other getCoefficients];
        self.coefficients.c[0] = coefficients.c[0];
        self.coefficients.c[1] = coefficients.c[1];
    }
    return self;
}

- (void)setCoefficients:(DistortionCoeffients)coefficients
{
    self.coefficients.c[0] = coefficients.c[0];
    self.coefficients.c[1] = coefficients.c[1];
}

- (DistortionCoeffients)getCoefficients
{
    return self.coefficients;
}

- (float)distortionFactor:(float)radius
{
    float rSq = radius * radius;
    return 1.0F + self.coefficients.c[0] * rSq + self.coefficients.c[1] * rSq * rSq;
}

- (float)distort:(float)radius
{
    return radius * [self distortionFactor:radius];
}

- (float)distortInverse:(float)radius
{
    float r0 = radius / 0.9f;
    float r1 = radius * 0.9f;
    float dr0 = radius - [self distort:r0];
    while (abs(r1 - r0) > 0.0001)
    {
        float dr1 = radius - [self distort:r1];
        float r2 = r1 - dr1 * ((r1 - r0) / (dr1 - dr0));
        r0 = r1;
        r1 = r2;
        dr0 = dr1;
    }
    return r1;
}

- (bool)equals:(id)other
{
    if (other == nil)
    {
        return false;
    }
    if (other == self)
    {
        return true;
    }
    if (![other isKindOfClass:[Distortion class]])
    {
        return false;
    }
    Distortion *o = (Distortion *)other;
    return (self.coefficients.c[0] == [o getCoefficients].c[0]) && (self.coefficients.c[1] == [o getCoefficients].c[1]);
}

- (NSString *)toString
{
    return [NSString stringWithFormat:@"Distortion {%f, %f}", self.coefficients.c[0], self.coefficients.c[1]];
}

@end
