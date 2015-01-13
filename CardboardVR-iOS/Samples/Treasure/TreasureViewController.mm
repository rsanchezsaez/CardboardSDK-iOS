//
//  TreasureViewController.m
//  CardboardVR-iOS
//
//  Created by Ricardo Sánchez-Sáez on 13/01/2015.
//  Copyright (c) 2015 Peter Tribe. All rights reserved.
//

#import "TreasureViewController.h"

#import "CardboardSDK.h"


@interface TreasureRenderer : NSObject

- (instancetype)initWithContext:(EAGLContext *)context;

@end


@implementation TreasureRenderer

- (instancetype)initWithContext:(EAGLContext *)context
{
    self = [super init];
    if (!self) { return nil; }
    
    return self;
}

@end


@interface StereoTreasureRenderer : NSObject <StereoRendererDelegate>

@property (nonatomic) TreasureRenderer *treasureRenderer;

@end


@implementation StereoTreasureRenderer

- (void)setupRendererWithView:(GLKView *)GLView
{
    self.treasureRenderer = [[TreasureRenderer alloc] initWithContext:GLView.context];
}

- (void)shutdownRendererWithView:(GLKView *)GLView
{
}

- (void)renderViewDidChangeSize:(CGSize)size
{
}

- (void)prepareNewFrameWithHeadTransform:(HeadTransform *)headTransform
{
}

- (void)drawEyeWithTransform:(EyeTransform *)eyeTransform eyeType:(EyeParamsType)eyeType
{
}

- (void)finishFrameWithViewport:(Viewport *)viewPort
{
}


@end


@interface TreasureViewController()

@property (nonatomic) StereoTreasureRenderer *stereoTreasureRenderer;

@end


@implementation TreasureViewController

- (instancetype)init
{
    self = [super init];
    if (!self) {return nil; }
    
    self.stereoTreasureRenderer = [StereoTreasureRenderer new];
    
    return self;
}

@end
