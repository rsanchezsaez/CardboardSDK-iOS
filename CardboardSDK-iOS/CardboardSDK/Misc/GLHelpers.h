//
//  GLHelpers.h
//  CardboardSDK-iOS
//

#ifndef _GLHelpers_h
#define _GLHelpers_h

#import <Foundation/Foundation.h>

#import <OpenGLES/ES2/gl.h>


#ifdef DEBUG

    static inline void GLCheckForError()
    {
        GLenum err = glGetError();
        if (err != GL_NO_ERROR)
        {
            NSLog(@"glError: 0x%04X", err);
            // assert(NO);
        }
    }

#else

    #define GLCheckForError()

#endif

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

BOOL GLCompileShader(GLuint *shader, GLenum type, NSString *file);
BOOL GLLinkProgram(GLuint program);
BOOL GLValidateProgram(GLuint program);

#endif