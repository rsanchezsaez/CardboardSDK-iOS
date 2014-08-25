//
//  Viewport.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>

struct _ViewportRect
{
    int r[4];
};
typedef struct _ViewportRect ViewportRect;

@interface Viewport : NSObject

@property (nonatomic, assign) int x;
@property (nonatomic, assign) int y;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;

- (void)setViewport:(int)x y:(int)y width:(int)width height:(int)height;
- (void)setGLViewport;
- (void)setGLScissor;
- (ViewportRect)getAsViewportRect;
- (NSString *)toString;

@end
