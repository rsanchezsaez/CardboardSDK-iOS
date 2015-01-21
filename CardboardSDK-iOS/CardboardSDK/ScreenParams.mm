//
//  ScreenParams.mm
//  CardboardSDK-iOS
//


#include "ScreenParams.h"

#include <sys/utsname.h>


@interface UIScreen (OrientationAware)

- (CGSize)orientationAwareSize;

@end

@implementation UIScreen (OrientationAware)

- (CGSize)orientationAwareSize
{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1)
        && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
    {
        return CGSizeMake(screenSize.height, screenSize.width);
    }
    return screenSize;
}

@end


ScreenParams::ScreenParams(UIScreen *screen)
{
    if ([screen respondsToSelector:@selector(nativeScale)])
    {
        _scale = screen.nativeScale;
    }
    else
    {
        _scale = screen.scale;
    }
    
    CGSize screenSize = [screen orientationAwareSize];
    _width = screenSize.width * _scale;
    _height = screenSize.height  * _scale;
    float screenPixelsPerInch = pixelsPerInch(screen);
    
    const float metersPerInch = 0.0254f;
    const float defaultBorderSizeMeters = 0.003f;
    _xMetersPerPixel = (metersPerInch / screenPixelsPerInch);
    _yMetersPerPixel = (metersPerInch / screenPixelsPerInch);
    _borderSizeMeters = defaultBorderSizeMeters;
}

ScreenParams::ScreenParams(ScreenParams *screenParams)
{
    _scale = screenParams->_scale;
    _width = screenParams->_width;
    _height = screenParams->_height;
    _xMetersPerPixel = screenParams->_xMetersPerPixel;
    _yMetersPerPixel = screenParams->_yMetersPerPixel;
    _borderSizeMeters = screenParams->_borderSizeMeters;
}

void ScreenParams::setWidth(int width)
{
    _width = width;
}

int ScreenParams::width()
{
    return _width;
}

void ScreenParams::setHeight(int height)
{
    _height = height;
}

int ScreenParams::height()
{
    return _height;
}

float ScreenParams::widthInMeters()
{
    float meters = _width * _xMetersPerPixel;
    return meters;
}

float ScreenParams::heightInMeters()
{
    float meters = _height * _yMetersPerPixel;
    return meters;
}

void ScreenParams::setBorderSizeInMeters(float screenBorderSize)
{
    _borderSizeMeters = screenBorderSize;
}

float ScreenParams::borderSizeInMeters()
{
    return _borderSizeMeters;
}

bool ScreenParams::equals(ScreenParams *other)
{
    if (other == nullptr)
    {
        return false;
    }
    else if (other == this)
    {
        return true;
    }
    return
    (width() == other->width())
    && (height() == other->height())
    && (widthInMeters() == other->widthInMeters())
    && (heightInMeters() == other->heightInMeters())
    && (borderSizeInMeters() == other->borderSizeInMeters());
}

float ScreenParams::pixelsPerInch(UIScreen *screen)
{
    // Default iPhone retina pixels per inch
    float pixelsPerInch = 163.0f * 2;
    struct utsname sysinfo;
    if (uname(&sysinfo) == 0)
    {
        NSString *identifier = [NSString stringWithUTF8String:sysinfo.machine];
        NSArray *deviceClassArray =
  @[
    // iPads
  @{@"identifiers":
        @[@"iPad1,1",
          @"iPad2,1", @"iPad2,2", @"iPad2,3", @"iPad2,4",
          @"iPad3,1", @"iPad3,2", @"iPad3,3", @"iPad3,4",
          @"iPad3,5", @"iPad3,6", @"iPad4,1", @"iPad4,2"],
    @"pointsPerInch": @132.0f},
  // iPhones, iPad Minis and simulators
  @{@"identifiers":
        @[@"iPod5,1",
          @"iPhone1,1", @"iPhone1,2",
          @"iPhone2,1",
          @"iPhone3,1", @"iPhone3,2", @"iPhone3,3",
          @"iPhone4,1",
          @"iPhone5,1", @"iPhone5,2", @"iPhone5,3", @"iPhone5,4",
          @"iPhone6,1", @"iPhone6,2",
          @"iPhone7,1", @"iPhone7,2",
          @"iPad2,5", @"iPad2,6", @"iPad2,7",
          @"iPad4,4", @"iPad4,5",
          @"i386", @"x86_64"],
    @"pointsPerInch":  @163.0f } ];
        for (NSDictionary *deviceClass in deviceClassArray)
        {
            for (NSString *deviceId in deviceClass[@"identifiers"])
            {
                if ([identifier isEqualToString:deviceId])
                {
                    pixelsPerInch = [deviceClass[@"pointsPerInch"] floatValue] * _scale;
                    break;
                }
            }
        }
    }
    return pixelsPerInch;
}