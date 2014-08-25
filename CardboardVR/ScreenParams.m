//
//  ScreenParams.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-24.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "ScreenParams.h"
#include <sys/utsname.h>

@interface ScreenParams ()

@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) float xMetersPerPixel;
@property (nonatomic, assign) float yMetersPerPixel;
@property (nonatomic, assign) float borderSizeMeters;

@end

@implementation ScreenParams

const float METERS_PER_INCH = 0.0254f;
const float DEFAULT_BORDER_SIZE_METERS = 0.003f;

- (float)pixelsPerInch:(UIScreen*)screen
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

- (id)initWithScreen:(UIScreen*)screen
{
    self = [super init];
    if (self)
    {
        self.width = screen.nativeBounds.size.width;
        self.height = screen.nativeBounds.size.height;
        float pixelsPerInch = [self pixelsPerInch:screen];
        self.xMetersPerPixel = (METERS_PER_INCH / pixelsPerInch);
        self.yMetersPerPixel = (METERS_PER_INCH / pixelsPerInch);
        self.borderSizeMeters = 0.003f;
    }
    return self;
}

- (id)initWithScreenParams:(ScreenParams*)screenParams
{
    self = [super init];
    if (self)
    {
        self.width = [screenParams getWidth];
        self.height = [screenParams getHeight];
        self.xMetersPerPixel = [screenParams getWidthMeters] / (float)self.width;
        self.yMetersPerPixel =  [screenParams getHeightMeters] / (float)self.height;
        self.borderSizeMeters = [screenParams getBorderSizeMeters];
    }
    return self;
}

- (void)setWidth:(int)width
{
    self.width = width;
}

- (int)getWidth
{
    return self.width;
}

- (void)setHeight:(int)height
{
    self.height = height;
}

- (int)getHeight
{
    return self.height;
}

- (float)getWidthMeters
{
    return self.width * self.xMetersPerPixel;
}

- (float)getHeightMeters
{
    return self.height * self.yMetersPerPixel;
}

- (void)setBorderSizeMeters:(float)screenBorderSize
{
    self.borderSizeMeters = screenBorderSize;
}

- (float)getBorderSizeMeters
{
    return self.borderSizeMeters;
}

- (bool)equals:(id)other
{
    if (other == nil)
    {
        return false;
    }
    if (other == self)
    {
        return true;
    }
    if (![other isKindOfClass:[ScreenParams class]])
    {
        return false;
    }
    
    ScreenParams *o = (ScreenParams *)other;
    return (self.getWidth == [o getWidth]) && (self.getHeight == [o getHeight]) && (self.getWidthMeters == [o getWidthMeters]) && (self.getHeightMeters == [o getHeightMeters]) && (self.getBorderSizeMeters == [o getBorderSizeMeters]);
}

@end
