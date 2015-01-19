//
//  Viewport.mm
//  CardboardSDK-iOS
//
//

#include "Viewport.h"

void Viewport::setViewport(int x, int y, int width, int height)
{
    this->x = x;
    this->y = y;
    this->width = width;
    this->height = height;
}

void Viewport::setGLViewport()
{
    glViewport(x, y, width, height);
}

void Viewport::setGLScissor()
{
    glScissor(x, y, width, height);
}

NSString* Viewport::toString()
{
    return [NSString stringWithFormat:@"Viewport {x:%d y:%d width:%d height:%d}", this->x, this->y, this->width, this->height];
}