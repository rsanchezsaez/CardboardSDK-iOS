//
//  GLCubeRenderer.m
//  CardboardVR-iOS
//
//  Created by Ricardo Sánchez-Sáez on 07/01/2015.
//  Copyright (c) 2015 Peter Tribe. All rights reserved.
//

#import "GLCubeRenderer.h"

#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>


#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

@interface GLCubeRenderer ()
{
    GLuint _program;

    GLuint _vertexArray;
    GLuint _vertexBuffer;
    float _currentRotation;
    
    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
}

@property (nonatomic) EAGLContext *context;

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
    
    [self loadShaders];

    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);

    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(cubeVertexData), cubeVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
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
}

- (void)updateProjectionMatrixAspectWithSize:(CGSize)size
{
    float aspect = fabsf(size.width /
                         size.height);
    _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(50.0f), aspect, 0.1f, 100.0f);
}

- (void)updateTimeWithDelta:(NSTimeInterval)timeSinceLastUpdate
{
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -7.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _currentRotation, 0.0f, 1.0f, 0.0f);
    
    // Compute the model view matrix for the object rendered with ES2
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _currentRotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(_projectionMatrix, modelViewMatrix);
    
    _currentRotation += timeSinceLastUpdate * 1.0f;
}

- (void)render
{
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
}

- (void)renderA
{
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
}

- (void)renderB
{
    glClearColor(0.0f, 0.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"CubeShader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"CubeShader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
