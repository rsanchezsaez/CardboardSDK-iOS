//
//  GLCubeRenderer.m
//  CardboardVR-iOS
//
//  Created by Ricardo Sánchez-Sáez on 07/01/2015.
//  Copyright (c) 2015 Peter Tribe. All rights reserved.
//

#import "GLCubeRenderer.h"

#import <GLKit/GLKit.h>


#define BUFFER_OFFSET(i) ((char *)NULL + (i))


@interface GLCubeRenderer ()

@property (nonatomic) EAGLContext *context;
@property (nonatomic) GLKBaseEffect *effect;
@property (nonatomic) GLuint vertexBuffer;
@property (nonatomic) float currentRotation;

@end


@implementation GLCubeRenderer

- (instancetype)initWithContext:(EAGLContext *)context
{
    self = [super init];
    if (!self) { return nil; }
    
    self.context = context;
    
    [self setupGL];
    
    return self;
}

- (void)setupGL
{
    const GLfloat cubeVertexData[216] =
    {
        //x     y      z              nx     ny     nz
        1.0f, -1.0f, -1.0f,         1.0f,  0.0f,  0.0f,
        1.0f,  1.0f, -1.0f,         1.0f,  0.0f,  0.0f,
        1.0f, -1.0f,  1.0f,         1.0f,  0.0f,  0.0f,
        1.0f, -1.0f,  1.0f,         1.0f,  0.0f,  0.0f,
        1.0f,  1.0f,  1.0f,         1.0f,  0.0f,  0.0f,
        1.0f,  1.0f, -1.0f,         1.0f,  0.0f,  0.0f,
        
        1.0f,  1.0f, -1.0f,         0.0f,  1.0f,  0.0f,
        -1.0f,  1.0f, -1.0f,         0.0f,  1.0f,  0.0f,
        1.0f,  1.0f,  1.0f,         0.0f,  1.0f,  0.0f,
        1.0f,  1.0f,  1.0f,         0.0f,  1.0f,  0.0f,
        -1.0f,  1.0f, -1.0f,         0.0f,  1.0f,  0.0f,
        -1.0f,  1.0f,  1.0f,         0.0f,  1.0f,  0.0f,
        
        -1.0f,  1.0f, -1.0f,        -1.0f,  0.0f,  0.0f,
        -1.0f, -1.0f, -1.0f,        -1.0f,  0.0f,  0.0f,
        -1.0f,  1.0f,  1.0f,        -1.0f,  0.0f,  0.0f,
        -1.0f,  1.0f,  1.0f,        -1.0f,  0.0f,  0.0f,
        -1.0f, -1.0f, -1.0f,        -1.0f,  0.0f,  0.0f,
        -1.0f, -1.0f,  1.0f,        -1.0f,  0.0f,  0.0f,
        
        -1.0f, -1.0f, -1.0f,         0.0f, -1.0f,  0.0f,
        1.0f, -1.0f, -1.0f,         0.0f, -1.0f,  0.0f,
        -1.0f, -1.0f,  1.0f,         0.0f, -1.0f,  0.0f,
        -1.0f, -1.0f,  1.0f,         0.0f, -1.0f,  0.0f,
        1.0f, -1.0f, -1.0f,         0.0f, -1.0f,  0.0f,
        1.0f, -1.0f,  1.0f,         0.0f, -1.0f,  0.0f,
        
        1.0f,  1.0f,  1.0f,         0.0f,  0.0f,  1.0f,
        -1.0f,  1.0f,  1.0f,         0.0f,  0.0f,  1.0f,
        1.0f, -1.0f,  1.0f,         0.0f,  0.0f,  1.0f,
        1.0f, -1.0f,  1.0f,         0.0f,  0.0f,  1.0f,
        -1.0f,  1.0f,  1.0f,         0.0f,  0.0f,  1.0f,
        -1.0f, -1.0f,  1.0f,         0.0f,  0.0f,  1.0f,
        
        1.0f, -1.0f, -1.0f,         0.0f,  0.0f, -1.0f,
        -1.0f, -1.0f, -1.0f,         0.0f,  0.0f, -1.0f,
        1.0f,  1.0f, -1.0f,         0.0f,  0.0f, -1.0f,
        1.0f,  1.0f, -1.0f,         0.0f,  0.0f, -1.0f,
        -1.0f, -1.0f, -1.0f,         0.0f,  0.0f, -1.0f,
        -1.0f,  1.0f, -1.0f,         0.0f,  0.0f, -1.0f
    };
    
    [EAGLContext setCurrentContext:self.context];
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    glEnable(GL_DEPTH_TEST);
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(cubeVertexData), cubeVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT,
                          GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT,
                          GL_FALSE, 24, BUFFER_OFFSET(12));
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    
    self.effect = nil;
}

- (void)updateProjectionMatrixAspectWithRect:(CGRect)rect
{
    float aspect = fabsf(rect.size.width /
                         rect.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(50.0f), aspect, 0.1f, 100.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
}

- (void)updateTimeWithDelta:(NSTimeInterval)timeSinceLastUpdate
{
    GLKMatrix4 modelMatrix = GLKMatrix4MakeTranslation(0.0f,0.0f,-7.0f);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, _currentRotation, 1.0f,1.0f,0.7f);
    self.effect.transform.modelviewMatrix = modelMatrix;
    
    _currentRotation += timeSinceLastUpdate * 1.0f;
}

- (void)render
{
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
}

@end
