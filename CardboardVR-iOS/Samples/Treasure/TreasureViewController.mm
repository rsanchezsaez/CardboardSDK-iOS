//
//  TreasureViewController.m
//  CardboardVR-iOS
//
//  Created by Ricardo Sánchez-Sáez on 13/01/2015.
//  Copyright (c) 2015 Peter Tribe. All rights reserved.
//

#import "TreasureViewController.h"

#import "CardboardSDK.h"


@interface TreasureRenderer : NSObject <StereoRendererDelegate>
{
    GLuint _cubeVertexArray;
    GLuint _cubeVertexBuffer;
    GLuint _cubeColorBuffer;
    GLuint _cubeFoundColorBuffer;
    GLuint _cubeNormalBuffer;

    GLuint _floorVertexArray;
    GLuint _floorVertexBuffer;
    GLuint _floorColorBuffer;
    GLuint _floorNormalBuffer;

    GLuint _cubeProgram;
    GLuint _floorProgram;
    
    GLint _cubePositionParam;
    GLint _cubeNormalParam;
    GLint _cubeColorParam;
    
    GLint _cubeModelParam;
    GLint _cubeModelViewParam;
    GLint _cubeModelViewProjectionParam;
    GLint _cubeLightPositionParam;

    GLint _floorPositionParam;
    GLint _floorNormalParam;
    GLint _floorColorParam;
    
    GLint _floorModelParam;
    GLint _floorModelViewParam;
    GLint _floorModelViewProjectionParam;
    GLint _floorLightPositionParam;
    
    GLKMatrix4 _modelCube;
    GLKMatrix4 _camera;
    GLKMatrix4 _view;
    GLKMatrix4 _modelViewProjection;
    GLKMatrix4 _modelView;
    GLKMatrix4 _modelFloor;
    GLKMatrix4 _headView;
    
    float _zNear;
    float _zFar;
    
    float _cameraZ;
    float _timeDelta;
    
    float _yawLimit;
    float _pitchLimit;
    
    int _coordsPerVertex;
    
    GLKVector4 _lightPositionInWorldSpace;
    GLKVector4 _lightPositionInEyeSpace;
    
    int _score;
    float _objectDistance;
    float _floorDepth;
}

@end


@implementation TreasureRenderer

- (instancetype)init
{
    self = [super init];
    if (!self) { return nil; }
    
    _objectDistance = 12.0f;
    _floorDepth = 20.0f;
    
    _zNear = 0.1f;
    _zFar = 100.0f;
    
    _cameraZ = 0.01f;
    _timeDelta = 0.3f;
    
    _yawLimit = 0.12f;
    _pitchLimit = 0.12f;
    
    _coordsPerVertex = 3;
    
    // We keep the light always position just above the user.
    _lightPositionInWorldSpace = GLKVector4Make(0.0f, 2.0f, 0.0f, 1.0f);
    _lightPositionInEyeSpace = GLKVector4Make(0.0f, 0.0f, 0.0f, 0.0f);

    return self;
}

- (void)setupRendererWithView:(GLKView *)GLView
{
    const GLfloat cubeVertices[] = {
        // Front face
        -1.0f, 1.0f, 1.0f,
        -1.0f, -1.0f, 1.0f,
        1.0f, 1.0f, 1.0f,
        -1.0f, -1.0f, 1.0f,
        1.0f, -1.0f, 1.0f,
        1.0f, 1.0f, 1.0f,
        
        // Right face
        1.0f, 1.0f, 1.0f,
        1.0f, -1.0f, 1.0f,
        1.0f, 1.0f, -1.0f,
        1.0f, -1.0f, 1.0f,
        1.0f, -1.0f, -1.0f,
        1.0f, 1.0f, -1.0f,
        
        // Back face
        1.0f, 1.0f, -1.0f,
        1.0f, -1.0f, -1.0f,
        -1.0f, 1.0f, -1.0f,
        1.0f, -1.0f, -1.0f,
        -1.0f, -1.0f, -1.0f,
        -1.0f, 1.0f, -1.0f,
        
        // Left face
        -1.0f, 1.0f, -1.0f,
        -1.0f, -1.0f, -1.0f,
        -1.0f, 1.0f, 1.0f,
        -1.0f, -1.0f, -1.0f,
        -1.0f, -1.0f, 1.0f,
        -1.0f, 1.0f, 1.0f,
        
        // Top face
        -1.0f, 1.0f, -1.0f,
        -1.0f, 1.0f, 1.0f,
        1.0f, 1.0f, -1.0f,
        -1.0f, 1.0f, 1.0f,
        1.0f, 1.0f, 1.0f,
        1.0f, 1.0f, -1.0f,
        
        // Bottom face
        1.0f, -1.0f, -1.0f,
        1.0f, -1.0f, 1.0f,
        -1.0f, -1.0f, -1.0f,
        1.0f, -1.0f, 1.0f,
        -1.0f, -1.0f, 1.0f,
        -1.0f, -1.0f, -1.0f,
    };
    
    const GLfloat cubeColors[] = {
        // front, green
        0.0f, 0.5273f, 0.2656f, 1.0f,
        0.0f, 0.5273f, 0.2656f, 1.0f,
        0.0f, 0.5273f, 0.2656f, 1.0f,
        0.0f, 0.5273f, 0.2656f, 1.0f,
        0.0f, 0.5273f, 0.2656f, 1.0f,
        0.0f, 0.5273f, 0.2656f, 1.0f,
        
        // right, blue
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        
        // back, also green
        0.0f, 0.5273f, 0.2656f, 1.0f,
        0.0f, 0.5273f, 0.2656f, 1.0f,
        0.0f, 0.5273f, 0.2656f, 1.0f,
        0.0f, 0.5273f, 0.2656f, 1.0f,
        0.0f, 0.5273f, 0.2656f, 1.0f,
        0.0f, 0.5273f, 0.2656f, 1.0f,
        
        // left, also blue
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        
        // top, red
        0.8359375f,  0.17578125f,  0.125f, 1.0f,
        0.8359375f,  0.17578125f,  0.125f, 1.0f,
        0.8359375f,  0.17578125f,  0.125f, 1.0f,
        0.8359375f,  0.17578125f,  0.125f, 1.0f,
        0.8359375f,  0.17578125f,  0.125f, 1.0f,
        0.8359375f,  0.17578125f,  0.125f, 1.0f,
        
        // bottom, also red
        0.8359375f,  0.17578125f,  0.125f, 1.0f,
        0.8359375f,  0.17578125f,  0.125f, 1.0f,
        0.8359375f,  0.17578125f,  0.125f, 1.0f,
        0.8359375f,  0.17578125f,  0.125f, 1.0f,
        0.8359375f,  0.17578125f,  0.125f, 1.0f,
        0.8359375f,  0.17578125f,  0.125f, 1.0f,
    };
    
//    const GLfloat cubeFoundColors[] = {
//        // front, yellow
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        
//        // right, yellow
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        
//        // back, yellow
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        
//        // left, yellow
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        
//        // top, yellow
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        
//        // bottom, yellow
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//        1.0f,  0.6523f, 0.0f, 1.0f,
//    };
    
    const GLfloat cubeNormals[] = {
        // Front face
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        
        // Right face
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        
        // Back face
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        
        // Left face
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        
        // Top face
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        
        // Bottom face
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f
    };
    
    const GLfloat floorVertices[] = {
         200.0f,  0.0f, -200.0f,
        -200.0f,  0.0f, -200.0f,
        -200.0f,  0.0f,  200.0f,
         200.0f,  0.0f, -200.0f,
        -200.0f,  0.0f,  200.0f,
         200.0f,  0.0f,  200.0f,
    };
    
    const GLfloat floorNormals[] = {
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
    };
    
    const GLfloat floorColors[] = {
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
        0.0f, 0.3398f, 0.9023f, 1.0f,
    };
    
    [EAGLContext setCurrentContext:GLView.context];

    [self setupPrograms];

    // Cube VAO setup
    glGenVertexArraysOES(1, &_cubeVertexArray);
    glBindVertexArrayOES(_cubeVertexArray);
    
    _cubePositionParam = glGetAttribLocation(_cubeProgram, "a_Position");
    _cubeNormalParam = glGetAttribLocation(_cubeProgram, "a_Normal");
    _cubeColorParam = glGetAttribLocation(_cubeProgram, "a_Color");
    
    _cubeModelParam = glGetUniformLocation(_cubeProgram, "u_Model");
    _cubeModelViewParam = glGetUniformLocation(_cubeProgram, "u_MVMatrix");
    _cubeModelViewProjectionParam = glGetUniformLocation(_cubeProgram, "u_MVP");
    _cubeLightPositionParam = glGetUniformLocation(_cubeProgram, "u_LightPos");
    
    glEnableVertexAttribArray(_cubePositionParam);
    glEnableVertexAttribArray(_cubeNormalParam);
    glEnableVertexAttribArray(_cubeColorParam);

    glGenBuffers(1, &_cubeVertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _cubeVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(cubeVertices), cubeVertices, GL_STATIC_DRAW);

    // Set the position of the cube
    glVertexAttribPointer(_cubePositionParam, _coordsPerVertex, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));

    glGenBuffers(1, &_cubeNormalBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _cubeNormalBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(cubeNormals), cubeNormals, GL_STATIC_DRAW);

    // Set the normal positions of the cube, again for shading
    glVertexAttribPointer(_cubeNormalParam, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));

    glGenBuffers(1, &_cubeColorBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _cubeColorBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(cubeColors), cubeColors, GL_STATIC_DRAW);

    glVertexAttribPointer(_cubeColorParam, 4, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));

    // TODO: implement color change when looking at cube
//    glVertexAttribPointer(_cubeColorParam, 4, GL_FLOAT, false, 0,
//                          isLookingAtObject() ? mCubeFoundColors : _cubeColors);
    
    checkGLError();

    glBindVertexArrayOES(0);
    
    
    // Floor VAO setup
    glGenVertexArraysOES(1, &_floorVertexArray);
    glBindVertexArrayOES(_floorVertexArray);

    _floorModelParam = glGetUniformLocation(_floorProgram, "u_Model");
    _floorModelViewParam = glGetUniformLocation(_floorProgram, "u_MVMatrix");
    _floorModelViewProjectionParam = glGetUniformLocation(_floorProgram, "u_MVP");
    _floorLightPositionParam = glGetUniformLocation(_floorProgram, "u_LightPos");
    
    _floorPositionParam = glGetAttribLocation(_floorProgram, "a_Position");
    _floorNormalParam = glGetAttribLocation(_floorProgram, "a_Normal");
    _floorColorParam = glGetAttribLocation(_floorProgram, "a_Color");
    
    glEnableVertexAttribArray(_floorPositionParam);
    glEnableVertexAttribArray(_floorNormalParam);
    glEnableVertexAttribArray(_floorColorParam);
    
    glGenBuffers(1, &_floorVertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _floorVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(floorVertices), floorVertices, GL_STATIC_DRAW);
    
    // Set the position of the floor
    glVertexAttribPointer(_floorPositionParam, _coordsPerVertex, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    glGenBuffers(1, &_floorNormalBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _floorNormalBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(floorNormals), floorNormals, GL_STATIC_DRAW);
    
    // Set the normal positions of the floor, again for shading
    glVertexAttribPointer(_floorNormalParam, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    glGenBuffers(1, &_floorColorBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _floorColorBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(floorColors), floorColors, GL_STATIC_DRAW);
    
    glVertexAttribPointer(_floorColorParam, 4, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    checkGLError();
    
    glBindVertexArrayOES(0);

    
    // Etc
    glEnable(GL_DEPTH_TEST);
    glClearColor(0.2f, 0.2f, 0.2f, 0.5f); // Dark background so text shows up well.

    
    // Object first appears directly in front of user.
    _modelCube = GLKMatrix4Identity;
    _modelCube = GLKMatrix4Translate(_modelCube, 0, 0, -_objectDistance);
    
    _modelFloor = GLKMatrix4Identity;
    _modelFloor = GLKMatrix4Translate(_modelFloor, 0, -_floorDepth, 0); // Floor appears below user.
    
    checkGLError();
}

- (BOOL)setupPrograms
{
    GLuint vertexShader, gridShader, passthroughShader;
    
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"light_vertex" ofType:@"shader"];
    if (![GLHelpers compileShader:&vertexShader type:GL_VERTEX_SHADER file:vertexShaderPath]) {
        NSLog(@"Failed to compile light_vertex shader");
        return NO;
    }

    NSString *gridShaderPath = [[NSBundle mainBundle] pathForResource:@"grid_fragment" ofType:@"shader"];
    if (![GLHelpers compileShader:&gridShader type:GL_FRAGMENT_SHADER file:gridShaderPath]) {
        NSLog(@"Failed to compile grid_fragment shader");
        return NO;
    }

    NSString *passthroughShaderPath = [[NSBundle mainBundle] pathForResource:@"passthrough_fragment" ofType:@"shader"];
    if (![GLHelpers compileShader:&passthroughShader type:GL_FRAGMENT_SHADER file:passthroughShaderPath]) {
        NSLog(@"Failed to compile passthrough_fragment shader");
        return NO;
    }
    
    _cubeProgram = glCreateProgram();
    glAttachShader(_cubeProgram, vertexShader);
    glAttachShader(_cubeProgram, passthroughShader);
    glLinkProgram(_cubeProgram);
    glUseProgram(_cubeProgram);
    
    checkGLError();
    
    _floorProgram = glCreateProgram();
    glAttachShader(_floorProgram, vertexShader);
    glAttachShader(_floorProgram, gridShader);
    glLinkProgram(_floorProgram);
    glUseProgram(_floorProgram);
    
    checkGLError();
    
    return YES;
}

- (void)shutdownRendererWithView:(GLKView *)GLView
{
}

- (void)renderViewDidChangeSize:(CGSize)size
{
}

- (void)prepareNewFrameWithHeadTransform:(HeadTransform *)headTransform
{
    // Build the Model part of the ModelView matrix
    _modelCube = GLKMatrix4Rotate(_modelCube, GLKMathDegreesToRadians(_timeDelta), 0.5f, 0.5f, 1.0f);
    
    // Build the camera matrix and apply it to the ModelView.
    _camera = GLKMatrix4MakeLookAt(0, 0, _cameraZ,
                                   0, 0, 0,
                                   0, 1.0f, 0);
    _headView = headTransform->getHeadView();
    
    checkGLError();
}

- (void)drawEyeWithTransform:(EyeTransform *)eyeTransform eyeType:(EyeParamsType)eyeType
{
    // NSLog(@"%@", NSStringFromGLKMatrix4(eyeTransform->getEyeView()));

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    checkGLError();
    
    // Apply the eye transformation to the camera
    _view = GLKMatrix4Multiply(eyeTransform->getEyeView(), _camera);
    
    // Set the position of the light
    _lightPositionInEyeSpace = GLKMatrix4MultiplyVector4(_view, _lightPositionInWorldSpace);
    
    // Build the ModelView and ModelViewProjection matrices
    // for calculating cube position and light.
    // float[] perspective = eye.getPerspective(Z_NEAR, Z_FAR);
    GLKMatrix4 perspective = eyeTransform->getPerspective();
    _modelView = GLKMatrix4Multiply(_view, _modelCube);
    _modelViewProjection = GLKMatrix4Multiply(perspective, _modelView);

    [self drawCube];
    
    // Set mModelView for the floor, so we draw floor in the correct location
    _modelView = GLKMatrix4Multiply(_view, _modelFloor);
    _modelViewProjection = GLKMatrix4Multiply(perspective, _modelView);
    [self drawFloor];
}

- (void)finishFrameWithViewport:(Viewport *)viewPort
{
}

// Draw the cube.
// We've set all of our transformation matrices. Now we simply pass them into the shader.
- (void)drawCube
{
    glUseProgram(_cubeProgram);
    glBindVertexArrayOES(_cubeVertexArray);

    glUniform3f(_cubeLightPositionParam,
                _lightPositionInEyeSpace.x,
                _lightPositionInEyeSpace.y,
                _lightPositionInEyeSpace.z);
    
    // Set the Model in the shader, used to calculate lighting
    glUniformMatrix4fv(_cubeModelParam, 1, GL_FALSE, _modelCube.m);
    
    // Set the ModelView in the shader, used to calculate lighting
    glUniformMatrix4fv(_cubeModelViewParam, 1, GL_FALSE, _modelView.m);
    
    // Set the ModelViewProjection matrix in the shader.
    glUniformMatrix4fv(_cubeModelViewProjectionParam, 1, GL_FALSE, _modelViewProjection.m);
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    checkGLError();
    
    glBindVertexArrayOES(0);
    glUseProgram(0);
}

// Draw the floor.
// This feeds in data for the floor into the shader. Note that this doesn't feed in data about
// position of the light, so if we rewrite our code to draw the floor first, the lighting might
// look strange.
- (void)drawFloor
{
    glUseProgram(_floorProgram);
    glBindVertexArrayOES(_floorVertexArray);

    // Set ModelView, MVP, position, normals, and color.
    glUniform3f(_floorLightPositionParam,
                _lightPositionInEyeSpace.x,
                _lightPositionInEyeSpace.y,
                _lightPositionInEyeSpace.z);
    glUniformMatrix4fv(_floorModelParam, 1, GL_FALSE, _modelFloor.m);
    glUniformMatrix4fv(_floorModelViewParam, 1, GL_FALSE, _modelView.m);
    glUniformMatrix4fv(_floorModelViewProjectionParam, 1, GL_FALSE, _modelViewProjection.m);
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    checkGLError();
    
    glBindVertexArrayOES(0);
    glUseProgram(0);
}

@end


@interface TreasureViewController()

@property (nonatomic) TreasureRenderer *treasureRenderer;

@end


@implementation TreasureViewController

- (instancetype)init
{
    self = [super init];
    if (!self) {return nil; }
    
    self.treasureRenderer = [TreasureRenderer new];
    self.stereoRendererDelegate = self.treasureRenderer;
    
    return self;
}

@end
