//
//  Matrix3x3d.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-22.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Vector3d.h"

@interface Matrix3x3d : NSObject

@property (nonatomic, assign) double *m;

- (id)initWithM00:(double)m00 m01:(double)m01 m02:(double)m02 m10:(double)m10 m11:(double)m11 m12:(double)m12 m20:(double)m20 m21:(double)m21 m22:(double)m22;
- (id)initWithMatrix3x3d:(Matrix3x3d*)o;
- (void)set:(double)m00 m01:(double)m01 m02:(double)m02 m10:(double)m10 m11:(double)m11 m12:(double)m12 m20:(double)m20 m21:(double)m21 m22:(double)m22;
- (void)set:(Matrix3x3d*)o;
- (void)setZero;
- (void)setIdentity;
- (void)setSameDiagonal:(double)d;
- (double)get:(int)row col:(int)col;
- (void)set:(int)row col:(int)col value:(double)value;
- (void)getColumn:(int)col v:(Vector3d*)v;
- (void)setColumn:(int)col v:(Vector3d*)v;
- (void)scale:(double)s;
- (void)plusEquals:(Matrix3x3d*)b;
- (void)minusEquals:(Matrix3x3d*)b;
- (void)transpose;
- (void)transpose:(Matrix3x3d*)result;
+ (void)add:(Matrix3x3d*)a b:(Matrix3x3d*)b result:(Matrix3x3d*)result;
+ (void)mult:(Matrix3x3d*)a b:(Matrix3x3d*)b result:(Matrix3x3d*)result;
+ (void)mult:(Matrix3x3d*)a v:(Vector3d*)v result:(Vector3d*)result;
- (double)determinant;
- (bool)invert:(Matrix3x3d*)result;

@end
