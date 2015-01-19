//
//  DistortionRenderer.h
//  CardboardSDK-iOS
//
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
        int _indices;
        int _arrayBufferID;
        int _elementBufferID;
        float _vertexData[8000];
        unsigned int _indexData[3158];
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
    
    struct EyeViewport
    {
      public:
        float x;
        float y;
        float width;
        float height;
        float eyeX;
        float eyeY;

        NSString* toString();
    };
    
    struct ProgramHolder
    {
      public:
        int program;
        int positionLocation;
        int vignetteLocation;
        int textureCoordLocation;
        int uTextureCoordScaleLocation;
        int uTextureSamplerLocation;
    };
    
    // int _originalFramebufferID;
    GLuint _framebufferID;
    GLuint _textureID;
    GLuint _renderbufferID;
    GLboolean _cullFaceEnabled;
    GLboolean _scissorTestEnabled;
    int _viewport[4];
    float _resolutionScale;
    DistortionMesh *_leftEyeDistortionMesh;
    DistortionMesh *_rightEyeDistortionMesh;
    HeadMountedDisplay *_headMountedDisplay;
    FieldOfView *_leftEyeFov;
    FieldOfView *_rightEyeFov;
    ProgramHolder *_programHolder;
  
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
    static float clamp(float val, float min, float max);
    
};

#endif
