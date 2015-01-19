//
//  FieldOfView.cpp
//  CardboardSDK-iOS
//
//

#include "FieldOfView.h"

FieldOfView::FieldOfView() :
    _left(0),
    _right(0),
    _bottom(0),
    _top(0)
{
}

FieldOfView::FieldOfView(float left, float right, float bottom, float top)
{
    _left = left;
    _right = right;
    _bottom = bottom;
    _top = top;
}

FieldOfView::FieldOfView(FieldOfView *other)
{
    _left = other->_left;
    _right = other->_right;
    _bottom = other->_bottom;
    _top = other->_top;
}

void FieldOfView::setLeft(float left)
{
    _left = left;
}

float FieldOfView::left()
{
    return _left;
}

void FieldOfView::setRight(float right)
{
    _right = right;
}

float FieldOfView::right()
{
    return _right;
}

void FieldOfView::setBottom(float bottom)
{
    _bottom = bottom;
}

float FieldOfView::bottom()
{
    return _bottom;
}

void FieldOfView::setTop(float top)
{
    _top = top;
}

float FieldOfView::top()
{
    return _top;
}

GLKMatrix4 FieldOfView::toPerspectiveMatrix(float near, float far)
{
    float left = -tanf(_left * (M_PI / 180.0f)) * near;
    float right = tanf(_right * (M_PI / 180.0f)) * near;
    float bottom = -tanf(_bottom * (M_PI / 180.0f)) * near;
    float top = tanf(_top * (M_PI / 180.0f)) * near;
    return frustumM(left, right, bottom, top, near, far);
}

bool FieldOfView::equals(FieldOfView *other)
{
    if (other == nullptr) {
        return false;
    }
    if (other == this) {
        return true;
    }
    return (left() == other->left()) && (right() == other->right()) && (bottom() == other->bottom()) && (top() == other->top());
}

NSString* FieldOfView::toString()
{
    return [NSString stringWithFormat:@"FieldOfView {left:%f right:%f bottom:%f top:%f}", _left, _right, _bottom, _top];
}

GLKMatrix4 FieldOfView::frustumM(float left, float right, float bottom, float top, float near, float far)
{
    float r_width  = 1.0f / (right - left);
    float r_height = 1.0f / (top - bottom);
    float r_depth  = 1.0f / (near - far);
    float x = 2.0f * (near * r_width);
    float y = 2.0f * (near * r_height);
    float A = (right + left) * r_width;
    float B = (top + bottom) * r_height;
    float C = (far + near) * r_depth;
    float D = 2.0f * (far * near * r_depth);
    GLKMatrix4 frustum;
    frustum.m[0] = x;
    frustum.m[1] = 0.0f;
    frustum.m[2] = 0.0f;
    frustum.m[3] = 0.0f;
    frustum.m[4] = 0.0f;
    frustum.m[5] = y;
    frustum.m[6] = 0.0f;
    frustum.m[7] = 0.0f;
    frustum.m[8] = A;
    frustum.m[9] = B;
    frustum.m[10] = C;
    frustum.m[11] = -1.0f;
    frustum.m[12] = 0.0f;
    frustum.m[13] = 0.0f;
    frustum.m[14] = D;
    frustum.m[15] = 0.0f;
    return frustum;
}
