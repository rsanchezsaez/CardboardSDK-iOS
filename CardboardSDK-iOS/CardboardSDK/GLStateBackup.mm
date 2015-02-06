//
//  GLStateBackup.mm
//  CardboardSDK-iOS
//


#include "GLStateBackup.h"


namespace CardboardSDK
{

GLStateBackup::VertexAttributeState::VertexAttributeState(GLuint attributeId) :
    _attributeId(attributeId),
    _enabled(false)
{
}

void GLStateBackup::VertexAttributeState::readFromGL()
{
    glGetVertexAttribiv(_attributeId, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &_enabled);
}

void GLStateBackup::VertexAttributeState::writeToGL() {
    if (_enabled == false)
    {
        glDisableVertexAttribArray(_attributeId);
    }
    else
    {
        glEnableVertexAttribArray(_attributeId);
    }
}


GLStateBackup::GLStateBackup() :
    _cullFaceEnabled(false),
    _scissorTestEnabled(false),
    _depthTestEnabled(false),
    _shaderProgram(-1),
    _activeTexture(-1),
    _texture2DBinding(-1),
    _arrayBufferBinding(-1),
    _elementArrayBufferBinding(-1)
{
    for (int i = 0; i < 4; i++)
    {
        _viewport[i] = 0;
        _clearColor[i] = 0;
        _scissorBox[i] = 0;
    }
    
}

void GLStateBackup::addTrackedVertexAttribute(GLuint attributeId)
{
    _vertexAttributes.push_back(VertexAttributeState(attributeId));
}

void GLStateBackup::clearTrackedVertexAttributes()
{
    _vertexAttributes.clear();
}

void GLStateBackup::readFromGL() {
    glGetIntegerv(GL_VIEWPORT, _viewport);
    _cullFaceEnabled = glIsEnabled(GL_CULL_FACE);
    _scissorTestEnabled = glIsEnabled(GL_SCISSOR_TEST);
    _depthTestEnabled = glIsEnabled(GL_DEPTH_TEST);
    glGetFloatv(GL_COLOR_CLEAR_VALUE, _clearColor);
    glGetIntegerv(GL_CURRENT_PROGRAM, &_shaderProgram);
    glGetIntegerv(GL_SCISSOR_BOX, _scissorBox);
    glGetIntegerv(GL_ACTIVE_TEXTURE, &_activeTexture);
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &_texture2DBinding);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &_arrayBufferBinding);
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &_elementArrayBufferBinding);
    for (std::vector<VertexAttributeState>::iterator it = _vertexAttributes.begin();
         it != _vertexAttributes.end();
         ++it)
    {
        (*it).readFromGL();
    }
}

void GLStateBackup::writeToGL()
{
    for (std::vector<VertexAttributeState>::iterator it = _vertexAttributes.begin();
         it != _vertexAttributes.end();
         ++it)
    {
        (*it).writeToGL();
    }
    glBindBuffer(GL_ARRAY_BUFFER, _arrayBufferBinding);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _elementArrayBufferBinding);
    glBindTexture(GL_TEXTURE_2D, _texture2DBinding);
    glActiveTexture(_activeTexture);
    glScissor(_scissorBox[0], _scissorBox[1], _scissorBox[2], _scissorBox[3]);
    glUseProgram(_shaderProgram);
    glClearColor(_clearColor[0], _clearColor[1], _clearColor[2], _clearColor[3]);
    if (_cullFaceEnabled)
    {
        glEnable(GL_CULL_FACE);
    }
    else
    {
        glDisable(GL_CULL_FACE);
    }
    if (_scissorTestEnabled)
    {
        glEnable(GL_SCISSOR_TEST);
    }
    else
    {
        glDisable(GL_SCISSOR_TEST);
    }
    if (_depthTestEnabled)
    {
        glEnable(GL_DEPTH_TEST);
    }
    else {
        glDisable(GL_DEPTH_TEST);
    }
    glViewport(_viewport[0], _viewport[1], _viewport[2], _viewport[3]);
}

}