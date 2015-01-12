//
//  CardboardDeviceParams.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-26.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "CardboardDeviceParams.h"

CardboardDeviceParams::CardboardDeviceParams()
{
    this->vendor = @"com.google";
    this->model = @"cardboard";
    this->version = @"1.0";
    
    this->interpupillaryDistance = 0.06F;
    this->verticalDistanceToLensCenter = 0.035F;
    this->lensDiameter = 0.025F;
    this->screenToLensDistance = 0.037F;
    this->eyeToLensDistance = 0.011F;
    
    this->visibleViewportSize = 0.06F;
    this->fovY = 65.0F;
    
    this->distortion = new Distortion();
}

CardboardDeviceParams::CardboardDeviceParams(CardboardDeviceParams* params)
{
    this->vendor = params->vendor;
    this->model = params->model;
    this->version = params->version;
    
    this->interpupillaryDistance = params->interpupillaryDistance;
    this->verticalDistanceToLensCenter = params->verticalDistanceToLensCenter;
    this->lensDiameter = params->lensDiameter;
    this->screenToLensDistance = params->screenToLensDistance;
    this->eyeToLensDistance = params->eyeToLensDistance;
    
    this->visibleViewportSize = params->visibleViewportSize;
    this->fovY = params->fovY;
    
    this->distortion = new Distortion(params->distortion);
}

CardboardDeviceParams::~CardboardDeviceParams()
{
    delete this->distortion;
}

void CardboardDeviceParams::setVendor(NSString* vendor)
{
    this->vendor = vendor;
}

NSString* CardboardDeviceParams::getVendor()
{
    return this->vendor;
}

void CardboardDeviceParams::setModel(NSString* model)
{
    this->model = model;
}

NSString* CardboardDeviceParams::getModel()
{
    return this->model;
}

void CardboardDeviceParams::setVersion(NSString* version)
{
    this->version = version;
}

NSString* CardboardDeviceParams::getVersion()
{
    return this->version;
}

void CardboardDeviceParams::setInterpupillaryDistance(float interpupillaryDistance)
{
    this->interpupillaryDistance = interpupillaryDistance;
}

float CardboardDeviceParams::getInterpupillaryDistance()
{
    return this->interpupillaryDistance;
}

void CardboardDeviceParams::setVerticalDistanceToLensCenter(float verticalDistanceToLensCenter)
{
    this->verticalDistanceToLensCenter = verticalDistanceToLensCenter;
}

float CardboardDeviceParams::getVerticalDistanceToLensCenter()
{
    return this->verticalDistanceToLensCenter;
}

void CardboardDeviceParams::setVisibleViewportSize(float visibleViewportSize)
{
    this->visibleViewportSize = visibleViewportSize;
}

float CardboardDeviceParams::getVisibleViewportSize()
{
    return this->visibleViewportSize;
}

void CardboardDeviceParams::setFovY(float fovY)
{
    this->fovY = fovY;
}

float CardboardDeviceParams::getFovY()
{
    return this->fovY;
}

void CardboardDeviceParams::setLensDiameter(float lensDiameter)
{
    this->lensDiameter = lensDiameter;
}

float CardboardDeviceParams::getLensDiameter()
{
    return this->lensDiameter;
}

void CardboardDeviceParams::setScreenToLensDistance(float screenToLensDistance)
{
    this->screenToLensDistance = screenToLensDistance;
}

float CardboardDeviceParams::getScreenToLensDistance()
{
    return this->screenToLensDistance;
}

void CardboardDeviceParams::setEyeToLensDistance(float eyeToLensDistance)
{
    this->eyeToLensDistance = eyeToLensDistance;
}

float CardboardDeviceParams::getEyeToLensDistance()
{
    return this->eyeToLensDistance;
}

Distortion* CardboardDeviceParams::getDistortion()
{
    return this->distortion;
}

bool CardboardDeviceParams::equals(CardboardDeviceParams *other)
{
    if (other == nullptr)
    {
        return false;
    }
    if (other == this)
    {
        return true;
    }
    return (this->getVendor() == other->getVendor()) && (this->getModel() == other->getModel()) && (this->getVersion() == other->getVersion()) && (this->getInterpupillaryDistance() == other->getInterpupillaryDistance()) && (this->getVerticalDistanceToLensCenter() == other->getVerticalDistanceToLensCenter()) && (this->getLensDiameter() == other->getLensDiameter()) && (this->getScreenToLensDistance() == other->getScreenToLensDistance()) && (this->getEyeToLensDistance() == other->getEyeToLensDistance()) && (this->getVisibleViewportSize() == other->getVisibleViewportSize()) && (this->getFovY() == other->getFovY()) && (this->getDistortion()->equals(other->getDistortion()));
}