//
//  GLCubeViewController.m
//  CardboardVR-iOS
//
//  Created by Ricardo Sánchez-Sáez on 07/01/2015.
//  Copyright (c) 2015 Peter Tribe. All rights reserved.
//

#import "GLCubeViewController.h"

#import "GLCubeRenderer.h"


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
    self.view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    self.cubeRenderer = [[GLCubeRenderer alloc] initWithContext:self.view.context];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self.cubeRenderer updateProjectionMatrixAspectWithRect:self.view.bounds];
}

- (void)update
{
    [self.cubeRenderer updateTimeWithDelta:self.timeSinceLastUpdate];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self.cubeRenderer render];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.paused = !self.paused;
}


@end
