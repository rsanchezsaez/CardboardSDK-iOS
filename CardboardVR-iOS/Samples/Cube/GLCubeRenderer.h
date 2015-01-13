//
//  GLCubeRenderer.h
//  CardboardVR-iOS
//
//  Created by Ricardo Sánchez-Sáez on 07/01/2015.
//  Copyright (c) 2015 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class EAGLContext;


@interface GLCubeRenderer : NSObject

- (instancetype)initWithContext:(EAGLContext *)context;

- (void)updateProjectionMatrixAspectWithSize:(CGSize)size;
- (void)updateTimeWithDelta:(NSTimeInterval)timeSinceLastUpdate;
- (void)render;

@end
