//
//  HeadTransform.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-24.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "HeadTransform.h"

@interface HeadTransform ()

@property (nonatomic,assign) GLKMatrix4 headView;

@end

@implementation HeadTransform

const float GIMBAL_LOCK_EPSILON = 0.01f;

- (id)init
{
    self = [super init];
    if (self)
    {
        self.headView = GLKMatrix4Identity;
    }
    return self;
}

- (GLKMatrix4)getHeadView
{
    return self.headView;
}

- (GLKVector3)getTranslation
{
    return GLKVector3Make(self.headView.m[12], self.headView.m[13], self.headView.m[14]);
}

- (GLKVector3)getForwardVector
{
    return GLKVector3Make(-self.headView.m[8], -self.headView.m[9], -self.headView.m[10]);
}

- (GLKVector3)getUpVector
{
    return GLKVector3Make(self.headView.m[4], self.headView.m[5], self.headView.m[6]);
}

- (GLKVector3)getRightVector
{
    return GLKVector3Make(self.headView.m[0], self.headView.m[1], self.headView.m[2]);
}

- (GLKQuaternion)getQuaternion
{
    float t = self.headView.m[0] + self.headView.m[5] + self.headView.m[10];
    float s, w, x, y, z;
    if (t >= 0.0f) {
        s = sqrtf(t + 1.0f);
        w = 0.5F * s;
        s = 0.5F / s;
        x = (self.headView.m[9] - self.headView.m[6]) * s;
        y = (self.headView.m[2] - self.headView.m[8]) * s;
        z = (self.headView.m[4] - self.headView.m[1]) * s;
    }
    else
    {
        if ((self.headView.m[0] > self.headView.m[5]) && (self.headView.m[0] > self.headView.m[10])) {
            s = sqrtf(1.0f + self.headView.m[0] - self.headView.m[5] - self.headView.m[10]);
            x = s * 0.5f;
            s = 0.5f / s;
            y = (self.headView.m[4] + self.headView.m[1]) * s;
            z = (self.headView.m[2] + self.headView.m[8]) * s;
            w = (self.headView.m[9] - self.headView.m[6]) * s;
        }
        else
        {
            if (self.headView.m[5] > self.headView.m[10]) {
                s = sqrtf(1.0f + self.headView.m[5] - self.headView.m[0] - self.headView.m[10]);
                y = s * 0.5f;
                s = 0.5f / s;
                x = (self.headView.m[4] + self.headView.m[1]) * s;
                z = (self.headView.m[9] + self.headView.m[6]) * s;
                w = (self.headView.m[2] - self.headView.m[8]) * s;
            }
            else {
                s = sqrtf(1.0f + self.headView.m[10] - self.headView.m[0] - self.headView.m[5]);
                z = s * 0.5f;
                s = 0.5f / s;
                x = (self.headView.m[2] + self.headView.m[8]) * s;
                y = (self.headView.m[9] + self.headView.m[6]) * s;
                w = (self.headView.m[4] - self.headView.m[1]) * s;
            }
        }
    }
    return GLKQuaternionMake(x, y, z, w);
}

- (GLKVector3)getEulerAngles
{
    float yaw, roll, pitch = asinf(self.headView.m[6]);
    if (sqrtf(1.0f - self.headView.m[6] * self.headView.m[6]) >= 0.01f)
    {
        yaw = atan2f(-self.headView.m[2], self.headView.m[10]);
        roll = atan2f(-self.headView.m[4], self.headView.m[5]);
    }
    else
    {
        yaw = 0.0f;
        roll = atan2f(self.headView.m[1], self.headView.m[0]);
    }
    return GLKVector3Make(-pitch, -yaw, -roll);
}

@end
