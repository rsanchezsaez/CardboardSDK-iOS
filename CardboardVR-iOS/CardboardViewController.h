//
//  CardboardViewController.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-09-04.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#include "CardboardView.h"
#include "MagnetSensor.h"
#include "CardboardDeviceParams.h"

@interface CardboardViewController : GLKViewController

@property (nonatomic, assign) CardboardView *cardboardView;
@property (nonatomic, assign) MagnetSensor *magnetSensor;
@property (nonatomic, assign) CardboardDeviceParams *cardboardDeviceParams;

- (id)initWithCardboardView:(CardboardView*)cardboardView;
- (CardboardView*)getCardboardView;
- (void)onCardboardTrigger:(id)sender;

@end
