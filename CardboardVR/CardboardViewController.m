//
//  CardboardViewController.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-19.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "CardboardViewController.h"
#import "MagnetSensor.h"

@interface CardboardViewController ()

@property (nonatomic,strong) MagnetSensor *magnetSensor;

@end

@implementation CardboardViewController

- (void)startSensor
{
    if (self.magnetSensor == nil) {
        self.magnetSensor = [[MagnetSensor alloc] init];
    }
    [self.magnetSensor setDelegate:self];
    [self.magnetSensor start];
}

-(void)stopSensor {
    if (self.magnetSensor == nil) {
        return;
    }
    [self.magnetSensor stop];
    self.magnetSensor = nil;
}

- (void)triggerClicked:(MagnetSensor *)magnetSensor
{
    NSLog(@"trigger clicked");
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [self startSensor];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self stopSensor];
}

@end
