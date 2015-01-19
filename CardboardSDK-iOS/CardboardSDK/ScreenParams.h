//
//  ScreenParams.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__ScreenParams__
#define __CardboardSDK_iOS__ScreenParams__

#import <UIKit/UIKit.h>


class ScreenParams
{
  public:
    ScreenParams(UIScreen *screen);
    ScreenParams(ScreenParams *screenParams);

    void setWidth(int width);
    int width();

    void setHeight(int height);
    int height();

    float widthInMeters();
    float heightInMeters();

    void setBorderSizeInMeters(float screenBorderSize);
    float borderSizeInMeters();

    bool equals(ScreenParams *other);

  private:
    CGFloat _scale;
    int _width;
    int _height;
    float _xMetersPerPixel;
    float _yMetersPerPixel;
    float _borderSizeMeters;

    float pixelsPerInch(UIScreen *screen);
};


#endif
