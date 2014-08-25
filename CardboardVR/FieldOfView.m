//
//  FieldOfView.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "FieldOfView.h"

@interface FieldOfView ()

@property (nonatomic, assign) float left;
@property (nonatomic, assign) float right;
@property (nonatomic, assign) float bottom;
@property (nonatomic, assign) float top;

@end

@implementation FieldOfView

- (id)initWithLeft:(float)left right:(float)right bottom:(float)bottom top:(float)top
{
    self = [super init];
    if (self)
    {
        self.left = left;
        self.right = right;
        self.bottom = bottom;
        self.top = top;
    }
    return self;
}

- (id)initWitFieldOfView:(FieldOfView*)other
{
    self = [super init];
    if (self)
    {
        self.left = [other getLeft];
        self.right = [other getRight];
        self.bottom = [other getBottom];
        self.top = [other getTop];
    }
    return self;
}

- (void)setLeft:(float)left
{
    self.left = left;
}

- (float)getLeft
{
    return self.left;
}

- (void)setRight:(float)right
{
    self.right = right;
}

- (float)getRight
{
    return self.right;
}

- (void)setBottom:(float)bottom
{
    self.bottom = bottom;
}

- (float)getBottom
{
    return self.bottom;
}

- (void)setTop:(float)top
{
    self.top = top;
}

- (float)getTop
{
    return self.top;
}

- (GLKMatrix4)frustumM:(float)left right:(float)right bottom:(float)bottom top:(float)top near:(float)near far:(float)far
{
    float r_width  = 1.0f / (right - left);
    float r_height = 1.0f / (top - bottom);
    float r_depth  = 1.0f / (near - far);
    float x = 2.0f * (near * r_width);
    float y = 2.0f * (near * r_height);
    float A = (right + left) * r_width;
    float B = (top + bottom) * r_height;
    float C = (far + near) * r_depth;
    float D = 2.0f * (far * near * r_depth);
    GLKMatrix4 frustum;
    frustum.m[0] = x;
    frustum.m[1] = 0.0f;
    frustum.m[2] = 0.0f;
    frustum.m[3] = 0.0f;
    frustum.m[4] = 0.0f;
    frustum.m[5] = y;
    frustum.m[6] = 0.0f;
    frustum.m[7] = 0.0f;
    frustum.m[8] = A;
    frustum.m[9] = B;
    frustum.m[10] = C;
    frustum.m[11] = -1.0f;
    frustum.m[12] = 0.0f;
    frustum.m[13] = 0.0f;
    frustum.m[14] = D;
    frustum.m[15] = 0.0f;
    return frustum;
}

- (GLKMatrix4)toPerspectiveMatrix:(float)near far:(float)far
{
    float l = -tanf(self.left * (M_PI / 180.0f)) * near;
    float r = tanf(self.right * (M_PI / 180.0f)) * near;
    float b = -tanf(self.bottom * (M_PI / 180.0f)) * near;
    float t = tanf(self.top * (M_PI / 180.0f)) * near;
    return [self frustumM:l right:r bottom:b top:t near:near far:far];
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
    if (![other isKindOfClass:[FieldOfView class]])
    {
        return false;
    }
    FieldOfView *o = (FieldOfView *)other;
    return (self.left == [o getLeft]) && (self.right == [o getRight]) && (self.bottom == [o getBottom]) && (self.top == [o getTop]);
}

- (NSString *)toString
{
    return [NSString stringWithFormat:@"FieldOfView {left:%f right:%f bottom:%f top:%f}", self.left, self.right, self.bottom, self.top];
}

@end
