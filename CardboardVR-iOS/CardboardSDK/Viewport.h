//
//  Viewport.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-26.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#ifndef __CardboardVR_iOS__Viewport__
#define __CardboardVR_iOS__Viewport__

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#include "Structs.h"

class Viewport
{
public:
    int x;
    int y;
    int width;
    int height;
public:
    void setViewport(int x, int y, int width, int height);
    void setGLViewport();
    void setGLScissor();
    NSString* toString();
};

#endif 