//
//  CBDStereoGLView.m
//
//  Created by Ricardo Sánchez-Sáez on 01/02/2015.
//

#import "CBDStereoGLView.h"

#import "GLHelpers.h"
#import <OpenGLES/ES2/glext.h>


@interface UIScreen (SafeNativeScale)

@property(nonatomic, readonly) CGFloat safeNativeScale;

@end


@implementation UIScreen (SafeNativeScale)

- (CGFloat)safeNativeScale
{
    return [self respondsToSelector:@selector(nativeScale)] ? self.nativeScale : self.scale;
}

@end


@interface CBDStereoGLView ()
{
    GLubyte *_texturePixelBuffer;
    CGContextRef _bitmapContext;
    
    GLuint _leftTextureID;
    GLuint _rightTextureID;
    
    GLuint _programID;
    GLuint _vertexArrayID;
    
    GLuint _positionVertexBuffer;
    
    GLuint _positionLocation;
    GLuint _inputTextureCoordinateLocation;
    
    GLuint _uniformLocation;
    
    BOOL _leftTextureDataReady;
    BOOL _rightTextureDataReady;
}

@property (nonatomic) EAGLContext *glContext;
@property (nonatomic) NSRecursiveLock *glLock;

@end


@implementation CBDStereoGLView

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)glContext
{
    return [self initWithFrame:frame context:glContext lock:nil];
}


- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)glContext lock:(NSRecursiveLock *)lock
{
    self = [super initWithFrame:frame];
    if (!self) { return nil; }
    
    _texturePixelBuffer = NULL;
    _bitmapContext = NULL;
    
    _leftTextureID = 0;
    _rightTextureID = 0;
    
    _programID = 0;
    _vertexArrayID = 0;
    
    _positionVertexBuffer = 0;
    
    _positionLocation = 0;
    _inputTextureCoordinateLocation = 0;
    
    _uniformLocation = 0;
    
    _leftTextureDataReady = NO;
    _rightTextureDataReady = NO;
    
    self.glLock = lock ? lock : [NSRecursiveLock new];

    self.glContext = glContext;
    [self prepareForRendering];
    
    return self;
}

- (void)dealloc
{
    if (_bitmapContext) { CGContextRelease(_bitmapContext); }
    if (_texturePixelBuffer) { free(_texturePixelBuffer); }
    [self teardownGL];
}

- (void)prepareForRendering
{
    [self createBitmapContext];
    [self setupGLProgram];
}

- (void)setupGLProgram
{
    [self.glLock lock];
    
    EAGLContext* tmpContext = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:self.glContext];
    
    // Program
    const GLchar *vertexShaderSource =
    "\
    attribute vec2 position;                            \
    attribute vec2 inputTextureCoordinate;              \
    varying vec2 textureCoordinate;                     \
                                                        \
    void main()                                         \
    {                                                   \
        gl_Position = vec4(position, 0.0, 1.0);         \
        textureCoordinate = inputTextureCoordinate;     \
    }                                                   \
    ";
    
    const GLchar *fragmentShaderSource =
    "\
    precision mediump float;                                            \
    varying vec2 textureCoordinate;                                     \
    uniform sampler2D textureSampler;                                   \
                                                                        \
    void main()                                                         \
    {                                                                   \
        gl_FragColor = texture2D(textureSampler, textureCoordinate);    \
    }                                                                   \
    ";
    
    GLuint vertexShader = 0;
    GLCompileShader(&vertexShader, GL_VERTEX_SHADER, vertexShaderSource);
    if (vertexShader == 0) { return; }
    
    GLuint pixelShader = 0;
    GLCompileShader(&pixelShader, GL_FRAGMENT_SHADER, fragmentShaderSource);
    if (pixelShader == 0) { return; }
    
    _programID = glCreateProgram();
    if (_programID == 0) { return; }
    
    glAttachShader(_programID, vertexShader);
    GLCheckForError();
    glAttachShader(_programID, pixelShader);
    GLCheckForError();
    GLLinkProgram(_programID);
    GLint status;
    glGetProgramiv(_programID, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
    {
        GLchar message[256];
        glGetProgramInfoLog(_programID, sizeof(message), 0, &message[0]);
        NSLog(@"Could not link program:\n%s", message);
        glDeleteProgram(_programID);
        _programID = 0;
    }
    
    
    // Buffers and VAO
    float vertices[] = {
        -1.0f,   -1.0f,    0.0f,    0.0f,       // Bottom-left
         1.0f,   -1.0f,    1.0f,    0.0f,       // Bottom-right
        -1.0f,    1.0f,    0.0f,    1.0f,       // Top-left
         1.0f,    1.0f,    1.0f,    1.0f        // Top-right
    };
    
    glGenVertexArraysOES(1, &_vertexArrayID);
    glBindVertexArrayOES(_vertexArrayID);
    
    GLCheckForError();
    
    _positionLocation = glGetAttribLocation(_programID, "position");
    _inputTextureCoordinateLocation = glGetAttribLocation(_programID, "inputTextureCoordinate");
    
    GLCheckForError();
    
    glEnableVertexAttribArray(_positionLocation);
    glEnableVertexAttribArray(_inputTextureCoordinateLocation);
    
    GLCheckForError();
    
    glGenBuffers(1, &_positionVertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _positionVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    GLCheckForError();
    
    // Set the position
    glVertexAttribPointer(_positionLocation, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), BUFFER_OFFSET(0));
    glVertexAttribPointer(_inputTextureCoordinateLocation, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), BUFFER_OFFSET(2 * sizeof(float)));
    
    GLCheckForError();
    
    _uniformLocation = glGetUniformLocation(_programID, "textureSampler");
    
    GLCheckForError();
    
    glBindVertexArrayOES(0);
    
    // Texture
    glGenTextures(1, &_leftTextureID);
    glBindTexture(GL_TEXTURE_2D, _leftTextureID);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glGenTextures(1, &_rightTextureID);
    glBindTexture(GL_TEXTURE_2D, _rightTextureID);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    [EAGLContext setCurrentContext:tmpContext];
    
    [self.glLock unlock];
}

- (void)teardownGL
{
    [self.glLock lock];

    EAGLContext* tmpContext = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:self.glContext];
    
    glDeleteTextures(1, &_leftTextureID);
    glDeleteTextures(1, &_rightTextureID);

    glDeleteVertexArraysOES(1, &_vertexArrayID);
    glDeleteBuffers(1, &_positionVertexBuffer);
    glDeleteProgram(_programID);
    
    [EAGLContext setCurrentContext:tmpContext];
    
    [self.glLock unlock];
}

- (void)createBitmapContext
{
    CGFloat scale = [UIScreen mainScreen].safeNativeScale;
    size_t width = CGRectGetWidth(self.layer.bounds) * scale;
    size_t height = CGRectGetHeight(self.layer.bounds) * scale;
    
    if (_texturePixelBuffer)
    {
        free(_texturePixelBuffer);
    }
    _texturePixelBuffer = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    if (_bitmapContext)
    {
        CGContextRelease(_bitmapContext);
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    _bitmapContext = CGBitmapContextCreate(_texturePixelBuffer,
                                           width, height, 8, width * 4, colorSpace,
                                           kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextScaleCTM(_bitmapContext, scale, scale);
}

- (GLuint)textureIDForEye:(CBDEyeType)eyeType
{
    GLuint textureID = 0;
    if (eyeType == CBDEyeTypeLeft || eyeType == CBDEyeTypeMonocular)
    {
        textureID = _leftTextureID;
    }
    else if (eyeType == CBDEyeTypeRight)
    {
        textureID = _rightTextureID;
    }
    return textureID;
}

- (BOOL)textureDataReadyForEye:(CBDEyeType)eyeType
{
    BOOL textureDataReady = NO;
    if (eyeType == CBDEyeTypeLeft || eyeType == CBDEyeTypeMonocular)
    {
        textureDataReady = _leftTextureDataReady;
    }
    else if (eyeType == CBDEyeTypeRight)
    {
        textureDataReady = _rightTextureDataReady;
    }
    return textureDataReady;
}

- (void)setTextureDataReady:(BOOL)textureDataReady forEye:(CBDEyeType)eyeType
{
    if (eyeType == CBDEyeTypeLeft || eyeType == CBDEyeTypeMonocular)
    {
        _leftTextureDataReady = textureDataReady;
    }
    else if (eyeType == CBDEyeTypeRight)
    {
         _rightTextureDataReady = textureDataReady;
    }
}

- (void)updateGLTextureForEye:(CBDEyeType)eyeType
{
    GLuint textureID = [self textureIDForEye:eyeType];
    if (textureID == 0 || !_bitmapContext) { return; }
    
    BOOL lockAcquired = [self.glLock tryLock];
    if (!lockAcquired) { return; }

    EAGLContext* tmpContext = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:self.glContext];

    size_t width = CGBitmapContextGetWidth(_bitmapContext);
    size_t height = CGBitmapContextGetHeight(_bitmapContext);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextClearRect(_bitmapContext, rect);
    
    // Use presentationLayer because it takes CAAnimations into account
    // (Flush CATransaction to make sure the latest constraint
    //  updates are reflected on the presentationLayer)
    [CATransaction flush];
    [self.layer.presentationLayer renderInContext:_bitmapContext];
    
    // Debug
    CGImageRef imageRef = CGBitmapContextCreateImage(_bitmapContext);
    __unused UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);

    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, _texturePixelBuffer);
    [self setTextureDataReady:YES forEye:eyeType];
    
    [EAGLContext setCurrentContext:tmpContext];
    
    GLCheckForError();
    
    [self.glLock unlock];
}

- (void)renderTextureForEye:(CBDEyeType)eyeType
{
    GLuint textureID = [self textureIDForEye:eyeType];
    BOOL textureDataSet = [self textureDataReadyForEye:eyeType];
    if (textureID == 0 || _programID == 0 || !textureDataSet) { return; }
    
    BOOL lockAcquired = [self.glLock tryLock];
    if (!lockAcquired) { return; }
    
    glUseProgram(_programID);
    glBindVertexArrayOES(_vertexArrayID);
    glUniform1i(_uniformLocation, 0);
    
    // Enable texture alpha blending
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    GLCheckForError();

    // Enable texture alpha blending
    glDisable(GL_BLEND);

    glBindVertexArrayOES(0);
    glUseProgram(0);
    
    [self.glLock unlock];
}

@end
