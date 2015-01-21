//
//  GLHelpers.h
//  CardboardSDK-iOS
//

#ifndef _GLHelpers_h
#define _GLHelpers_h

#import <Foundation/Foundation.h>

#import <OpenGLES/ES2/gl.h>


#ifdef DEBUG

    inline void checkGLError()
    {
        GLenum err = glGetError();
        if (err != GL_NO_ERROR)
        {
            NSLog(@"glError: 0x%04X", err);
            // assert(NO);
        }
    }

#else

    #define checkGLError() ;

#endif

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

class GLHelpers
{
  public:
    static BOOL compileShader(GLuint *shader, GLenum type, NSString *file);
    static BOOL linkProgram(GLuint program);
    static BOOL validateProgram(GLuint program);
};

#endif