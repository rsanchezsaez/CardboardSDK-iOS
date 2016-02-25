//
//  TouchSensor.h
//  CardboardSDK-iOS
//
//

#ifndef __CardboardSDK_iOS__TouchSensor__
#define __CardboardSDK_iOS__TouchSensor__

#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>

#import "CBDViewController.h"

@interface CBDViewController (TouchSensor)

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end

#endif