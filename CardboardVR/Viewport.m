//
//  Viewport.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "Viewport.h"
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@implementation Viewport

- (void)setViewport:(int)x y:(int)y width:(int)width height:(int)height
{
    self.x = x;
    self.y = y;
    self.width = width;
    self.height = height;
}

- (void)setGLViewport
{
    glViewport(self.x, self.y, self.width, self.height);
}

- (void)setGLScissor
{
    glScissor(self.x, self.y, self.width, self.height);
}

- (ViewportRect)getAsViewportRect
{
    ViewportRect viewportRect;
    viewportRect.r[0] = self.x;
    viewportRect.r[1] = self.y;
    viewportRect.r[2] = self.width;
    viewportRect.r[3] = self.height;
    return viewportRect;
}

- (NSString *)toString
{
    return [NSString stringWithFormat:@"Viewport {x:%d y:%d width:%d height:%d}", self.x, self.y, self.width, self.height];
}

@end
