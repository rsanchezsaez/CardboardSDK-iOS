//
//  DistortionRenderer.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "DistortionRenderer.h"
#import "DistortionMesh.h"
#import "EyeViewport.h"
#import "ProgramHolder.h"

@interface DistortionRenderer ()

@property (nonatomic, assign) GLuint textureId;
@property (nonatomic, assign) GLuint renderbufferId;
@property (nonatomic, assign) GLuint framebufferId;
@property (nonatomic, assign) int *originalFramebufferId;
@property (nonatomic, assign) int *cullFaceEnabled;
@property (nonatomic, assign) int *scissorTestEnabled;
@property (nonatomic, assign) int *viewport;
@property (nonatomic, assign) float resolutionScale;
@property (nonatomic, strong) DistortionMesh *leftEyeDistortionMesh;
@property (nonatomic, strong) DistortionMesh *rightEyeDistortionMesh;
@property (nonatomic, strong) HeadMountedDisplay *hmd;
@property (nonatomic, strong) FieldOfView *leftEyeFov;
@property (nonatomic, strong) FieldOfView *rightEyeFov;
@property (nonatomic, assign) ProgramHolder *programHolder;

@end

@implementation DistortionRenderer

- (id)init
{
    self = [super init];
    if (self)
    {
        self.textureId = -1;
        self.renderbufferId = -1;
        self.framebufferId = -1;
        self.originalFramebufferId = malloc(sizeof(UInt32));
        self.cullFaceEnabled = malloc(sizeof(UInt32));
        self.scissorTestEnabled = malloc(sizeof(UInt32));
        self.viewport = malloc(sizeof(UInt32) * 4);
        self.resolutionScale = 1.0F;
    }
    return self;
}

- (void)dealloc
{
    free(self.originalFramebufferId);
    free(self.cullFaceEnabled);
    free(self.scissorTestEnabled);
    free(self.viewport);
}

- (void)beforeDrawFrame
{
    glGetIntegerv(36006, self.originalFramebufferId);
    glBindFramebuffer(36160, self.framebufferId);
}

- (void)afterDrawFrame
{
    glBindFramebuffer(36160, self.originalFramebufferId[0]);
    glViewport(0, 0, [[self.hmd getScreen] getWidth], [[self.hmd getScreen] getHeight]);
    
    glGetIntegerv(2978, self.viewport);
    glGetIntegerv(2884, self.cullFaceEnabled);
    glGetIntegerv(3089, self.scissorTestEnabled);
    glDisable(3089);
    glDisable(2884);
    
    glClearColor(0.0F, 0.0F, 0.0F, 1.0F);
    glClear(16640);
    
    glUseProgram(self.programHolder.program);
    
    glEnable(3089);
    glScissor(0, 0, [[self.hmd getScreen] getWidth] / 2, [[self.hmd getScreen] getHeight]);
    
    [self renderDistortionMesh:self.leftEyeDistortionMesh];
    
    glScissor([[self.hmd getScreen] getWidth] / 2, 0, [[self.hmd getScreen] getWidth] / 2, [[self.hmd getScreen] getHeight]);
    
    [self renderDistortionMesh:self.rightEyeDistortionMesh];
    
    glDisableVertexAttribArray(self.programHolder.aPosition);
    glDisableVertexAttribArray(self.programHolder.aVignette);
    glDisableVertexAttribArray(self.programHolder.aTextureCoord);
    glUseProgram(0);
    glBindBuffer(34962, 0);
    glBindBuffer(34963, 0);
    glDisable(3089);
    if (self.cullFaceEnabled[0] == 1) {
        glEnable(2884);
    }
    if (self.scissorTestEnabled[0] == 1) {
        glEnable(3089);
    }
    glViewport(self.viewport[0], self.viewport[1], self.viewport[2], self.viewport[3]);
}

- (void)setResolutionScale:(float)scale
{
    self.resolutionScale = scale;
}

- (void)onProjectionChanged:(HeadMountedDisplay*)hmd leftEye:(EyeParams*)leftEye rightEye:(EyeParams*)rightEye zNear:(float)zNear zFar:(float)zFar
{
    self.hmd = [[HeadMountedDisplay alloc] initWithHeadMountedDisplay:hmd];
    self.leftEyeFov = [[FieldOfView alloc] initWitFieldOfView:[leftEye getFov]];
    self.rightEyeFov = [[FieldOfView alloc] initWitFieldOfView:[rightEye getFov]];
    
    ScreenParams *screen = [hmd getScreen];
    CardboardDeviceParams *cdp = [hmd getCardboard];
    
    if (self.programHolder == nil) {
        self.programHolder = [self createProgramHolder];
    }
    
    EyeViewport *leftEyeViewport = [self createViewportForEye:leftEye xOffsetM:0.0f];
    EyeViewport *rightEyeViewport = [self createViewportForEye:rightEye xOffsetM:leftEyeViewport.width];
    
    GLKMatrix4 leftEyeMatrix = [[leftEye getFov] toPerspectiveMatrix:zNear far:zFar];
    [[leftEye getTransform] setPerspective:leftEyeMatrix];
    GLKMatrix4 rightEyeMatrix = [[rightEye getFov] toPerspectiveMatrix:zNear far:zFar];
    [[rightEye getTransform] setPerspective:rightEyeMatrix];
    
    float textureWidthM = leftEyeViewport.width + rightEyeViewport.width;
    float textureHeightM = MAX(leftEyeViewport.height, rightEyeViewport.height);
    float xPxPerM = [screen getWidth] / [screen getWidthMeters];
    float yPxPerM = [screen getHeight] / [screen getHeightMeters];
    int textureWidthPx = round(textureWidthM * xPxPerM);
    int textureHeightPx = round(textureHeightM * yPxPerM);
    
    float xEyeOffsetMScreen = [screen getWidthMeters] / 2.0F - [cdp getInterpupillaryDistance] / 2.0F;
    float yEyeOffsetMScreen = [cdp getVerticalDistanceToLensCenter] - [screen getBorderSizeMeters];
    
    self.leftEyeDistortionMesh = [self createDistortionMesh:leftEye eyeViewport:leftEyeViewport textureWidthM:textureWidthM textureHeightM:textureHeightM xEyeOffsetMScreen:xEyeOffsetMScreen yEyeOffsetMScreen:yEyeOffsetMScreen];
    
    xEyeOffsetMScreen = [screen getWidthMeters] - xEyeOffsetMScreen;
    self.rightEyeDistortionMesh = [self createDistortionMesh:rightEye eyeViewport:rightEyeViewport textureWidthM:textureWidthM textureHeightM:textureHeightM xEyeOffsetMScreen:xEyeOffsetMScreen yEyeOffsetMScreen:yEyeOffsetMScreen];
    
    [self setupRenderTextureAndRenderbuffer:textureWidthPx height:textureHeightPx];
}

- (EyeViewport*)createViewportForEye:(EyeParams*)eye xOffsetM:(float)xOffsetM
{
    ScreenParams *screen = [self.hmd getScreen];
    CardboardDeviceParams *cdp = [self.hmd getCardboard];
    
    float eyeToScreenDistanceM = [cdp getEyeToLensDistance] + [cdp getScreenToLensDistance];
    
    float leftM = tanf([[eye getFov] getLeft] * (M_PI / 180.0f)) * eyeToScreenDistanceM;
    float rightM = tanf([[eye getFov] getRight] * (M_PI / 180.0f)) * eyeToScreenDistanceM;
    float bottomM = tanf([[eye getFov] getBottom] * (M_PI / 180.0f)) * eyeToScreenDistanceM;
    float topM = tanf([[eye getFov] getTop] * (M_PI / 180.0f)) * eyeToScreenDistanceM;
    
    EyeViewport *vp = [[EyeViewport alloc] init];
    vp.x = xOffsetM;
    vp.y = 0.0F;
    vp.width = (leftM + rightM);
    vp.height = (bottomM + topM);
    vp.eyeX = (leftM + xOffsetM);
    vp.eyeY = bottomM;
    
    float xPxPerM = [screen getWidth] / [screen getWidthMeters];
    float yPxPerM = [screen getHeight] / [screen getHeightMeters];
    [eye getViewport].x = round(vp.x * xPxPerM);
    [eye getViewport].y = round(vp.y * yPxPerM);
    [eye getViewport].width = round(vp.width * xPxPerM);
    [eye getViewport].height = round(vp.height * yPxPerM);
    
    return vp;
}

- (DistortionMesh*)createDistortionMesh:(EyeParams*)eye eyeViewport:(EyeViewport*)eyeViewport textureWidthM:(float)textureWidthM textureHeightM:(float)textureHeightM  xEyeOffsetMScreen:(float)xEyeOffsetMScreen yEyeOffsetMScreen:(float)yEyeOffsetMScreen
{
    return [[DistortionMesh alloc] initWithEyeParams:eye distortion:[[self.hmd getCardboard] getDistortion] screenWidthM:[[self.hmd getScreen] getWidthMeters] screenHeightM:[[self.hmd getScreen] getHeightMeters] xEyeOffsetMScreen:xEyeOffsetMScreen yEyeOffsetMScreen:yEyeOffsetMScreen textureWidthM:textureWidthM textureHeightM:textureHeightM xEyeOffsetMTexture:eyeViewport.eyeX yEyeOffsetMTexture:eyeViewport.eyeY viewportXMTexture:eyeViewport.x viewportYMTexture:eyeViewport.y viewportWidthMTexture:eyeViewport.width viewportHeightMTexture:eyeViewport.height];
}

- (void)renderDistortionMesh:(DistortionMesh*)mesh
{
    glBindBuffer(34962, mesh.arrayBufferId);
    glVertexAttribPointer(self.programHolder.aPosition, 3, 5126, false, 5 * sizeof(Float32), &mesh.vertexData[0]);
    glEnableVertexAttribArray(self.programHolder.aPosition);
    glVertexAttribPointer(self.programHolder.aVignette, 1, 5126, false, 5 * sizeof(Float32), &mesh.vertexData[2 * sizeof(Float32)]);
    glEnableVertexAttribArray(self.programHolder.aVignette);
    glVertexAttribPointer(self.programHolder.aTextureCoord, 2, 5126, false, 5 * sizeof(Float32), &mesh.vertexData[3 * sizeof(Float32)]);
    glEnableVertexAttribArray(self.programHolder.aTextureCoord);
    
    glActiveTexture(33984);
    glBindTexture(3553, self.textureId);
    glUniform1i(self.programHolder.uTextureSampler, 0);
    glUniform1f(self.programHolder.uTextureCoordScale, self.resolutionScale);
    
    glBindBuffer(34963, mesh.elementBufferId);
    glDrawElements(5, mesh.indices, 5125, 0);
}

- (float)computeDistortionScale:(Distortion*)distortion screenWidthM:(float)screenWidthM interpupillaryDistanceM:(float)interpupillaryDistanceM
{
    return [distortion distortionFactor:(screenWidthM / 2.0F - interpupillaryDistanceM / 2.0F) / (screenWidthM / 4.0F)];
}

- (int)createTexture:(int)width height:(int)height
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

- (int)setupRenderTextureAndRenderbuffer:(int)width height:(int)height
{
    GLuint textureId = self.textureId;
    if (textureId != -1) {
        glDeleteTextures(1, &textureId);
    }
    GLuint renderbufferId = self.renderbufferId;
    if (renderbufferId != -1) {
        glDeleteRenderbuffers(1, &renderbufferId);
    }
    GLuint framebufferId = self.framebufferId;
    if (framebufferId != -1) {
        glDeleteFramebuffers(1, &framebufferId);
    }
    
    self.textureId = [self createTexture:width height:height];
    [self checkGlError:@"setupRenderTextureAndRenderbuffer: create texture"];
    
    GLuint renderbufferIds;
    glGenRenderbuffers(1, &renderbufferIds);
    glBindRenderbuffer(36161, renderbufferIds);
    glRenderbufferStorage(36161, 33189, width, height);
    
    self.renderbufferId = renderbufferIds;
    [self checkGlError:@"setupRenderTextureAndRenderbuffer: create renderbuffer"];
    
    GLuint framebufferIds;
    glGenFramebuffers(1, &framebufferIds);
    glBindFramebuffer(36160, framebufferIds);
    self.framebufferId = framebufferIds;
    
    glFramebufferTexture2D(36160, 36064, 3553, self.textureId, 0);
    
    glFramebufferRenderbuffer(36160, 36096, 36161, renderbufferIds);
    
    GLuint status = glCheckFramebufferStatus(36160);
    if (status != 36053) {
        [NSException raise:@"DistortionRenderer" format:@"Framebuffer is not complete: %d", status];
    }
    
    glBindFramebuffer(36160, 0);
    
    return framebufferIds;
}

- (int)loadShader:(GLenum)shaderType source:(const GLchar*)source
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

- (int)createProgram:(const GLchar*)vertexSource  fragmentSource:(const GLchar*)fragmentSource
{
    GLuint vertexShader = [self loadShader:35633 source:vertexSource];
    if (vertexShader == 0) {
        return 0;
    }
    GLuint pixelShader = [self loadShader:35632 source:fragmentSource];
    if (pixelShader == 0) {
        return 0;
    }
    GLuint program = glCreateProgram();
    if (program != 0) {
        glAttachShader(program, vertexShader);
        [self checkGlError:@"glAttachShader"];
        glAttachShader(program, pixelShader);
        [self checkGlError:@"glAttachShader"];
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

- (ProgramHolder*)createProgramHolder
{
    ProgramHolder *holder = [[ProgramHolder alloc] init];
    [self createProgram:"attribute vec2 aPosition;\nattribute float aVignette;\nattribute vec2 aTextureCoord;\nvarying vec2 vTextureCoord;\nvarying float vVignette;\nuniform float uTextureCoordScale;\nvoid main() {\n    gl_Position = vec4(aPosition, 0.0, 1.0);\n    vTextureCoord = aTextureCoord.xy * uTextureCoordScale;\n    vVignette = aVignette;\n}\n" fragmentSource:"precision mediump float;\nvarying vec2 vTextureCoord;\nvarying float vVignette;\nuniform sampler2D uTextureSampler;\nvoid main() {\n    gl_FragColor = vVignette * texture2D(uTextureSampler, vTextureCoord);\n}\n"];
    if (holder.program == 0) {
        [NSException raise:@"DistortionRenderer" format:@"Could not create program"];
    }
    holder.aPosition = glGetAttribLocation(holder.program, "aPosition");
    [self checkGlError:@"glGetAttribLocation aPosition"];
    if (holder.aPosition == -1) {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aPosition"];
    }
    holder.aVignette = glGetAttribLocation(holder.program, "aVignette");
    [self checkGlError:@"glGetAttribLocation aVignette"];
    if (holder.aVignette == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aVignette"];
    }
    holder.aTextureCoord = glGetAttribLocation(holder.program, "aTextureCoord");
    [self checkGlError:@"glGetAttribLocation aTextureCoord"];
    if (holder.aTextureCoord == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for aTextureCoord"];
    }
    holder.uTextureCoordScale = glGetUniformLocation(holder.program, "uTextureCoordScale");
    [self checkGlError:@"glGetUniformLocation uTextureCoordScale"];
    if (holder.uTextureCoordScale == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for uTextureCoordScale"];
    }
    holder.uTextureSampler = glGetUniformLocation(holder.program, "uTextureSampler");
    [self checkGlError:@"glGetUniformLocation uTextureSampler"];
    if (holder.uTextureSampler == -1)
    {
        [NSException raise:@"DistortionRenderer" format:@"Could not get attrib location for uTextureSampler"];
    }
    return holder;
}

- (void)checkGlError:(NSString*)op
{
    int error = glGetError();
    if (error != 0) {
        [NSException raise:@"DistortionRenderer" format:@"%@: glError %d", op, error];
    }
}

+ (float)clamp:(float)val min:(float)min max:(float)max
{
    return MAX(min, MIN(max, val));
}

@end


