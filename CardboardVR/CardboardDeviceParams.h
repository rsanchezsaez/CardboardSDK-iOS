//
//  CardboardDeviceParams.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-24.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Distortion.h"

@interface CardboardDeviceParams : NSObject

- (id)initWithCardboardDeviceParams:(CardboardDeviceParams*)params;
- (void)setVendor:(NSString*)vendor;
- (NSString*)getVendor;
- (void)setModel:(NSString*)model;
- (NSString*)getModel;
- (void)setVersion:(NSString*)version;
- (NSString*)getVersion;
- (void)setInterpupillaryDistance:(float)interpupillaryDistance;
- (float)getInterpupillaryDistance;
- (void)setVerticalDistanceToLensCenter:(float)verticalDistanceToLensCenter;
- (float)getVerticalDistanceToLensCenter;
- (void)setVisibleViewportSize:(float)visibleViewportSize;
- (float)getVisibleViewportSize;
- (void)setFovY:(float)fovY;
- (float)getFovY;
- (void)setLensDiameter:(float)lensDiameter;
- (float)getLensDiameter;
- (void)setScreenToLensDistance:(float)screenToLensDistance;
- (float)getScreenToLensDistance;
- (void)setEyeToLensDistance:(float)eyeToLensDistance;
- (float)getEyeToLensDistance;
- (Distortion*)getDistortion;
- (bool)equals:(id)other;

@end
