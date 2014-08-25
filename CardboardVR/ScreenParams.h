//
//  ScreenParams.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-24.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ScreenParams : NSObject

- (id)initWithScreen:(UIScreen*)screen;
- (id)initWithScreenParams:(ScreenParams*)screenParams;
- (void)setWidth:(int)width;
- (int)getWidth;
- (void)setHeight:(int)height;
- (int)getHeight;
- (float)getWidthMeters;
- (float)getHeightMeters;
- (void)setBorderSizeMeters:(float)screenBorderSize;
- (float)getBorderSizeMeters;
- (bool)equals:(id)other;

@end
