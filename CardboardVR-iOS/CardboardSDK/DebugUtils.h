//
//  DebugUtils.h
//  CardboardVR-iOS
//
//  Created by Ricardo Sánchez-Sáez on 12/01/2015.
//  Copyright (c) 2015 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenGLES/ES2/gl.h>

inline void printGLError()
{
    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
    {
        NSLog(@"Error glGetError: glError: 0x%04X", err);
    }
}
