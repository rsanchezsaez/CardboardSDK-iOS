//
//  GLHelpers.m
//  CardboardSDK-iOS
//

#import "GLHelpers.h"



BOOL GLHelpers::compileShader(GLuint *shader, GLenum type, NSString *file)
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

BOOL GLHelpers::linkProgram(GLuint program)
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

BOOL GLHelpers::validateProgram(GLuint program)
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
