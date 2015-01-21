//
//  GLHelpers.h
//  CardboardSDK-iOS
//

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

@interface GLHelpers : NSObject

+ (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
+ (BOOL)linkProgram:(GLuint)prog;
+ (BOOL)validateProgram:(GLuint)prog;


@end
