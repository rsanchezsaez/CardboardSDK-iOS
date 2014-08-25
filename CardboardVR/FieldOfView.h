//
//  FieldOfView.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface FieldOfView : NSObject

- (id)initWithLeft:(float)left right:(float)right bottom:(float)bottom top:(float)top;
- (id)initWitFieldOfView:(FieldOfView*)other;
- (void)setLeft:(float)left;
- (float)getLeft;
- (void)setRight:(float)right;
- (float)getRight;
- (void)setBottom:(float)bottom;
- (float)getBottom;
- (void)setTop:(float)top;
- (float)getTop;
- (GLKMatrix4)toPerspectiveMatrix:(float)near far:(float)far;
- (bool)equals:(id)other;
- (NSString *)toString;

@end
