//
//  MagnetSensor.mm
//  CardboardSDK-iOS
//
//

#include "MagnetSensor.h"

#include <algorithm>

static const size_t kNumSamples = 20;

MagnetSensor::MagnetSensor() :
    _sampleIndex(0),
    _sensorData(2*kNumSamples),
    _offsets(kNumSamples)
{
    _manager = [[CMMotionManager alloc] init];
}

void MagnetSensor::start()
{
    if (_manager.isMagnetometerAvailable && !_manager.isMagnetometerActive)
    {
        _manager.magnetometerUpdateInterval = 1.0f / 100.0f;
        [_manager startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                            withHandler:^(CMMagnetometerData *magnetometerData, NSError *error) {
                                                addData((GLKVector3) {
                                                        (float) magnetometerData.magneticField.x,
                                                        (float) magnetometerData.magneticField.y,
                                                        (float) magnetometerData.magneticField.z});
                                            }];
    }
}

void MagnetSensor::stop()
{
    [_manager stopMagnetometerUpdates];
}

void MagnetSensor::addData(GLKVector3 value)
{
    _sensorData[_sampleIndex % (2*kNumSamples)] = value;
    _baseline = value;
    ++_sampleIndex;
    evaluateModel();
}

void MagnetSensor::evaluateModel()
{
    if (_sampleIndex < (2*kNumSamples))
    {
        return;
    }
    float minimums[2];
    float maximums[2];
    for (int i = 0; i < 2; i++)
    {
        computeOffsets(kNumSamples * i, _baseline);
        auto min = std::min_element(_offsets.begin(), _offsets.end());
        auto max = std::max_element(_offsets.begin(), _offsets.end());
        minimums[i] = *min;
        maximums[i] = *max;
    }
        
    if (minimums[0] < 30.0f && maximums[1] > 130.0f)
    {
        _sampleIndex = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:CBTriggerPressedNotification object:nil];
    }
}

void MagnetSensor::computeOffsets(int start, GLKVector3 baseline)
{
    size_t frontIndex = _sampleIndex % (2*kNumSamples); // currently the oldest sample
    for (int i = 0; i < kNumSamples; i++)
    {
        GLKVector3 point = _sensorData[(frontIndex + start + i) % (2*kNumSamples)];
        float o[] = {point.x - baseline.x, point.y - baseline.y, point.z - baseline.z};
        float magnitude = (float)sqrt(o[0] * o[0] + o[1] * o[1] + o[2] * o[2]);
        _offsets[i] = magnitude;
    }
}

