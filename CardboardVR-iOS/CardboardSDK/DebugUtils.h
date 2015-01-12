//
//  DebugUtils.h
//  CardboardVR-iOS
//
//  Created by Ricardo Sánchez-Sáez on 12/01/2015.
//  Copyright (c) 2015 Peter Tribe. All rights reserved.
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