//
//  DistortionRenderer.mm
//  CardboardSDK-iOS
//
//

#include "DistortionRenderer.h"

#import "GLHelpers.h"

#import <OpenGLES/ES2/glext.h>


DistortionRenderer::DistortionRenderer()
{
    _programHolder = nullptr;
    _headMountedDisplay = nullptr;
    _leftEyeDistortionMesh = nullptr;
    _rightEyeDistortionMesh = nullptr;
    _leftEyeFov = nullptr;
    _rightEyeFov = nullptr;

    // _originalFramebufferID = 0;
    _framebufferID = -1;
    _textureID = -1;
    _renderbufferID = -1;
    _cullFaceEnabled = 0;
    _scissorTestEnabled = 0;
    for (int i = 0; i < 4; i++) {
        _viewport[i] = 0;
    }
    _resolutionScale = 1.0F;
}

void DistortionRenderer::beforeDrawFrame()
{
    // glGetIntegerv(GL_FRAMEBUFFER_BINDING, &_originalFramebufferID);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebufferID);
}

void DistortionRenderer::afterDrawFrame()
{
    // glBindFramebuffer(GL_FRAMEBUFFER, _originalFramebufferID);
    ScreenParams *screen = _headMountedDisplay->getScreen();
    glViewport(0, 0, screen->width(), screen->height());
    
    glGetIntegerv(GL_VIEWPORT, _viewport);
    
    _cullFaceEnabled = glIsEnabled(GL_CULL_FACE);
    _scissorTestEnabled = glIsEnabled(GL_SCISSOR_TEST);
 
    glDisable(GL_CULL_FACE);
    glDisable(GL_SCISSOR_TEST);
    
    glClearColor(0.0F, 0.0F, 0.0F, 1.0F);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glUseProgram(_programHolder->program);
    
    glEnable(GL_SCISSOR_TEST);
    
    glScissor(0, 0, screen->width() / 2, screen->height());
    
    renderDistortionMesh(_leftEyeDistortionMesh);
    
    glScissor(screen->width() / 2, 0, screen->width() / 2, screen->height());

    renderDistortionMesh(_rightEyeDistortionMesh);
    
    glDisableVertexAttribArray(_programHolder->positionLocation);
    glDisableVertexAttribArray(_programHolder->vignetteLocation);
    glDisableVertexAttribArray(_programHolder->textureCoordLocation);
    glUseProgram(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    if (_cullFaceEnabled == 1)
    {
        glEnable(GL_CULL_FACE);
    }
    if (_scissorTestEnabled == 1)
    {
        glEnable(GL_SCISSOR_TEST);
    }
    else
    {
        glDisable(GL_SCISSOR_TEST);
    }
    
    glViewport(_viewport[0], _viewport[1], _viewport[2], _viewport[3]);
    
    checkGLError();
}

DistortionRenderer::~DistortionRenderer()
{
    if (_leftEyeDistortionMesh != nullptr) { delete _leftEyeDistortionMesh; }
    if (_rightEyeDistortionMesh != nullptr) { delete _rightEyeDistortionMesh; }
    if (_headMountedDisplay != nullptr) { delete _headMountedDisplay; }
    if (_leftEyeFov != nullptr) { delete _leftEyeFov; }
    if (_rightEyeFov != nullptr) { delete _rightEyeFov; }
    if (_programHolder != nullptr) { delete _programHolder; }
}

void DistortionRenderer::setResolutionScale(float scale)
{
    _resolutionScale = scale;
}

void DistortionRenderer::onProjectionChanged(HeadMountedDisplay *hmd,
                                             EyeParams *leftEye,
                                             EyeParams *rightEye,
                                             float zNear,
                                             float zFar)
{
    if (_headMountedDisplay != nullptr) { delete _headMountedDisplay; }
    if (_leftEyeFov != nullptr) { delete _leftEyeFov; }
    if (_rightEyeFov != nullptr) { delete _rightEyeFov; }

    _headMountedDisplay = new HeadMountedDisplay(hmd);
    _leftEyeFov = new FieldOfView(leftEye->fov());
    _rightEyeFov = new FieldOfView(rightEye->fov());
    
    ScreenParams *screen = hmd->getScreen();
    CardboardDeviceParams *cdp = hmd->getCardboard();
    
    if (_programHolder == nullptr)
    {
        _programHolder = createProgramHolder();
    }
    
    EyeViewport leftEyeViewport = initViewportForEye(leftEye, 0.0f);
    EyeViewport rightEyeViewport = initViewportForEye(rightEye, leftEyeViewport.width);

    leftEye->transform()->setPerspective(leftEye->fov()->toPerspectiveMatrix(zNear, zFar));
    rightEye->transform()->setPerspective(rightEye->fov()->toPerspectiveMatrix(zNear, zFar));
    
    float textureWidthM = leftEyeViewport.width + rightEyeViewport.width;
    float textureHeightM = MAX(leftEyeViewport.height, rightEyeViewport.height);
    
    float xPxPerM = screen->width() / screen->widthInMeters();
    float yPxPerM = screen->height() / screen->heightInMeters();
    int textureWidthPx = round(textureWidthM * xPxPerM);
    int textureHeightPx = round(textureHeightM * yPxPerM);
    
    float xEyeOffsetMScreen = screen->widthInMeters() / 2.0f - cdp->interpupillaryDistance() / 2.0f;
    float yEyeOffsetMScreen = cdp->verticalDistanceToLensCenter() - screen->borderSizeInMeters();
    
    _leftEyeDistortionMesh = createDistortionMesh(leftEye, leftEyeViewport, textureWidthM, textureHeightM, xEyeOffsetMScreen, yEyeOffsetMScreen);
    xEyeOffsetMScreen = screen->widthInMeters() - xEyeOffsetMScreen;
    _rightEyeDistortionMesh = createDistortionMesh(rightEye, rightEyeViewport, textureWidthM, textureHeightM, xEyeOffsetMScreen, yEyeOffsetMScreen);
    
    setupRenderTextureAndRenderbuffer(textureWidthPx, textureHeightPx);
}

DistortionRenderer::EyeViewport DistortionRenderer::initViewportForEye(EyeParams *eye, float xOffsetM)
{
    ScreenParams *screen = _headMountedDisplay->getScreen();
    CardboardDeviceParams *cdp = _headMountedDisplay->getCardboard();
    
    float eyeToScreenDistanceM = cdp->eyeToLensDistance() + cdp->screenToLensDistance();
    
    float leftM = tanf(eye->fov()->left() * (M_PI / 180.0f)) * eyeToScreenDistanceM;
    float rightM = tanf(eye->fov()->right() * (M_PI / 180.0f)) * eyeToScreenDistanceM;
    float bottomM = tanf(eye->fov()->bottom() * (M_PI / 180.0f)) * eyeToScreenDistanceM;
    float topM = tanf(eye->fov()->top() * (M_PI / 180.0f)) * eyeToScreenDistanceM;
    
    EyeViewport vp;
    vp.x = xOffsetM;
    vp.y = 0.0F;
    vp.width = (leftM + rightM);
    vp.height = (bottomM + topM);
    vp.eyeX = (leftM + xOffsetM);
    vp.eyeY = bottomM;
    
    float xPxPerM = screen->width() / screen->widthInMeters();
    float yPxPerM = screen->height() / screen->heightInMeters();
    eye->viewport()->x = round(vp.x * xPxPerM);
    eye->viewport()->y = round(vp.y * yPxPerM);
    eye->viewport()->width = round(vp.width * xPxPerM);
    eye->viewport()->height = round(vp.height * yPxPerM);
    
    return vp;
}

DistortionRenderer::DistortionMesh* DistortionRenderer::createDistortionMesh(EyeParams *eye,
                                                                             EyeViewport eyeViewport,
                                                                             float textureWidthM,
                                                                             float textureHeightM,
                                                                             float xEyeOffsetMScreen,
                                                                             float yEyeOffsetMScreen)
{
    return new DistortionMesh(eye,
                              _headMountedDisplay->getCardboard()->getDistortion(),
            _headMountedDisplay->getScreen()->widthInMeters(),
            _headMountedDisplay->getScreen()->heightInMeters(),
                              xEyeOffsetMScreen, yEyeOffsetMScreen,
                              textureWidthM, textureHeightM,
                              eyeViewport.eyeX, eyeViewport.eyeY,
                              eyeViewport.x, eyeViewport.y,
                              eyeViewport.width, eyeViewport.height);
}

void DistortionRenderer::renderDistortionMesh(DistortionMesh *mesh)
{
    glBindBuffer(GL_ARRAY_BUFFER, mesh->_arrayBufferID);
    glVertexAttribPointer(_programHolder->positionLocation, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void *)(0 * sizeof(float)));
    glEnableVertexAttribArray(_programHolder->positionLocation);
    glVertexAttribPointer(_programHolder->vignetteLocation, 1, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void *)(2 * sizeof(float)));
    glEnableVertexAttribArray(_programHolder->vignetteLocation);
    glVertexAttribPointer(_programHolder->textureCoordLocation, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void *)(3 * sizeof(float)));
    glEnableVertexAttribArray(_programHolder->textureCoordLocation);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureID);
    glUniform1i(_programHolder->uTextureSamplerLocation, 0);
    glUniform1f(_programHolder->uTextureCoordScaleLocation, _resolutionScale);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh->_elementBufferID);
    glDrawElements(5, mesh->_indices, GL_UNSIGNED_INT, 0);
    
    checkGLError();
}

float DistortionRenderer::computeDistortionScale(Distortion *distortion, float screenWidthM, float interpupillaryDistanceM)
{
    return distortion->distortionFactor((screenWidthM / 2.0f - interpupillaryDistanceM / 2.0f) / (screenWidthM / 4.0f));
}

int DistortionRenderer::createTexture(int width, int height)
{
    GLuint textureIds;
    glGenTextures(1, &textureIds);
    glBindTexture(GL_TEXTURE_2D, textureIds);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, nil);
    
    checkGLError();

    return textureIds;
}

int DistortionRenderer::setupRenderTextureAndRenderbuffer(int width, int height)
{
    GLuint textureId = _textureID;
    if (textureId != -1)
    {
        glDeleteTextures(1, &textureId);
    }
    GLuint renderbufferId = _renderbufferID;
    if (renderbufferId != -1)
    {
        glDeleteRenderbuffers(1, &renderbufferId);
    }
    GLuint framebufferId = _framebufferID;
    if (framebufferId != -1)
    {
        glDeleteFramebuffers(1, &framebufferId);
    }
    
    _textureID = createTexture(width, height);
    checkGLError();
    
    GLuint renderbufferIds;
    glGenRenderbuffers(1, &renderbufferIds);
    glBindRenderbuffer(GL_RENDERBUFFER, renderbufferIds);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    
    _renderbufferID = renderbufferIds;
    checkGLError();
    
    GLuint framebufferIds;
    glGenFramebuffers(1, &framebufferIds);
    glBindFramebuffer(GL_FRAMEBUFFER, framebufferIds);
    _framebufferID = framebufferIds;
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _textureID, 0);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, renderbufferIds);
    
    GLuint status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE)
    {
        [NSException raise:@"DistortionRenderer" format:@"Framebuffer is not complete: %d", status];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    checkGLError();

    return framebufferIds;
}

int DistortionRenderer::loadShader(GLenum shaderType, const GLchar *source)
{
    GLuint shader = glCreateShader(shaderType);
    if (shader != 0) {
        glShaderSource(shader, 1, &source, nil);
        glCompileShader(shader);
        GLint status;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
        if (status == GL_FALSE)
        {
            GLchar message[256];
            glGetShaderInfoLog(shader, sizeof(message), 0, &message[0]);
            NSLog(@"Could not compile shader %d:\n%s", shaderType, message);
            glDeleteShader(shader);
            shader = 0;
        }
    }
    
    checkGLError();

    return shader;
}

int DistortionRenderer::createProgram(const GLchar *vertexSource, const GLchar *fragmentSource)
{
    GLuint vertexShader = loadShader(GL_VERTEX_SHADER, vertexSource);
    if (vertexShader == 0)
    {
        return 0;
    }
    GLuint pixelShader = loadShader(GL_FRAGMENT_SHADER, fragmentSource);
    if (pixelShader == 0)
    {
        return 0;
    }
    GLuint program = glCreateProgram();
    if (program != 0)
    {
        glAttachShader(program, vertexShader);
        checkGLError();
        glAttachShader(program, pixelShader);
        checkGLError();
        glLinkProgram(program);
        GLint status;
        glGetProgramiv(program, GL_LINK_STATUS, &status);
        if (status == GL_FALSE)
        {
            GLchar message[256];
            glGetProgramInfoLog(program, sizeof(message), 0, &message[0]);
            NSLog(@"Could not link program:\n%s", message);
            glDeleteProgram(program);
            program = 0;
        }
    }
    
    checkGLError();

    return program;
}

DistortionRenderer::ProgramHolder *DistortionRenderer::createProgramHolder()
{
    ProgramHolder *holder = new ProgramHolder();
    holder->program = createProgram("attribute vec2 aPosition;\nattribute float aVignette;\nattribute vec2 aTextureCoord;\nvarying vec2 vTextureCoord;\nvarying float vVignette;\nuniform float uTextureCoordScale;\nvoid main() {\n    gl_Position = vec4(aPosition, 0.0, 1.0);\n    vTextureCoord = aTextureCoord.xy * uTextureCoordScale;\n    vVignette = aVignette;\n}\n",
                                          "precision mediump float;\nvarying vec2 vTextureCoord;\nvarying float vVignette;\nuniform sampler2D uTextureSampler;\nvoid main() {\n    gl_FragColor = vVignette * texture2D(uTextureSampler, vTextureCoord);\n}\n");
    if (holder->program == 0)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not create program"];
    }
    
    holder->positionLocation = glGetAttribLocation(holder->program, "aPosition");
    checkGLError();
    if (holder->positionLocation == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aPosition"];
    }
    
    holder->vignetteLocation = glGetAttribLocation(holder->program, "aVignette");
    checkGLError();
    if (holder->vignetteLocation == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aVignette"];
    }
    
    holder->textureCoordLocation = glGetAttribLocation(holder->program, "aTextureCoord");
    checkGLError();
    if (holder->textureCoordLocation == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aTextureCoord"];
    }
    
    holder->uTextureCoordScaleLocation = glGetUniformLocation(holder->program, "uTextureCoordScale");
    checkGLError();
    if (holder->uTextureCoordScaleLocation == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for uTextureCoordScale"];
    }
    
    holder->uTextureSamplerLocation = glGetUniformLocation(holder->program, "uTextureSampler");
    checkGLError();
    if (holder->uTextureSamplerLocation == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for uTextureSampler"];
    }
    
    // NSLog(@"ProgramHolder created %p %d", this, holder->program);
    
    return holder;
}

float DistortionRenderer::clamp(float val, float min, float max)
{
    return MAX(min, MIN(max, val));
}

// DistortionMesh

DistortionRenderer::DistortionMesh::DistortionMesh(EyeParams *eye,
                                                   Distortion *distortion,
                                                   float screenWidthM,
                                                   float screenHeightM,
                                                   float xEyeOffsetMScreen,
                                                   float yEyeOffsetMScreen,
                                                   float textureWidthM,
                                                   float textureHeightM,
                                                   float xEyeOffsetMTexture,
                                                   float yEyeOffsetMTexture,
                                                   float viewportXMTexture,
                                                   float viewportYMTexture,
                                                   float viewportWidthMTexture,
                                                   float viewportHeightMTexture)
{
    float mPerUScreen = screenWidthM;
    float mPerVScreen = screenHeightM;
    float mPerUTexture = textureWidthM;
    float mPerVTexture = textureHeightM;
    
    int vertexOffset = 0;
    
    for (int row = 0; row < 40; row++)
    {
        for (int col = 0; col < 40; col++)
        {
            float uTexture = col / 39.0f * (viewportWidthMTexture / textureWidthM) + viewportXMTexture / textureWidthM;
            
            float vTexture = row / 39.0f * (viewportHeightMTexture / textureHeightM) + viewportYMTexture / textureHeightM;
            
            float xTexture = uTexture * mPerUTexture;
            float yTexture = vTexture * mPerVTexture;
            float xTextureEye = xTexture - xEyeOffsetMTexture;
            float yTextureEye = yTexture - yEyeOffsetMTexture;
            float rTexture = sqrtf(xTextureEye * xTextureEye + yTextureEye * yTextureEye);
            
            float textureToScreen = rTexture > 0.0f ? distortion->distortInverse(rTexture) / rTexture : 1.0f;
            
            float xScreen = xTextureEye * textureToScreen + xEyeOffsetMScreen;
            float yScreen = yTextureEye * textureToScreen + yEyeOffsetMScreen;
            float uScreen = xScreen / mPerUScreen;
            float vScreen = yScreen / mPerVScreen;
            float vignetteSizeMTexture = 0.002f / textureToScreen;
            
            float dxTexture = xTexture - DistortionRenderer::clamp(xTexture, viewportXMTexture + vignetteSizeMTexture, viewportXMTexture + viewportWidthMTexture - vignetteSizeMTexture);
            float dyTexture = yTexture - DistortionRenderer::clamp(yTexture, viewportYMTexture + vignetteSizeMTexture, viewportYMTexture + viewportHeightMTexture - vignetteSizeMTexture);
            
            float drTexture = sqrtf(dxTexture * dxTexture + dyTexture * dyTexture);
            
            float vignette = 1.0f - DistortionRenderer::clamp(drTexture / vignetteSizeMTexture, 0.0f, 1.0f);
            
            _vertexData[(vertexOffset + 0)] = (2.0f * uScreen - 1.0f);
            _vertexData[(vertexOffset + 1)] = (2.0f * vScreen - 1.0f);
            _vertexData[(vertexOffset + 2)] = vignette;
            _vertexData[(vertexOffset + 3)] = uTexture;
            _vertexData[(vertexOffset + 4)] = vTexture;
            
            vertexOffset += 5;
        }
    }
    
    _indices = 3158;
    
    int indexOffset = 0;
    vertexOffset = 0;
    for (int row = 0; row < 39; row++)
    {
        if (row > 0)
        {
            _indexData[indexOffset] = _indexData[(indexOffset - 1)];
            indexOffset++;
        }
        for (int col = 0; col < 40; col++) {
            if (col > 0) {
                if (row % 2 == 0)
                {
                    vertexOffset++;
                }
                else {
                    vertexOffset--;
                }
            }
            _indexData[(indexOffset++)] = vertexOffset;
            _indexData[(indexOffset++)] = (vertexOffset + 40);
        }
        vertexOffset += 40;
    }
    
    GLuint bufferIds[2] = { 0, 0 };
    glGenBuffers(2, bufferIds);
    _arrayBufferID = bufferIds[0];
    _elementBufferID = bufferIds[1];
    
    glBindBuffer(GL_ARRAY_BUFFER, _arrayBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_vertexData), _vertexData, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _elementBufferID);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(_indexData), _indexData, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    checkGLError();
}

// EyeViewport

NSString* DistortionRenderer::EyeViewport::toString()
{
    return [NSString stringWithFormat:@"EyeViewport {x:%f y:%f width:%f height:%f eyeX:%f, eyeY:%f}",
            x, y, width, height, eyeX, eyeY];
}
