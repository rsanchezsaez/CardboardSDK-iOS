//
//  CardboardViewController.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-09-04.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "EyeParams.h"

class EyeTransform;
class HeadTransform;
class Viewport;


@protocol StereoRendererDelegate <NSObject>

- (void)setupRendererWithView:(GLKView *)GLView;
- (void)shutdownRendererWithView:(GLKView *)GLView;
- (void)renderViewDidChangeSize:(CGSize)size;

- (void)prepareNewFrameWithHeadTransform:(HeadTransform *)headTransform;
- (void)drawEyeWithTransform:(EyeTransform *)eyeTransform eyeType:(EyeParamsType)eyeType;
- (void)finishFrameWithViewport:(Viewport *)viewPort;

@optional

- (void)magneticTriggerPressed;

@end


@interface CardboardViewController : GLKViewController

@property (nonatomic) id <StereoRendererDelegate> stereoRendererDelegate;
@property (nonatomic) BOOL isVRModeEnabled;

@end
