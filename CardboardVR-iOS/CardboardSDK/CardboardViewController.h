//
//  CardboardViewController.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-09-04.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>


class EyeTransform;
class HeadTransform;
class Viewport;


@protocol StereoRendererDelegate

- (void)setupRendererWithView:(GLKView *)GLView;
- (void)shutdownRendererWithView:(GLKView *)GLView;
- (void)renderViewDidChangeSize:(CGSize)size;

- (void)prepareNewFrameWithHeadTransform:(HeadTransform *)headTransform;
- (void)drawEyeWithTransform:(EyeTransform *)eyeTransform;
- (void)drawEyeWithTransformA:(EyeTransform *)eyeTransform;
- (void)drawEyeWithTransformB:(EyeTransform *)eyeTransform;
- (void)finishFrameWithViewport:(Viewport *)viewPort;

@end


@interface CardboardViewController : GLKViewController

@property (nonatomic) id <StereoRendererDelegate> stereoRendererDelegate;
@property (nonatomic) BOOL isVRModeEnabled;

@end
