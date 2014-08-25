//
//  EyeTransform.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EyeParams.h"
#import <GLKit/GLKit.h>

@class EyeParams;

@interface EyeTransform : NSObject

- (id)initWithEyeParams:(EyeParams*)params;
- (GLKMatrix4)getEyeView;
- (GLKMatrix4)getPerspective;
- (void)setPerspective:(GLKMatrix4)perspective;
- (EyeParams*)getParams;

@end
