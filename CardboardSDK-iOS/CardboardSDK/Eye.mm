//
//  Eye.mm
//  CardboardSDK-iOS
//


#include "Eye.h"

#include "FieldOfView.h"
#include "Viewport.h"


namespace CardboardSDK
{

Eye::Eye(Type eyeType) :
    _type(eyeType),
    _eyeView(GLKMatrix4Identity),
    _projectionChanged(true),
    _perspective(GLKMatrix4Identity),
    _lastZNear(0),
    _lastZFar(0)
{
    _viewport = new Viewport();
    _fov = new FieldOfView();
}

Eye::~Eye()
{
    if (_viewport != nullptr) { delete _viewport; }
    if (_fov != nullptr) { delete _fov; }
}

Eye::Type Eye::type()
{
    return _type;
}

GLKMatrix4 Eye::eyeView()
{
    return _eyeView;
}

void Eye::setEyeView(GLKMatrix4 eyeView)
{
    _eyeView = eyeView;
}

GLKMatrix4 Eye::perspective(float zNear, float zFar)
{
    if (!_projectionChanged && _lastZNear == zNear && _lastZFar == zFar)
    {
        return _perspective;
    }
    _perspective = fov()->toPerspectiveMatrix(zNear, zFar);
    _lastZNear = zNear;
    _lastZFar = zFar;
    _projectionChanged = false;
    return _perspective;
}

Viewport *Eye::viewport()
{
    return _viewport;
}

FieldOfView *Eye::fov()
{
    return _fov;
}

void Eye::setProjectionChanged()
{
    _projectionChanged = true;
}

}