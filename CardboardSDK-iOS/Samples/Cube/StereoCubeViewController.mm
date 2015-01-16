//
//  StereoCubeRenderer.m
//  CardboardVR-iOS
//
//  Created by Ricardo Sánchez-Sáez on 12/01/2015.
//  Copyright (c) 2015 Peter Tribe. All rights reserved.
//

#import "StereoCubeViewController.h"

#import "CardboardSDK.h"
#import "GLCubeRenderer.h"


@interface StereoCubeRenderer : NSObject <StereoRendererDelegate>

@property (nonatomic) GLCubeRenderer *cubeRenderer;

@end


@implementation StereoCubeRenderer

- (void)setupRendererWithView:(GLKView *)GLView
{
    self.cubeRenderer = [[GLCubeRenderer alloc] initWithContext:GLView.context];
    [self.cubeRenderer updateProjectionMatrixAspectWithSize:GLView.bounds.size];
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
    [self.cubeRenderer render];
    checkGLError();
}

- (void)finishFrameWithViewport:(Viewport *)viewPort
{
}

@end


@interface StereoCubeViewController()

@property (nonatomic) StereoCubeRenderer *stereoCubeRenderer;

@end


@implementation StereoCubeViewController

- (instancetype)init
{
    self = [super init];
    if (!self) {return nil; }
    
    self.stereoCubeRenderer = [StereoCubeRenderer new];
    self.stereoRendererDelegate = self.stereoCubeRenderer;
    
    return self;
}

@end
