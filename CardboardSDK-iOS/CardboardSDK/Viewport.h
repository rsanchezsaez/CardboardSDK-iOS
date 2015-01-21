//
//  Viewport.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__Viewport__
#define __CardboardSDK_iOS__Viewport__

#import <Foundation/Foundation.h>


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

    NSString *toString();
};

#endif 