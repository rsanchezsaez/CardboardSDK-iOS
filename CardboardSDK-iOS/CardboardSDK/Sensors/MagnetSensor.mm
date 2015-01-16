//
//  MagnetSensor.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "MagnetSensor.h"

MagnetSensor::MagnetSensor()
{
    this->manager = [[CMMotionManager alloc] init];
}

void MagnetSensor::start()
{
    if (this->manager.isMagnetometerAvailable && !this->manager.isMagnetometerActive)
    {
        this->manager.magnetometerUpdateInterval = 1.0f / 100.0f;
        [this->manager startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                           withHandler:^(CMMagnetometerData *magnetometerData, NSError *error)
        {
            this->addData(GLKVector3 {
                (float)magnetometerData.magneticField.x,
                (float)magnetometerData.magneticField.y,
                (float)magnetometerData.magneticField.z });
        }];
    }
}

void MagnetSensor::stop()
{
    [this->manager stopMagnetometerUpdates];
}

void MagnetSensor::addData(GLKVector3 value)
{
    if (this->sensorData.size() > 40)
    {
        this->sensorData.erase(this->sensorData.begin());
    }
    this->sensorData.push_back(value);
    this->evaluateModel();
}

void MagnetSensor::evaluateModel()
{
    if (this->sensorData.size() < 40)
    {
        return;
    }
    float minimums[2];
    float maximums[2];
    GLKVector3 baseline = this->sensorData.back();
    for (int i = 0; i < 2; i++)
    {
        std::vector<float> offsets = computeOffsets(20 * i, baseline);
        minimums[i] = this->computeMinimum(offsets);
        maximums[i] = this->computeMaximum(offsets);
    }

    if (minimums[0] < 30.0f && maximums[1] > 130.0f)
    {
        this->sensorData.clear();
        [[NSNotificationCenter defaultCenter] postNotificationName:CBTriggerPressedNotification object:nil];
    }
}

std::vector<float> MagnetSensor::computeOffsets(int start, GLKVector3 baseline)
{
    std::vector<float> offsets;
    for (int i = 0; i < 20; i++)
    {
        GLKVector3 point = this->sensorData[start + i];
        float o[] = {point.x - baseline.x, point.y - baseline.y, point.z - baseline.z};
        float magnitude = (float)sqrt(o[0] * o[0] + o[1] * o[1] + o[2] * o[2]);
        offsets.push_back(magnitude);
    }
    return offsets;
}

float MagnetSensor::computeMinimum(std::vector<float> offsets)
{
    float min = FLT_MAX;
    for (int i = 0; i < offsets.size(); i++)
    {
        min = MIN(offsets[i], min);
    }
    return min;
}

float MagnetSensor::computeMaximum(std::vector<float> offsets)
{
    float max = FLT_MIN;
    for (int i = 0; i < offsets.size(); i++)
    {
        max = MAX(offsets[i], max);
    }
    return max;
}

