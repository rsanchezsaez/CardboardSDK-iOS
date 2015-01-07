//
//  CardboardViewController.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-09-04.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "CardboardViewController.h"

#include "CardboardDeviceParams.h"
#include "HeadTracker.h"
#include "HeadMountedDisplay.h"




@interface CardboardViewController ()

@property (nonatomic, assign) CardboardDeviceParams *cardboardDeviceParams;
@property (nonatomic, assign) HeadTracker *headTracker;
@property (nonatomic, assign) HeadMountedDisplay *headMountedDisplay;

@end


@implementation CardboardViewController

- (id)init
{
    self = [super init];
    if (!self) { return nil; }
    
    self.cardboardDeviceParams = new CardboardDeviceParams();
    self.headTracker = new HeadTracker();
    self.headMountedDisplay = new HeadMountedDisplay([UIScreen mainScreen]);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCardboardTrigger:) name:@"TriggerClicked" object:nil];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.cardboardDeviceParams != nullptr) { delete self.cardboardDeviceParams; }
    if (self.headTracker != nullptr) { delete self.headTracker; }
    if (self.headMountedDisplay != nullptr) { delete self.headMountedDisplay; }
}

- (void)onCardboardTrigger:(id)sender
{
    
}

@end
