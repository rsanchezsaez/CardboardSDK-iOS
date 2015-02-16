//
//  Viewport.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__Viewport__
#define __CardboardSDK_iOS__Viewport__

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


namespace CardboardSDK
{

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

    CGRect toCGRect();
    NSString *toString();
};

}

#endif