//
//  StereoCubeRenderer.m
//  CardboardVR-iOS
//
//  Created by Ricardo Sánchez-Sáez on 12/01/2015.
//  Copyright (c) 2015 Peter Tribe. All rights reserved.
//

#import "StereoCubeRenderer.h"

#import "CardboardSDK.h"
#import "GLCubeRenderer.h"


@interface StereoCubeRenderer ()

@property (nonatomic) GLCubeRenderer *cubeRenderer;

@end


@implementation StereoCubeRenderer

- (void)setupRendererWithView:(GLKView *)GLView
{
    self.cubeRenderer = [[GLCubeRenderer alloc] initWithContext:GLView.context];
}

- (void)shutdownRendererWithView:(GLKView *)GLView
{
}

- (void)renderViewDidChangeSize:(CGSize)size
{
    [self.cubeRenderer updateProjectionMatrixAspectWithSize:size];
}

- (void)prepareNewFrameWithHeadTransform:(HeadTransform *)headTransform
{
}

- (void)drawEyeWithTransform:(EyeTransform *)eyeTransform eyeType:(EyeParamsType)eyeType
{
    [self.cubeRenderer updateTimeWithDelta:1/60.0f];
    // [self.cubeRenderer render];
    if (eyeType == EyeParamsTypeMonocular)
    {
        [self.cubeRenderer render];
    }
    else if (eyeType == EyeParamsTypeLeft)
    {
        [self.cubeRenderer renderA];
    }
    else if (eyeType == EyeParamsTypeRight)
    {
        [self.cubeRenderer renderB];
    }
    checkGLError();
}

- (void)finishFrameWithViewport:(Viewport *)viewPort
{
}



@end
