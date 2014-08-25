//
//  MagnetSensor.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-20.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "MagnetSensor.h"
#import <CoreMotion/CoreMotion.h>

@interface MagnetSensor ()

@property (nonatomic,strong) CMMotionManager *manager;
@property (nonatomic,strong) NSMutableArray *sensorData;

@end

@implementation MagnetSensor

const int WINDOW_SIZE = 40;
const int NUM_SEGMENTS = 2;
const int SEGMENT_SIZE = WINDOW_SIZE / NUM_SEGMENTS;
const int T1 = 30, T2 = 130;

- (void)start
{
    if (self.sensorData == nil) {
        self.sensorData = [[NSMutableArray alloc] init];
    }
    if (self.manager == nil) {
        self.manager = [[CMMotionManager alloc] init];
    }
    if (self.manager.isMagnetometerAvailable) {
        self.manager.magnetometerUpdateInterval = 1.0f / 100.0f;
        [self.manager startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMMagnetometerData *magnetometerData, NSError *error) {
            [self addData:magnetometerData.magneticField.x y:magnetometerData.magneticField.y z:magnetometerData.magneticField.z];
        }];
    }
}

-(void)stop {
    if (self.manager == nil) {
        return;
    }
    [self.manager stopMagnetometerUpdates];
    self.manager = nil;
}

- (void)addData:(float)x y:(float)y z:(float)z
{
    if(x == 0 && y == 0 && z   == 0)
    {
        return;
    }
    if ([self.sensorData count] > WINDOW_SIZE) {
        [self.sensorData removeObjectAtIndex:0];
    }
    [self.sensorData addObject:[[NSMutableArray alloc] initWithObjects:[NSNumber numberWithFloat:x], [NSNumber numberWithFloat:y], [NSNumber numberWithFloat:z], nil]];
    [self evaluateModel];
}

- (void)evaluateModel
{
    if ([self.sensorData count] < WINDOW_SIZE) {
        return;
    }
    
    NSMutableArray *minimums = [[NSMutableArray alloc] initWithCapacity:NUM_SEGMENTS];
    NSMutableArray *maximums = [[NSMutableArray alloc] initWithCapacity:NUM_SEGMENTS];
    NSArray *baseline = [self.sensorData lastObject];
    
    for (int i = 0; i < NUM_SEGMENTS; i++) {
        int segmentStart = SEGMENT_SIZE * i;
        NSArray *offsets = [self computeOffsets:segmentStart baseline:baseline];
        [minimums addObject:[self computeMinimum:offsets]];
        [maximums addObject:[self computeMaximum:offsets]];
    }
    
    float min1 = [[minimums objectAtIndex:0] floatValue];
    float max2 = [[maximums objectAtIndex:1] floatValue];
    
    if ((min1 < T1) && (max2 > T2))
    {
        [self.sensorData removeAllObjects];
        [self.delegate triggerClicked:self];
    }
}

- (NSArray *)computeOffsets:(int)start baseline:(NSArray *)baseline
{
    float baseline1 = [[baseline objectAtIndex:0] floatValue];
    float baseline2 = [[baseline objectAtIndex:1] floatValue];
    float baseline3 = [[baseline objectAtIndex:2] floatValue];
    NSMutableArray *offsets = [[NSMutableArray alloc] initWithCapacity:SEGMENT_SIZE];
    for (int i = 0; i < SEGMENT_SIZE; i++) {
        float point1 = [[[self.sensorData objectAtIndex:start + i] objectAtIndex:0] floatValue];
        float point2 = [[[self.sensorData objectAtIndex:start + i] objectAtIndex:1] floatValue];
        float point3 = [[[self.sensorData objectAtIndex:start + i] objectAtIndex:2] floatValue];
        float o[] = {point1 - baseline1, point2 - baseline2, point3 - baseline3};
        float magnitude = (float)sqrt(o[0] * o[0] + o[1] * o[1] + o[2] * o[2]);
        [offsets addObject:[[NSNumber alloc] initWithFloat:magnitude]];
    }
    return offsets;
}

- (NSNumber *)computeMaximum:(NSArray *)offsets
{
    float max = FLT_MIN;
    for (NSNumber *offset in offsets) {
        max = MAX([offset floatValue], max);
    }
    return [[NSNumber alloc] initWithFloat:max];
}

- (NSNumber *)computeMinimum:(NSArray *)offsets
{
    float min = FLT_MAX;
    for (NSNumber *offset in offsets) {
        min = MIN([offset floatValue], min);
    }
    return [[NSNumber alloc] initWithFloat:min];
}

@end
