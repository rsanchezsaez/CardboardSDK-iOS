//
//  GLStateBackup.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__GLStateBackup__
#define __CardboardSDK_iOS__GLStateBackup__

#include <vector>

#import <OpenGLES/ES2/gl.h>


namespace CardboardSDK
{

class GLStateBackup
{
  public:
    GLStateBackup();
    void addTrackedVertexAttribute(GLuint attributeId);
    void clearTrackedVertexAttributes();
    void readFromGL();
    void writeToGL();
    
  private:
    class VertexAttributeState
    {
      public:
        VertexAttributeState(GLuint attributeId);
        
        void readFromGL();
        void writeToGL();
        
      private:
        GLuint _attributeId;
        GLint _enabled;
    };
    

    GLint _viewport[4];
    bool _cullFaceEnabled;
    bool _scissorTestEnabled;
    bool _depthTestEnabled;
    GLfloat _clearColor[4];
    GLint _shaderProgram;
    GLint _scissorBox[4];
    GLint _activeTexture;
    GLint _texture2DBinding;
    GLint _arrayBufferBinding;
    GLint _elementArrayBufferBinding;
    std::vector<VertexAttributeState> _vertexAttributes;
};

}

#endif /* defined(__CardboardSDK_iOS__GLStateBackup__) */
