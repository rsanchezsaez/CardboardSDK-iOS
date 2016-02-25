//
//  TouchSensor.mm
//  CardboardSDK-iOS
//
//

#import "CBDViewController.h"
#import "TouchSensor.h"
#import "MagnetSensor.h"

@implementation CBDViewController (TouchSensor)

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:CardboardSDK::CBDTriggerPressedNotification
                      object:nil];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
}

@end
