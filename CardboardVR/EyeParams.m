//
//  EyeParams.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "EyeParams.h"

@interface EyeParams ()

@property (nonatomic, assign) EyeParamsEyeType eye;
@property (nonatomic, strong) Viewport *viewport;
@property (nonatomic, strong) FieldOfView *fov;
@property (nonatomic, strong) EyeTransform *eyeTransform;

@end

@implementation EyeParams

- (id)initWithEye:(EyeParamsEyeType)eye
{
    self = [super init];
    if (self)
    {
        self.eye = eye;
        self.viewport = [[Viewport alloc] init];
        self.fov = [[FieldOfView alloc] init];
        self.eyeTransform = [[EyeTransform alloc] init];
    }
    return self;
}

- (EyeParamsEyeType)getEye
{
    return self.eye;
}

- (Viewport*)getViewport
{
    return self.viewport;
}

- (FieldOfView*)getFov
{
    return self.fov;
}

- (EyeTransform*)getTransform
{
    return self.eyeTransform;
}

@end
