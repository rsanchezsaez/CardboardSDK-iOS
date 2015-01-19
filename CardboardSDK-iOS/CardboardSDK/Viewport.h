//
//  Viewport.h
//  CardboardSDK-iOS
//
//

#ifndef __CardboardVR_iOS__Viewport__
#define __CardboardVR_iOS__Viewport__

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

struct Viewport
{
  public:
    int x;
    int y;
    int width;
    int height;

    void setViewport(int x, int y, int width, int height);

    void setGLViewport();
    void setGLScissor();

    NSString* toString();
};

#endif 