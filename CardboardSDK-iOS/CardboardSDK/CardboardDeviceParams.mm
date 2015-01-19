//
//  CardboardDeviceParams.mm
//  CardboardSDK-iOS
//
//

#include "CardboardDeviceParams.h"

CardboardDeviceParams::CardboardDeviceParams() :
    _vendor(@"com.google"),
    _model(@"cardboard"),
    _version(@"1.0"),
    _interLensDistance(0.06f),
    _verticalDistanceToLensCenter(0.035f),
    _lensDiameter(0.025f),
    _screenToLensDistance(0.037f),
    _eyeToLensDistance(0.011f),
    _visibleViewportSize(0.06f),
    _fovY(65.0f)
{
    _distortion = new Distortion();
}

CardboardDeviceParams::CardboardDeviceParams(CardboardDeviceParams* params)
{
    _vendor = params->_vendor;
    _model = params->_model;
    _version = params->_version;
    
    _interLensDistance = params->_interLensDistance;
    _verticalDistanceToLensCenter = params->_verticalDistanceToLensCenter;
    _lensDiameter = params->_lensDiameter;
    _screenToLensDistance = params->_screenToLensDistance;
    _eyeToLensDistance = params->_eyeToLensDistance;
    
    _visibleViewportSize = params->_visibleViewportSize;
    _fovY = params->_fovY;
    
    _distortion = new Distortion(params->_distortion);
}

CardboardDeviceParams::~CardboardDeviceParams()
{
    delete _distortion;
}

void CardboardDeviceParams::setVendor(NSString* vendor)
{
    _vendor = vendor;
}

NSString* CardboardDeviceParams::vendor()
{
    return _vendor;
}

void CardboardDeviceParams::setModel(NSString* model)
{
    _model = model;
}

NSString* CardboardDeviceParams::model()
{
    return _model;
}

void CardboardDeviceParams::setVersion(NSString* version)
{
    _version = version;
}

NSString* CardboardDeviceParams::version()
{
    return _version;
}

void CardboardDeviceParams::setInterLensDistance(float interLensDistance)
{
    _interLensDistance = interLensDistance;
}

float CardboardDeviceParams::interLensDistance()
{
    return _interLensDistance;
}

void CardboardDeviceParams::setVerticalDistanceToLensCenter(float verticalDistanceToLensCenter)
{
    _verticalDistanceToLensCenter = verticalDistanceToLensCenter;
}

float CardboardDeviceParams::verticalDistanceToLensCenter()
{
    return _verticalDistanceToLensCenter;
}

void CardboardDeviceParams::setVisibleViewportSize(float visibleViewportSize)
{
    _visibleViewportSize = visibleViewportSize;
}

float CardboardDeviceParams::visibleViewportSize()
{
    return _visibleViewportSize;
}

void CardboardDeviceParams::setFovY(float fovY)
{
    _fovY = fovY;
}

float CardboardDeviceParams::fovY()
{
    return _fovY;
}

void CardboardDeviceParams::setLensDiameter(float lensDiameter)
{
    _lensDiameter = lensDiameter;
}

float CardboardDeviceParams::lensDiameter()
{
    return _lensDiameter;
}

void CardboardDeviceParams::setScreenToLensDistance(float screenToLensDistance)
{
    _screenToLensDistance = screenToLensDistance;
}

float CardboardDeviceParams::screenToLensDistance()
{
    return _screenToLensDistance;
}

void CardboardDeviceParams::setEyeToLensDistance(float eyeToLensDistance)
{
    _eyeToLensDistance = eyeToLensDistance;
}

float CardboardDeviceParams::eyeToLensDistance()
{
    return _eyeToLensDistance;
}

Distortion* CardboardDeviceParams::getDistortion()
{
    return _distortion;
}

bool CardboardDeviceParams::equals(CardboardDeviceParams *other)
{
    if (other == nullptr)
    {
        return false;
    }
    else if (other == this)
    {
        return true;
    }
    return
    ([vendor() isEqualToString:other->vendor()])
    && ([model() isEqualToString:other->model()])
    && ([version() isEqualToString:other->version()])
    && (interLensDistance() == other->interLensDistance())
    && (verticalDistanceToLensCenter() == other->verticalDistanceToLensCenter())
    && (lensDiameter() == other->lensDiameter())
    && (screenToLensDistance() == other->screenToLensDistance())
    && (eyeToLensDistance() == other->eyeToLensDistance())
    && (visibleViewportSize() == other->visibleViewportSize())
    && (fovY() == other->fovY())
    && (getDistortion()->equals(other->getDistortion()));
}