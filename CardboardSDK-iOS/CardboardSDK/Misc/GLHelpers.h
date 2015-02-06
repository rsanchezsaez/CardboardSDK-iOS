//
//  GLHelpers.h
//  CardboardSDK-iOS
//

#ifndef _GLHelpers_h
#define _GLHelpers_h


#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>


#ifdef __cplusplus
  extern "C" {
#endif

      
#if defined(DEBUG)
  void GLCheckForError();
#else
  #define GLCheckForError()
#endif

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

BOOL GLCompileShader(GLuint *shader, GLenum type, const GLchar *source);
BOOL GLCompileShaderFromFile(GLuint *shader, GLenum type, NSString *file);
BOOL GLLinkProgram(GLuint program);
BOOL GLValidateProgram(GLuint program);

      
#ifdef __cplusplus
  }
#endif


#endif
