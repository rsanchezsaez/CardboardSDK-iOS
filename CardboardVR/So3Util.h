//
//  So3Util.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-23.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Vector3d.h"
#import "Matrix3x3d.h"

@interface So3Util : NSObject

+ (void)sO3FromTwoVec:(Vector3d*)a b:(Vector3d*)b result:(Matrix3x3d*)result;
+ (void)rotationPiAboutAxis:(Vector3d*)v result:(Matrix3x3d*)result;
+ (void)sO3FromMu:(Vector3d*)w result:(Matrix3x3d*)result;
+ (void)muFromSO3:(Matrix3x3d*)so3 result:(Vector3d*)result;
+ (void)rodriguesSo3Exp:(Vector3d*)w kA:(double)kA kB:(double)kB result:(Matrix3x3d*)result;
+ (void)generatorField:(int)i pos:(Matrix3x3d*)pos result:(Matrix3x3d*)result;

@end
