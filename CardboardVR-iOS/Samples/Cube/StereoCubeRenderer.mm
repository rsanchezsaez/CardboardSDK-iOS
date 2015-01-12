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

#import "DebugUtils.h"

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

- (void)drawEyeWithTransform:(EyeTransform *)eyeTransform
{
    [self.cubeRenderer updateTimeWithDelta:1/60.0f];
    [self.cubeRenderer render];
    printGLError();
}

- (void)drawEyeWithTransformA:(EyeTransform *)eyeTransform
{
    [self.cubeRenderer updateTimeWithDelta:1/60.0f];
    [self.cubeRenderer renderA];
    printGLError();
}

- (void)drawEyeWithTransformB:(EyeTransform *)eyeTransform
{
    [self.cubeRenderer updateTimeWithDelta:1/60.0f];
    [self.cubeRenderer renderB];
    printGLError();
}

- (void)finishFrameWithViewport:(Viewport *)viewPort
{
}



@end
