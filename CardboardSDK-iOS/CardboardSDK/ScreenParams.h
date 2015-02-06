//
//  ScreenParams.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__ScreenParams__
#define __CardboardSDK_iOS__ScreenParams__

#import <UIKit/UIKit.h>


namespace CardboardSDK
{

class ScreenParams
{
  public:
    ScreenParams(UIScreen *screen);
    ScreenParams(ScreenParams *screenParams);

    int width();
    int height();

    float widthInMeters();
    float heightInMeters();

    void setBorderSizeInMeters(float screenBorderSize);
    float borderSizeInMeters();

    bool equals(ScreenParams *other);

  private:
    UIScreen *_screen;
    CGFloat _scale;
    float _xMetersPerPixel;
    float _yMetersPerPixel;
    float _borderSizeMeters;

    float pixelsPerInch(UIScreen *screen);
};

}

#endif
