//
//  Distortion.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-24.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>

struct _DistortionCoeffients
{
    float c[2];
};
typedef struct _DistortionCoeffients DistortionCoeffients;

@interface Distortion : NSObject

- (id)initWithDistortion:(Distortion*)other;
- (void)setCoefficients:(DistortionCoeffients)coefficients;
- (DistortionCoeffients)getCoefficients;
- (float)distortionFactor:(float)radius;
- (float)distort:(float)radius;
- (float)distortInverse:(float)radius;
- (bool)equals:(id)other;
- (NSString *)toString;

@end
