//
//  EyeTransform.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "EyeTransform.h"

@interface EyeTransform ()

@property (nonatomic, strong) EyeParams *eyeParams;
@property (nonatomic, assign) GLKMatrix4 eyeView;
@property (nonatomic, assign) GLKMatrix4 perspective;

@end

@implementation EyeTransform

- (id)initWithEyeParams:(EyeParams*)params
{
    self = [super init];
    if (self)
    {
        self.eyeParams = params;
        self.eyeView = GLKMatrix4Identity;
        self.perspective = GLKMatrix4Identity;    }
    return self;
}

- (GLKMatrix4)getEyeView
{
    return self.eyeView;
}

- (GLKMatrix4)getPerspective
{
    return self.perspective;
}

- (void)setPerspective:(GLKMatrix4)perspective
{
    self.perspective = perspective;
}

- (EyeParams*)getParams
{
    return self.eyeParams;
}

@end
