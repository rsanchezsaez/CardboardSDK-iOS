//
//  GLHelpers.h
//  CardboardVR-iOS
//
//  Created by Ricardo Sánchez-Sáez on 13/01/2015.
//  Copyright (c) 2015 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


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
