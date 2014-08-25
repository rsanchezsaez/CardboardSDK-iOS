//
//  EyeViewport.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "EyeViewport.h"

@implementation EyeViewport

- (NSString *)toString
{
    return [NSString stringWithFormat:@"EyeViewport {x:%f y:%f width:%f height:%f eyeX:%f eyeY:%f}", self.x, self.y, self.width, self.height, self.eyeX, self.eyeY];
}

@end
