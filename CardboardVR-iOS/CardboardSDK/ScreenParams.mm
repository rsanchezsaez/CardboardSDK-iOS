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
    this->width = screen.bounds.size.width;
    this->height = screen.bounds.size.height;
    float pixelsPerInch = this->pixelsPerInch(screen);
    this->xMetersPerPixel = (0.0254f / pixelsPerInch);
    this->yMetersPerPixel = (0.0254f / pixelsPerInch);
    this->borderSizeMeters = 0.003f;
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
    float pixelsPerInch = 163.0f;
    struct utsname sysinfo;
    if (uname(&sysinfo) == 0) {
        NSString *identifier = [NSString stringWithUTF8String:sysinfo.machine];
        NSArray *deviceArray = @[@{@"identifiers": @[@"iPad1,1", @"iPad2,1", @"iPad2,2", @"iPad2,3", @"iPad2,4", @"iPad3,1", @"iPad3,2", @"iPad3,3", @"iPad3,4", @"iPad3,5", @"iPad3,6", @"iPad4,1", @"iPad4,2"], @"pointsPerInch": @132.0f}, @{@"identifiers": @[@"iPod5,1", @"iPhone1,1", @"iPhone1,2", @"iPhone2,1", @"iPhone3,1", @"iPhone3,2", @"iPhone3,3", @"iPhone4,1", @"iPhone5,1", @"iPhone5,2", @"iPhone5,3", @"iPhone5,4", @"iPhone6,1", @"iPhone6,2", @"iPad2,5", @"iPad2,6", @"iPad2,7", @"iPad4,4", @"iPad4,5", @"i386", @"x86_64"], @"pointsPerInch":  @163.0f}];
        for (id device in deviceArray)
        {
            for (NSString *deviceId in [device objectForKey:@"identifiers"])
            {
                if ([identifier isEqualToString:deviceId]) {
                    pixelsPerInch = [[device objectForKey:@"pointsPerInch"] floatValue] * [screen scale];
                    break;
                }
            }
        }
    }
    return pixelsPerInch;
}