//
//  DistortionRenderer.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-29.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "DistortionRenderer.h"

DistortionRenderer::DistortionRenderer()
{
    this->textureId = -1;
    this->renderbufferId = -1;
    this->framebufferId = -1;
    this->originalFramebufferId = 0;
    this->cullFaceEnabled = 0;
    this->scissorTestEnabled = 0;
    for (int i = 0; i < 4; i++) {
        this->viewport[i] = 0;
    }
    this->resolutionScale = 1.0F;
}

void DistortionRenderer::beforeDrawFrame()
{
    glGetIntegerv(36006, &this->originalFramebufferId);
    glBindFramebuffer(36160, this->framebufferId);
}

void DistortionRenderer::afterDrawFrame()
{
    glBindFramebuffer(36160, this->originalFramebufferId);
    glViewport(0, 0, this->hmd->getScreen()->getWidth(), this->hmd->getScreen()->getHeight());
    
    glGetIntegerv(2978, this->viewport);
    glGetIntegerv(2884, &this->cullFaceEnabled);
    glGetIntegerv(3089, &this->scissorTestEnabled);
    glDisable(3089);
    glDisable(2884);
    
    glClearColor(0.0F, 0.0F, 0.0F, 1.0F);
    glClear(16640);
    
    glUseProgram(this->programHolder->program);
    
    glEnable(3089);
    
    glScissor(0, 0, this->hmd->getScreen()->getWidth() / 2, this->hmd->getScreen()->getHeight());
    
    this->renderDistortionMesh(this->leftEyeDistortionMesh);
    
    glScissor(this->hmd->getScreen()->getWidth() / 2, 0, this->hmd->getScreen()->getWidth() / 2, this->hmd->getScreen()->getHeight());

    this->renderDistortionMesh(this->rightEyeDistortionMesh);
    
    glDisableVertexAttribArray(this->programHolder->aPosition);
    glDisableVertexAttribArray(this->programHolder->aVignette);
    glDisableVertexAttribArray(this->programHolder->aTextureCoord);
    glUseProgram(0);
    glBindBuffer(34962, 0);
    glBindBuffer(34963, 0);
    glDisable(3089);
    if (this->cullFaceEnabled == 1) {
        glEnable(2884);
    }
    if (this->scissorTestEnabled == 1) {
        glEnable(3089);
    }
    glViewport(this->viewport[0], this->viewport[1], this->viewport[2], this->viewport[3]);
}

void DistortionRenderer::setResolutionScale(float scale)
{
    this->resolutionScale = scale;
}

void DistortionRenderer::onProjectionChanged(HeadMountedDisplay *hmd, EyeParams *leftEye, EyeParams *rightEye, float zNear, float zFar)
{
    this->hmd = new HeadMountedDisplay(hmd);
    this->leftEyeFov = new FieldOfView(leftEye->getFov());
    this->rightEyeFov = new FieldOfView(rightEye->getFov());
    
    ScreenParams *screen = hmd->getScreen();
    CardboardDeviceParams *cdp = hmd->getCardboard();
    
    if (this->programHolder == nullptr) {
        this->programHolder = this->createProgramHolder();
    }
    
    EyeViewport leftEyeViewport = this->initViewportForEye(leftEye, 0.0f);
    EyeViewport rightEyeViewport = this->initViewportForEye(rightEye, leftEyeViewport.width);
    
    leftEye->getTransform()->setPerspective(leftEye->getFov()->toPerspectiveMatrix(zNear, zFar));
    rightEye->getTransform()->setPerspective(rightEye->getFov()->toPerspectiveMatrix(zNear, zFar));
    
    float textureWidthM = leftEyeViewport.width + rightEyeViewport.width;
    float textureHeightM = MAX(leftEyeViewport.height, rightEyeViewport.height);
    
    float xPxPerM = screen->getWidth() / screen->getWidthMeters();
    float yPxPerM = screen->getHeight() / screen->getHeightMeters();
    int textureWidthPx = round(textureWidthM * xPxPerM);
    int textureHeightPx = round(textureHeightM * yPxPerM);
    
    float xEyeOffsetMScreen = screen->getWidthMeters() / 2.0f - cdp->getInterpupillaryDistance() / 2.0f;
    float yEyeOffsetMScreen = cdp->getVerticalDistanceToLensCenter() - screen->getBorderSizeMeters();
    
    this->leftEyeDistortionMesh = this->createDistortionMesh(leftEye, leftEyeViewport, textureWidthM, textureHeightM, xEyeOffsetMScreen, yEyeOffsetMScreen);
    xEyeOffsetMScreen = screen->getWidthMeters() - xEyeOffsetMScreen;
    this->rightEyeDistortionMesh = this->createDistortionMesh(rightEye, rightEyeViewport, textureWidthM, textureHeightM, xEyeOffsetMScreen, yEyeOffsetMScreen);
    
    this->setupRenderTextureAndRenderbuffer(textureWidthPx, textureHeightPx);
}

DistortionRenderer::EyeViewport DistortionRenderer::initViewportForEye(EyeParams *eye, float xOffsetM)
{
    ScreenParams *screen = hmd->getScreen();
    CardboardDeviceParams *cdp = hmd->getCardboard();
    
    float eyeToScreenDistanceM = cdp->getEyeToLensDistance() + cdp->getScreenToLensDistance();
    
    float leftM = tanf(eye->getFov()->getLeft() * (M_PI / 180.0f)) * eyeToScreenDistanceM;
    float rightM = tanf(eye->getFov()->getRight() * (M_PI / 180.0f)) * eyeToScreenDistanceM;
    float bottomM = tanf(eye->getFov()->getBottom() * (M_PI / 180.0f)) * eyeToScreenDistanceM;
    float topM = tanf(eye->getFov()->getTop() * (M_PI / 180.0f)) * eyeToScreenDistanceM;
    
    EyeViewport vp;
    vp.x = xOffsetM;
    vp.y = 0.0F;
    vp.width = (leftM + rightM);
    vp.height = (bottomM + topM);
    vp.eyeX = (leftM + xOffsetM);
    vp.eyeY = bottomM;
    
    float xPxPerM = screen->getWidth() / screen->getWidthMeters();
    float yPxPerM = screen->getHeight() / screen->getHeightMeters();
    eye->getViewport()->x = round(vp.x * xPxPerM);
    eye->getViewport()->y = round(vp.y * yPxPerM);
    eye->getViewport()->width = round(vp.width * xPxPerM);
    eye->getViewport()->height = round(vp.height * yPxPerM);
    
    return vp;
}

DistortionRenderer::DistortionMesh* DistortionRenderer::createDistortionMesh(EyeParams *eye, EyeViewport eyeViewport, float textureWidthM, float textureHeightM, float xEyeOffsetMScreen, float yEyeOffsetMScreen)
{
    return new DistortionMesh(eye, this->hmd->getCardboard()->getDistortion(), this->hmd->getScreen()->getWidthMeters(), this->hmd->getScreen()->getHeightMeters(), xEyeOffsetMScreen, yEyeOffsetMScreen, textureWidthM, textureHeightM, eyeViewport.eyeX, eyeViewport.eyeY, eyeViewport.x, eyeViewport.y, eyeViewport.width, eyeViewport.height);
}

void DistortionRenderer::renderDistortionMesh(DistortionMesh *mesh)
{
    glBindBuffer(34962, mesh->arrayBufferId);
    glVertexAttribPointer(this->programHolder->aPosition, 3, 5126, false, 5 * sizeof(float), &mesh->vertexData[0]);
    glEnableVertexAttribArray(this->programHolder->aPosition);
    glVertexAttribPointer(this->programHolder->aVignette, 1, 5126, false, 5 * sizeof(float), &mesh->vertexData[2 * sizeof(float)]);
    glEnableVertexAttribArray(this->programHolder->aVignette);
    glVertexAttribPointer(this->programHolder->aTextureCoord, 2, 5126, false, 5 * sizeof(float), &mesh->vertexData[3 * sizeof(float)]);
    glEnableVertexAttribArray(this->programHolder->aTextureCoord);
    
    glActiveTexture(33984);
    glBindTexture(3553, this->textureId);
    glUniform1i(this->programHolder->uTextureSampler, 0);
    glUniform1f(this->programHolder->uTextureCoordScale, this->resolutionScale);
    
    glBindBuffer(34963, mesh->elementBufferId);
    glDrawElements(5, mesh->indices, 5125, 0);
}

float DistortionRenderer::computeDistortionScale(Distortion *distortion, float screenWidthM, float interpupillaryDistanceM)
{
    return distortion->distortionFactor((screenWidthM / 2.0f - interpupillaryDistanceM / 2.0f) / (screenWidthM / 4.0f));
}

int DistortionRenderer::createTexture(int width, int height)
{
    GLuint textureIds;
    glGenTextures(1, &textureIds);
    glBindTexture(3553, textureIds);
    glTexParameteri(3553, 10242, 33071);
    glTexParameteri(3553, 10243, 33071);
    glTexParameteri(3553, 10240, 9729);
    glTexParameteri(3553, 10241, 9729);
    glTexImage2D(3553, 0, 6407, width, height, 0, 6407, 33635, nil);
    return textureIds;
}

int DistortionRenderer::setupRenderTextureAndRenderbuffer(int width, int height)
{
    GLuint textureId = this->textureId;
    if (textureId != -1) {
        glDeleteTextures(1, &textureId);
    }
    GLuint renderbufferId = this->renderbufferId;
    if (renderbufferId != -1) {
        glDeleteRenderbuffers(1, &renderbufferId);
    }
    GLuint framebufferId = this->framebufferId;
    if (framebufferId != -1) {
        glDeleteFramebuffers(1, &framebufferId);
    }
    
    this->textureId = this->createTexture(width, height);
    this->checkGlError(@"setupRenderTextureAndRenderbuffer: create texture");
    
    GLuint renderbufferIds;
    glGenRenderbuffers(1, &renderbufferIds);
    glBindRenderbuffer(36161, renderbufferIds);
    glRenderbufferStorage(36161, 33189, width, height);
    
    this->renderbufferId = renderbufferIds;
    this->checkGlError(@"setupRenderTextureAndRenderbuffer: create renderbuffer");
    
    GLuint framebufferIds;
    glGenFramebuffers(1, &framebufferIds);
    glBindFramebuffer(36160, framebufferIds);
    this->framebufferId = framebufferIds;
    
    glFramebufferTexture2D(36160, 36064, 3553, this->textureId, 0);
    
    glFramebufferRenderbuffer(36160, 36096, 36161, renderbufferIds);
    
    GLuint status = glCheckFramebufferStatus(36160);
    if (status != 36053) {
        [NSException raise:@"DistortionRenderer" format:@"Framebuffer is not complete: %d", status];
    }
    
    glBindFramebuffer(36160, 0);
    
    return framebufferIds;
}

int DistortionRenderer::loadShader(GLenum shaderType, const GLchar *source)
{
    GLuint shader = glCreateShader(shaderType);
    if (shader != 0) {
        glShaderSource(shader, 1, &source, nil);
        glCompileShader(shader);
        GLint status;
        glGetShaderiv(shader, 35713, &status);
        if (status == 0)
        {
            GLchar message[256];
            glGetShaderInfoLog(shader, sizeof(message), 0, &message[0]);
            NSLog(@"Could not compile shader %d:\n%s", shaderType, message);
            glDeleteShader(shader);
            shader = 0;
        }
    }
    return shader;
}

int DistortionRenderer::createProgram(const GLchar *vertexSource, const GLchar *fragmentSource)
{
    GLuint vertexShader = this->loadShader(35633, vertexSource);
    if (vertexShader == 0) {
        return 0;
    }
    GLuint pixelShader = this->loadShader(35632, fragmentSource);
    if (pixelShader == 0) {
        return 0;
    }
    GLuint program = glCreateProgram();
    if (program != 0) {
        glAttachShader(program, vertexShader);
        this->checkGlError(@"glAttachShader");
        glAttachShader(program, pixelShader);
        this->checkGlError(@"glAttachShader");
        glLinkProgram(program);
        GLint status;
        glGetProgramiv(program, 35714, &status);
        if (status != 1) {
            GLchar message[256];
            glGetProgramInfoLog(program, sizeof(message), 0, &message[0]);
            NSLog(@"Could not link program:\n%s", message);
            glDeleteProgram(program);
            program = 0;
        }
    }
    return program;
}

DistortionRenderer::ProgramHolder* DistortionRenderer::createProgramHolder()
{
    ProgramHolder *holder = new ProgramHolder();
    this->createProgram("attribute vec2 aPosition;\nattribute float aVignette;\nattribute vec2 aTextureCoord;\nvarying vec2 vTextureCoord;\nvarying float vVignette;\nuniform float uTextureCoordScale;\nvoid main() {\n    gl_Position = vec4(aPosition, 0.0, 1.0);\n    vTextureCoord = aTextureCoord.xy * uTextureCoordScale;\n    vVignette = aVignette;\n}\n", "precision mediump float;\nvarying vec2 vTextureCoord;\nvarying float vVignette;\nuniform sampler2D uTextureSampler;\nvoid main() {\n    gl_FragColor = vVignette * texture2D(uTextureSampler, vTextureCoord);\n}\n");
    if (holder->program == 0) {
        [NSException raise:@"DistortionRenderer" format:@"Could not create program"];
    }
    holder->aPosition = glGetAttribLocation(holder->program, "aPosition");
    this->checkGlError(@"glGetAttribLocation aPosition");
    if (holder->aPosition == -1) {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aPosition"];
    }
    holder->aVignette = glGetAttribLocation(holder->program, "aVignette");
    this->checkGlError(@"glGetAttribLocation aVignette");
    if (holder->aVignette == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aVignette"];
    }
    holder->aTextureCoord = glGetAttribLocation(holder->program, "aTextureCoord");
    this->checkGlError(@"glGetAttribLocation aTextureCoord");
    if (holder->aTextureCoord == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aTextureCoord"];
    }
    holder->uTextureCoordScale = glGetUniformLocation(holder->program, "uTextureCoordScale");
    this->checkGlError(@"glGetUniformLocation uTextureCoordScale");
    if (holder->uTextureCoordScale == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for uTextureCoordScale"];
    }
    holder->uTextureSampler = glGetUniformLocation(holder->program, "uTextureSampler");
    this->checkGlError(@"glGetUniformLocation uTextureSampler");
    if (holder->uTextureSampler == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for uTextureSampler"];
    }
    return holder;
}

void DistortionRenderer::checkGlError(NSString* op)
{
    int error = glGetError();
    if (error != 0) {
        [NSException raise:@"DistortionRenderer" format:@"%@: glError %d", op, error];
    }
}

float DistortionRenderer::clamp(float val, float min, float max)
{
    return MAX(min, MIN(max, val));
}

//DistortionMesh

DistortionRenderer::DistortionMesh::DistortionMesh(EyeParams *eye, Distortion *distortion, float screenWidthM, float screenHeightM, float xEyeOffsetMScreen, float yEyeOffsetMScreen, float textureWidthM, float textureHeightM, float xEyeOffsetMTexture, float yEyeOffsetMTexture, float viewportXMTexture, float viewportYMTexture, float viewportWidthMTexture, float viewportHeightMTexture)
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
            float uTexture = col / 39.0F * (viewportWidthMTexture / textureWidthM) + viewportXMTexture / textureWidthM;
            
            float vTexture = row / 39.0F * (viewportHeightMTexture / textureHeightM) + viewportYMTexture / textureHeightM;
            
            float xTexture = uTexture * mPerUTexture;
            float yTexture = vTexture * mPerVTexture;
            float xTextureEye = xTexture - xEyeOffsetMTexture;
            float yTextureEye = yTexture - yEyeOffsetMTexture;
            float rTexture = sqrtf(xTextureEye * xTextureEye + yTextureEye * yTextureEye);
            
            float textureToScreen = rTexture > 0.0f ? distortion->distortInverse(rTexture) / rTexture : 1.0F;
            
            float xScreen = xTextureEye * textureToScreen + xEyeOffsetMScreen;
            float yScreen = yTextureEye * textureToScreen + yEyeOffsetMScreen;
            float uScreen = xScreen / mPerUScreen;
            float vScreen = yScreen / mPerVScreen;
            float vignetteSizeMTexture = 0.002F / textureToScreen;
            
            float dxTexture = xTexture - DistortionRenderer::clamp(xTexture, viewportXMTexture + vignetteSizeMTexture, viewportXMTexture + viewportWidthMTexture - vignetteSizeMTexture);
            float dyTexture = yTexture - DistortionRenderer::clamp(yTexture, viewportYMTexture + vignetteSizeMTexture, viewportYMTexture + viewportHeightMTexture - vignetteSizeMTexture);
            
            float drTexture = sqrtf(dxTexture * dxTexture + dyTexture * dyTexture);
            
            float vignette = 1.0f - DistortionRenderer::clamp(drTexture / vignetteSizeMTexture, 0.0f, 1.0f);
            
            vertexData[(vertexOffset + 0)] = (2.0F * uScreen - 1.0F);
            vertexData[(vertexOffset + 1)] = (2.0F * vScreen - 1.0F);
            vertexData[(vertexOffset + 2)] = vignette;
            vertexData[(vertexOffset + 3)] = uTexture;
            vertexData[(vertexOffset + 4)] = vTexture;
            
            vertexOffset += 5;
        }
    }
    
    this->indices = 3158;
    
    int indexOffset = 0;
    vertexOffset = 0;
    for (int row = 0; row < 39; row++)
    {
        if (row > 0)
        {
            indexData[indexOffset] = indexData[(indexOffset - 1)];
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
            indexData[(indexOffset++)] = vertexOffset;
            indexData[(indexOffset++)] = (vertexOffset + 40);
        }
        vertexOffset += 40;
    }
    
    GLuint bufferIds[2] = { 0, 0 };
    glGenBuffers(2, bufferIds);
    this->arrayBufferId = bufferIds[0];
    this->elementBufferId = bufferIds[1];
    
    glBindBuffer(34962, this->arrayBufferId);
    glBufferData(34962, sizeof(vertexData), vertexData, 35044);
    
    glBindBuffer(34963, this->elementBufferId);
    glBufferData(34963, sizeof(indexData), indexData, 35044);
    
    glBindBuffer(34962, 0);
    glBindBuffer(34963, 0);
    
}

//EyeViewport

NSString* DistortionRenderer::EyeViewport::toString()
{
    return [NSString stringWithFormat:@"EyeViewport {x:%f y:%f width:%f height:%f eyeX:%f, eyeY:%f}", this->x, this->y, this->width, this->height, this->eyeX, this->eyeY];
}
