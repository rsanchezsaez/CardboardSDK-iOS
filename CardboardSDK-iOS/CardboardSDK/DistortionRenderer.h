//
//  DistortionRenderer.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-29.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#ifndef __CardboardVR_iOS__DistortionRenderer__
#define __CardboardVR_iOS__DistortionRenderer__

#import <GLKit/GLKit.h>
#include "HeadMountedDisplay.h"
#include "EyeParams.h"
#include "Distortion.h"
#include "FieldOfView.h"

class DistortionRenderer
{
public:
    DistortionRenderer();
    ~DistortionRenderer();
    void beforeDrawFrame();
    void afterDrawFrame();
    void setResolutionScale(float scale);
    void onProjectionChanged(HeadMountedDisplay *hmd,
                             EyeParams *leftEye,
                             EyeParams *rightEye,
                             float zNear,
                             float zFar);
private:
    
    class DistortionMesh
    {
    public:
        int indices;
        int arrayBufferId;
        int elementBufferId;
        float vertexData[8000];
        unsigned int indexData[3158];
    public:
        DistortionMesh();
        DistortionMesh(EyeParams *eye,
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
                       float viewportHeightMTexture);
    };
    
    class EyeViewport
    {
    public:
        float x;
        float y;
        float width;
        float height;
        float eyeX;
        float eyeY;
    public:
        NSString* toString();
    };
    
    class ProgramHolder
    {
    public:
        int program;
        int aPosition;
        int aVignette;
        int aTextureCoord;
        int uTextureCoordScale;
        int uTextureSampler;
    };
    
    //int originalFramebufferId;
    GLuint framebufferId;
    GLuint textureId;
    GLuint renderbufferId;
    GLboolean cullFaceEnabled;
    GLboolean scissorTestEnabled;
    int viewport[4];
    float resolutionScale;
    DistortionMesh *leftEyeDistortionMesh;
    DistortionMesh *rightEyeDistortionMesh;
    HeadMountedDisplay *hmd;
    FieldOfView *leftEyeFov;
    FieldOfView *rightEyeFov;
    ProgramHolder *programHolder;
private:
    EyeViewport initViewportForEye(EyeParams *eye, float xOffsetM);
    DistortionMesh* createDistortionMesh(EyeParams *eye,
                                         EyeViewport eyeViewport,
                                         float textureWidthM,
                                         float textureHeightM,
                                         float xEyeOffsetMScreen,
                                         float yEyeOffsetMScreen);
    void renderDistortionMesh(DistortionMesh *mesh);
    float computeDistortionScale(Distortion *distortion,
                                 float screenWidthM,
                                 float interpupillaryDistanceM);
    int createTexture(int width, int height);
    int setupRenderTextureAndRenderbuffer(int width, int height);
    int loadShader(GLenum shaderType, const GLchar *source);
    int createProgram(const GLchar *vertexSource,
                      const GLchar *fragmentSource);
    ProgramHolder* createProgramHolder();
    void checkGlError(NSString* op);
    static float clamp(float val, float min, float max);
    
};

#endif
