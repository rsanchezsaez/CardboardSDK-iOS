//
//  HeadTransform.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-24.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface HeadTransform : NSObject

- (GLKMatrix4)getHeadView;
- (GLKVector3)getTranslation;
- (GLKVector3)getForwardVector;
- (GLKVector3)getUpVector;
- (GLKVector3)getRightVector;
- (GLKQuaternion)getQuaternion;
- (GLKVector3)getEulerAngles;

@end
