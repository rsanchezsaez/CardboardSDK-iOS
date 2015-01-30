//
//  GLHelpers.m
//  CardboardSDK-iOS
//

#import "GLHelpers.h"


#if defined(DEBUG)
void GLCheckForError()
{
    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
    {
        NSLog(@"glError: 0x%04X", err);
        // assert(NO);
    }
}
#endif

BOOL GLCompileShader(GLuint *shader, GLenum type, const GLchar *source)
{
    if (!source) {
        NSLog(@"Failed to read shader source");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength = 0;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    GLint status = 0;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

BOOL GLCompileShaderFromFile(GLuint *shader, GLenum type, NSString *file)
{
    const GLchar *source = (GLchar *)[[NSString stringWithContentsOfFile:file
                                                                encoding:NSUTF8StringEncoding
                                                                   error:nil] UTF8String];
    return GLCompileShader(shader, type, source);
}

BOOL GLLinkProgram(GLuint program)
{
    GLint status;
    glLinkProgram(program);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == 0)
    {
        return NO;
    }
    
    return YES;
}

BOOL GLValidateProgram(GLuint program)
{
    GLint logLength, status;
    
    glValidateProgram(program);
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(program, GL_VALIDATE_STATUS, &status);
    if (status == 0)
    {
        return NO;
    }
    
    return YES;
}
