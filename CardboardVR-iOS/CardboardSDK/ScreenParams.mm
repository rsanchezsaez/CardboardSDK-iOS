//
//  ScreenParams.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-26.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "ScreenParams.h"
#include <sys/utsname.h>

ScreenParams::ScreenParams(UIScreen *screen)
{
    this->width = screen.bounds.size.width * screen.nativeScale;
    this->height = screen.bounds.size.height  * screen.nativeScale;
    float pixelsPerInch = this->pixelsPerInch(screen);
    
    const float metersPerInch = 0.0254f;
    const float defaultBorderSizeMeters = 0.003f;
    this->xMetersPerPixel = (metersPerInch / pixelsPerInch);
    this->yMetersPerPixel = (metersPerInch / pixelsPerInch);
    this->borderSizeMeters = defaultBorderSizeMeters;
}

ScreenParams::ScreenParams(ScreenParams *screenParams)
{
    this->width = screenParams->getWidth();
    this->height = screenParams->getHeight();
    this->xMetersPerPixel = screenParams->getWidthMeters() / (float)this->width;
    this->yMetersPerPixel =  screenParams->getHeightMeters() / (float)this->height;
    this->borderSizeMeters = screenParams->getBorderSizeMeters();
}

void ScreenParams::setWidth(int width)
{
    this->width = width;
}

int ScreenParams::getWidth()
{
    return this->width;
}

void ScreenParams::setHeight(int height)
{
    this->height = height;
}

int ScreenParams::getHeight()
{
    return this->height;
}

float ScreenParams::getWidthMeters()
{
    return this->width * this->xMetersPerPixel;
}

float ScreenParams::getHeightMeters()
{
    return this->height * this->yMetersPerPixel;
}

void ScreenParams::setBorderSizeMeters(float screenBorderSize)
{
    this->borderSizeMeters = screenBorderSize;
}

float ScreenParams::getBorderSizeMeters()
{
    return this->borderSizeMeters;
}

bool ScreenParams::equals(ScreenParams *other)
{
    if (other == nullptr) {
        return false;
    }
    if (other == this) {
        return true;
    }
    return (this->getWidth() == other->getWidth()) && (this->getHeight() == other->getHeight()) && (this->getWidthMeters() == other->getWidthMeters()) && (this->getHeightMeters() == other->getHeightMeters()) && (this->getBorderSizeMeters() == other->getBorderSizeMeters());
}

float ScreenParams::pixelsPerInch(UIScreen* screen)
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
                    pixelsPerInch = [deviceClass[@"pointsPerInch"] floatValue] * [screen nativeScale];
                    break;
                }
            }
        }
    }
    return pixelsPerInch;
}