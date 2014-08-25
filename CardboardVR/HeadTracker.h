//
//  HeadTracker.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-22.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface HeadTracker : NSObject

- (void)startTracking;
- (void)stopTracking;
- (GLKMatrix4)getLastHeadView;

@end
