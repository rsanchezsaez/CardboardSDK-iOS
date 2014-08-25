//
//  Matrix3x3d.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-22.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "Matrix3x3d.h"

@implementation Matrix3x3d

- (id)init
{
    self = [super init];
    if (self)
    {
        self.m = malloc(sizeof(double)*9);
        [self setZero];
    }
    return self;
}

- (void)dealloc
{
    free(self.m);
}

- (id)initWithM00:(double)m00 m01:(double)m01 m02:(double)m02 m10:(double)m10 m11:(double)m11 m12:(double)m12 m20:(double)m20 m21:(double)m21 m22:(double)m22
{
    self = [super init];
    if (self)
    {
        self.m[0] = m00;
        self.m[1] = m01;
        self.m[2] = m02;
        self.m[3] = m10;
        self.m[4] = m11;
        self.m[5] = m12;
        self.m[6] = m20;
        self.m[7] = m21;
        self.m[8] = m22;
    }
    return self;
}

- (id)initWithMatrix3x3d:(Matrix3x3d*)o
{
    self = [super init];
    if (self)
    {
        for (int i = 0; i < 9; i++)
        {
            self.m[i] = o.m[i];
        }
    }
    return self;
}

- (void)set:(double)m00 m01:(double)m01 m02:(double)m02 m10:(double)m10 m11:(double)m11 m12:(double)m12 m20:(double)m20 m21:(double)m21 m22:(double)m22
{
    self.m[0] = m00;
    self.m[1] = m01;
    self.m[2] = m02;
    self.m[3] = m10;
    self.m[4] = m11;
    self.m[5] = m12;
    self.m[6] = m20;
    self.m[7] = m21;
    self.m[8] = m22;
}

- (void)set:(Matrix3x3d*)o
{
    for (int i = 0; i < 9; i++)
    {
        self.m[i] = o.m[i];
    }
}

- (void)setZero
{
    for (int i = 0; i < 9; i++)
    {
        self.m[i] = 0;
    }
}

- (void)setIdentity
{
    self.m[0] = 1;
    self.m[1] = 0;
    self.m[2] = 0;
    self.m[3] = 0;
    self.m[4] = 1;
    self.m[5] = 0;
    self.m[6] = 0;
    self.m[7] = 0;
    self.m[8] = 1;
}

- (void)setSameDiagonal:(double)d
{
    self.m[0] = d;
    self.m[4] = d;
    self.m[8] = d;
}

- (double)get:(int)row col:(int)col
{
    return self.m[(3 * row + col)];
}

- (void)set:(int)row col:(int)col value:(double)value
{
    self.m[(3 * row + col)] = value;
}

- (void)getColumn:(int)col v:(Vector3d*)v
{
    v.x = self.m[col];
    v.y = self.m[col + 3];
    v.z = self.m[col + 6];
}

- (void)setColumn:(int)col v:(Vector3d*)v
{
    self.m[col] = v.x;
    self.m[col + 3] = v.y;
    self.m[col + 6] = v.z;
}

- (void)scale:(double)s
{
    for (int i = 0; i < 9; i++)
    {
        self.m[i] *= s;
    }
}

- (void)plusEquals:(Matrix3x3d*)b
{
    for (int i = 0; i < 9; i++)
    {
        self.m[i] += b.m[i];
    }
}

- (void)minusEquals:(Matrix3x3d*)b
{
    for (int i = 0; i < 9; i++)
    {
        self.m[i] -= b.m[i];
    }
}

- (void)transpose
{
    double tmp = self.m[1];
    self.m[1] = self.m[3];
    self.m[3] = tmp;
    tmp = self.m[2];
    self.m[2] = self.m[6];
    self.m[6] = tmp;
    tmp = self.m[5];
    self.m[5] = self.m[7];
    self.m[7] = tmp;
}

- (void)transpose:(Matrix3x3d*)result
{
    double m1 = self.m[1];
    double m2 = self.m[2];
    double m5 = self.m[5];
    result.m[0] = self.m[0];
    result.m[1] = self.m[3];
    result.m[2] = self.m[6];
    result.m[3] = m1;
    result.m[4] = self.m[4];
    result.m[5] = self.m[7];
    result.m[6] = m2;
    result.m[7] = m5;
    result.m[8] = self.m[8];
}

+ (void)add:(Matrix3x3d*)a b:(Matrix3x3d*)b result:(Matrix3x3d*)result
{
    for (int i = 0; i < 9; i++)
    {
        result.m[i] = a.m[i] + b.m[i];
    }
}

+ (void)mult:(Matrix3x3d*)a b:(Matrix3x3d*)b result:(Matrix3x3d*)result
{
    [result set:a.m[0] * b.m[0] + a.m[1] * b.m[3] + a.m[2] * b.m[6] m01:a.m[0] * b.m[1] + a.m[1] * b.m[4] + a.m[2] * b.m[7] m02:a.m[0] * b.m[2] + a.m[1] * b.m[5] + a.m[2] * b.m[8] m10:a.m[3] * b.m[0] + a.m[4] * b.m[3] + a.m[5] * b.m[6] m11:a.m[3] * b.m[1] + a.m[4] * b.m[4] + a.m[5] * b.m[7] m12:a.m[3] * b.m[2] + a.m[4] * b.m[5] + a.m[5] * b.m[8] m20:a.m[6] * b.m[0] + a.m[7] * b.m[3] + a.m[8] * b.m[6] m21:a.m[6] * b.m[1] + a.m[7] * b.m[4] + a.m[8] * b.m[7] m22:a.m[6] * b.m[2] + a.m[7] * b.m[5] + a.m[8] * b.m[8]];
}

+ (void)mult:(Matrix3x3d*)a v:(Vector3d*)v result:(Vector3d*)result
{
    [result set:a.m[0] * v.x + a.m[1] * v.y + a.m[2] * v.z y:a.m[3] * v.x + a.m[4] * v.y + a.m[5] * v.z z:a.m[6] * v.x + a.m[7] * v.y + a.m[8] * v.z];
}

- (double)determinant
{
    return [self get:0 col:0] * ([self get:1 col:1] * [self get:2 col:2] - [self get:2 col:1] * [self get:1 col:2]) - [self get:0 col:1] * ([self get:1 col:0] * [self get:2 col:2] - [self get:1 col:2] * [self get:2 col:0]) + [self get:0 col:2] * ([self get:1 col:0] * [self get:2 col:1] - [self get:1 col:1] * [self get:2 col:0]);
}

- (bool)invert:(Matrix3x3d*)result
{
    double d = [self determinant];
    if (d == 0.0) {
        return false;
    }
    
    double invdet = 1.0 / d;
    
    [result set:(self.m[4] * self.m[8] - self.m[7] * self.m[5]) * invdet m01:-(self.m[1] * self.m[8] - self.m[2] * self.m[7]) * invdet m02:(self.m[1] * self.m[5] - self.m[2] * self.m[4]) * invdet m10:-(self.m[3] * self.m[8] - self.m[5] * self.m[6]) * invdet m11:(self.m[0] * self.m[8] - self.m[2] * self.m[6]) * invdet m12:-(self.m[0] * self.m[5] - self.m[3] * self.m[2]) * invdet m20:(self.m[3] * self.m[7] - self.m[6] * self.m[4]) * invdet m21:-(self.m[0] * self.m[7] - self.m[6] * self.m[1]) * invdet m22:(self.m[0] * self.m[4] - self.m[3] * self.m[1]) * invdet];
    
    return true;
}

@end
