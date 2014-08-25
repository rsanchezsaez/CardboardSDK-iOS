//
//  Vector3d.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-23.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "Vector3d.h"

@implementation Vector3d

- (id)init
{
    self = [super init];
    if (self)
    {
        [self setZero];
    }
    return self;
}

- (id)initWithX:(double)x y:(double)y z:(double)z
{
    self = [super init];
    if (self)
    {
        [self set:x y:y z:z];
    }
    return self;
}

- (void)set:(double)x y:(double)y z:(double)z
{
    self.x = x;
    self.y = y;
    self.z = z;
}

- (void)setComponent:(int)i val:(double)val
{
    if (i == 0)
    {
        self.x = val;
    }
    else if (i == 1)
    {
        self.y = val;
    }
    else
    {
        self.z = val;
    }
}

- (void)setZero
{
    [self set:0 y:0 z:0];
}

- (void)set:(Vector3d*)other
{
    [self set:other.x y:other.y z:other.z];
}

- (void)scale:(double)s
{
    self.x *= s;
    self.y *= s;
    self.z *= s;
}

- (void)normalize
{
    double d = [self length];
    if (d != 0.0) {
        [self scale:1.0 / d];
    }
}

+ (double)dot:(Vector3d*)a b:(Vector3d*)b
{
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

- (double)length
{
    return sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
}

- (bool)sameValues:(Vector3d*)other
{
    return (self.x == other.x) && (self.y == other.y) && (self.z == other.z);
}

+ (void)sub:(Vector3d*)a b:(Vector3d*)b result:(Vector3d*)result
{
    [result set:a.x - b.x y:a.y - b.y z:a.z - b.z];
}

+ (void)cross:(Vector3d*)a b:(Vector3d*)b result:(Vector3d*)result
{
    [result set:a.y * b.z - a.z * b.y y:a.z * b.x - a.x * b.z z:a.x * b.y - a.y * b.x];
}

+ (void)ortho:(Vector3d*)v result:(Vector3d*)result
{
    int k = [self largestAbsComponent:v] - 1;
    if (k < 0)
    {
        k = 2;
    }
    [result setZero];
    [result setComponent:k val:1.0];
    [self cross:v b:result result:result];
    [result normalize];
}

+ (int)largestAbsComponent:(Vector3d*)v
{
    double xAbs = abs(v.x);
    double yAbs = abs(v.y);
    double zAbs = abs(v.z);
    if (xAbs > yAbs) {
        if (xAbs > zAbs) {
            return 0;
        }
        return 2;
    }
    if (yAbs > zAbs) {
        return 1;
    }
    return 2;
}

@end
