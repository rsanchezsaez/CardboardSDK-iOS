//
//  DistortionRenderer.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EyeParams.h"
//#import "Distortion.h"
#import "HeadMountedDisplay.h"
//#import "DistortionMesh.h"
//#import "EyeViewport.h"
//#import "ProgramHolder.h"

@interface DistortionRenderer : NSObject

- (void)beforeDrawFrame;
- (void)afterDrawFrame;
- (void)setResolutionScale:(float)scale;
- (void)onProjectionChanged:(HeadMountedDisplay*)hmd leftEye:(EyeParams*)leftEye rightEye:(EyeParams*)rightEye zNear:(float)zNear zFar:(float)zFar;
+ (float)clamp:(float)val min:(float)min max:(float)max;

@end
