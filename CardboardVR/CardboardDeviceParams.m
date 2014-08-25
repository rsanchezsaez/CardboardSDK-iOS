//
//  CardboardDeviceParams.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-24.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "CardboardDeviceParams.h"
#import <UIKit/UIKit.h>

@interface CardboardDeviceParams ()

@property (nonatomic, strong) NSString *vendor;
@property (nonatomic, strong) NSString *model;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, assign) float interpupillaryDistance;
@property (nonatomic, assign) float verticalDistanceToLensCenter;
@property (nonatomic, assign) float lensDiameter;
@property (nonatomic, assign) float screenToLensDistance;
@property (nonatomic, assign) float eyeToLensDistance;
@property (nonatomic, assign) float visibleViewportSize;
@property (nonatomic, assign) float fovY;
@property (nonatomic, strong) Distortion *distortion;

@end

@implementation CardboardDeviceParams

- (id)init
{
    self = [super init];
    if (self)
    {
        self.vendor = @"com.google";
        self.model = @"cardboard";
        self.version = @"1.0";
        
        self.interpupillaryDistance = 0.06F;
        self.verticalDistanceToLensCenter = 0.035F;
        self.lensDiameter = 0.025F;
        self.screenToLensDistance = 0.037F;
        self.eyeToLensDistance = 0.011F;
        
        self.visibleViewportSize = 0.06F;
        self.fovY = 65.0F;
        
        self.distortion = [[Distortion alloc] init];
    }
    return self;
}

- (id)initWithCardboardDeviceParams:(CardboardDeviceParams*)params
{
    self = [super init];
    if (self)
    {
        self.vendor = params.vendor;
        self.model = params.model;
        self.version = params.version;
        
        self.interpupillaryDistance = params.interpupillaryDistance;
        self.verticalDistanceToLensCenter = params.verticalDistanceToLensCenter;
        self.lensDiameter = params.lensDiameter;
        self.screenToLensDistance = params.screenToLensDistance;
        self.eyeToLensDistance = params.eyeToLensDistance;
        
        self.visibleViewportSize = params.visibleViewportSize;
        self.fovY = params.fovY;
        
        self.distortion = [[Distortion alloc] initWithDistortion:params.distortion];
    }
    return self;
}

- (void)setVendor:(NSString*)vendor
{
    self.vendor = vendor;
}

- (NSString*)getVendor
{
    return self.vendor;
}

- (void)setModel:(NSString*)model
{
    self.model = model;
}

- (NSString*)getModel
{
    return self.model;
}

- (void)setVersion:(NSString*)version
{
    self.version = version;
}

- (NSString*)getVersion
{
    return self.version;
}

- (void)setInterpupillaryDistance:(float)interpupillaryDistance
{
    self.interpupillaryDistance = interpupillaryDistance;
}

- (float)getInterpupillaryDistance
{
    return self.interpupillaryDistance;
}

- (void)setVerticalDistanceToLensCenter:(float)verticalDistanceToLensCenter
{
    self.verticalDistanceToLensCenter = verticalDistanceToLensCenter;
}

- (float)getVerticalDistanceToLensCenter
{
    return self.verticalDistanceToLensCenter;
}

- (void)setVisibleViewportSize:(float)visibleViewportSize
{
    self.visibleViewportSize = visibleViewportSize;
}

- (float)getVisibleViewportSize
{
    return self.visibleViewportSize;
}

- (void)setFovY:(float)fovY
{
    self.fovY = fovY;
}

- (float)getFovY
{
    return self.fovY;
}

- (void)setLensDiameter:(float)lensDiameter
{
    self.lensDiameter = lensDiameter;
}

- (float)getLensDiameter
{
    return self.lensDiameter;
}

- (void)setScreenToLensDistance:(float)screenToLensDistance
{
    self.screenToLensDistance = screenToLensDistance;
}

- (float)getScreenToLensDistance
{
    return self.screenToLensDistance;
}

- (void)setEyeToLensDistance:(float)eyeToLensDistance
{
    self.eyeToLensDistance = eyeToLensDistance;
}

- (float)getEyeToLensDistance
{
    return self.eyeToLensDistance;
}

- (Distortion*)getDistortion
{
    return self.distortion;
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
    if (![other isKindOfClass:[CardboardDeviceParams class]])
    {
        return false;
    }
    CardboardDeviceParams *o = (CardboardDeviceParams *)other;
    return (self.getVendor == [o getVendor]) && (self.getModel == [o getModel]) && (self.getVersion == [o getVersion]) && (self.getInterpupillaryDistance == [o getInterpupillaryDistance]) && (self.getVerticalDistanceToLensCenter == [o getVerticalDistanceToLensCenter]) && (self.getLensDiameter == [o getLensDiameter]) && (self.getScreenToLensDistance == [o getScreenToLensDistance]) && (self.getEyeToLensDistance == [o getEyeToLensDistance]) && (self.getVisibleViewportSize == [o getVisibleViewportSize]) && (self.getFovY == [o getFovY]) && ([self.getDistortion equals:[o getDistortion]]);
}

@end
