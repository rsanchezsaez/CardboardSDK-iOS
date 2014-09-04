//
//  CardboardViewController.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-09-04.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "CardboardViewController.h"

@implementation CardboardViewController

- (id)initWithCardboardView:(CardboardView*)cardboardView
{
    self = [super init];
    if (self)
    {
        self.cardboardDeviceParams = nullptr;
        self.cardboardView = cardboardView;
        if (self.cardboardView != nullptr) {
            self.cardboardDeviceParams = new CardboardDeviceParams();
            //cardboardView->updateCardboardDeviceParams(this->cardboardDeviceParams);
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCardboardTrigger:) name:@"TriggerClicked" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.cardboardDeviceParams != nullptr) {
        delete self.cardboardDeviceParams;
    }
}

- (CardboardView*)getCardboardView
{
    return self.cardboardView;
}

- (void)onCardboardTrigger:(id)sender
{
    
}

@end
