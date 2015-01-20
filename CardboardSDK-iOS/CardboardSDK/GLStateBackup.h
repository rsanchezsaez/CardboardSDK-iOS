//
//  GLStateBackup.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__GLStateBackup__
#define __CardboardSDK_iOS__GLStateBackup__

#include <vector>
#import <OpenGLES/ES2/glext.h>

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
        VertexAttributeState(GLuint attributeId) :
        _attributeId(attributeId),
        _enabled(false)
        {
        }
        
        void readFromGL()
        {
            glGetVertexAttribiv(_attributeId, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &_enabled);
        }
        
        void writeToGL() {
            if (_enabled == false) {
                glDisableVertexAttribArray(_attributeId);
            }
            else
            {
                glEnableVertexAttribArray(_attributeId);
            }
        }
        
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

#endif /* defined(__CardboardSDK_iOS__GLStateBackup__) */
