//
//  Vector3d.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-23.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Vector3d : NSObject

@property (nonatomic, assign) double x;
@property (nonatomic, assign) double y;
@property (nonatomic, assign) double z;

- (id)initWithX:(double)x y:(double)y z:(double)z;
- (void)set:(double)x y:(double)y z:(double)z;
- (void)setComponent:(int)i val:(double)val;
- (void)setZero;
- (void)set:(Vector3d*)other;
- (void)scale:(double)s;
- (void)normalize;
+ (double)dot:(Vector3d*)a b:(Vector3d*)b;
- (double)length;
- (bool)sameValues:(Vector3d*)other;
+ (void)sub:(Vector3d*)a b:(Vector3d*)b result:(Vector3d*)result;
+ (void)cross:(Vector3d*)a b:(Vector3d*)b result:(Vector3d*)result;
+ (void)ortho:(Vector3d*)v result:(Vector3d*)result;
+ (int)largestAbsComponent:(Vector3d*)v;

@end
