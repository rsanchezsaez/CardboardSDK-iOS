//
//  GLCubeViewController.m
//  CardboardVR-iOS
//
//  Created by Ricardo Sánchez-Sáez on 07/01/2015.
//  Copyright (c) 2015 Peter Tribe. All rights reserved.
//

#import "GLCubeViewController.h"

#import "GLCubeRenderer.h"

#import <OpenGLES/ES2/glext.h>


@interface GLCubeViewController ()

@property (nonatomic) GLKView *view;
@property (nonatomic) GLCubeRenderer *cubeRenderer;

@end


@implementation GLCubeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.preferredFramesPerSecond = 60;
    self.view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.view.context)
    {
        NSLog(@"Failed to create OpenGL ES 2.0 context");
    }
    self.view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
    self.cubeRenderer = [[GLCubeRenderer alloc] initWithContext:self.view.context];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self.cubeRenderer updateProjectionMatrixAspectWithSize:self.view.bounds.size];
}

- (void)update
{
    [self.cubeRenderer updateTimeWithDelta:self.timeSinceLastUpdate];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
//    glInsertEventMarkerEXT(0, "com.apple.GPUTools.event.debug-frame");

    [self.cubeRenderer render];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.paused = !self.paused;
}


@end
