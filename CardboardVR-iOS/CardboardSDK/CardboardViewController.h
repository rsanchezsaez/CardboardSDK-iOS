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

- (void)prepareNewFrameWithHeadTransform:(HeadTransform *)headTransform;
- (void)drawEyeWithTransform:(EyeTransform *)eyeTransform;
- (void)finishFrameWithViewport:(Viewport *)viewPort;

- (void)renderViewDidChangeSize:(CGSize)size;

- (void)setupRenderer;
- (void)shutdownRenderer;

@end


@interface CardboardViewController : GLKViewController

@property (nonatomic) BOOL isVRModeEnabled;

- (void)onCardboardTrigger:(id)sender;

@end
