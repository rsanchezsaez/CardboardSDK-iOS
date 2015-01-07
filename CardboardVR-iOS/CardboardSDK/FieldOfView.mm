//
//  FieldOfView.cpp
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-26.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "FieldOfView.h"

FieldOfView::FieldOfView()
{
    
}

FieldOfView::FieldOfView(float left, float right, float bottom, float top)
{
    this->left = left;
    this->right = right;
    this->bottom = bottom;
    this->top = top;
}

FieldOfView::FieldOfView(FieldOfView *other)
{
    this->left = other->left;
    this->right = other->right;
    this->bottom = other->bottom;
    this->top = other->top;
}

void FieldOfView::setLeft(float left)
{
    this->left = left;
}

float FieldOfView::getLeft()
{
    return this->left;
}

void FieldOfView::setRight(float right)
{
    this->right = right;
}

float FieldOfView::getRight()
{
    return this->right;
}

void FieldOfView::setBottom(float bottom)
{
    this->bottom = bottom;
}

float FieldOfView::getBottom()
{
    return this->bottom;
}

void FieldOfView::setTop(float top)
{
    this->top = top;
}

float FieldOfView::getTop()
{
    return this->top;
}

GLKMatrix4 FieldOfView::toPerspectiveMatrix(float near, float far)
{
    float left = -tanf(this->left * (M_PI / 180.0f)) * near;
    float right = tanf(this->right * (M_PI / 180.0f)) * near;
    float bottom = -tanf(this->bottom * (M_PI / 180.0f)) * near;
    float top = tanf(this->top * (M_PI / 180.0f)) * near;
    return this->frustumM(left, right, bottom, top, near, far);
}

bool FieldOfView::equals(FieldOfView *other)
{
    if (other == nullptr) {
        return false;
    }
    if (other == this) {
        return true;
    }
    return (this->getLeft() == other->getLeft()) && (this->getRight() == other->getRight()) && (this->getBottom() == other->getBottom()) && (this->getTop() == other->getTop());
}

NSString* FieldOfView::toString()
{
    return [NSString stringWithFormat:@"FieldOfView {left:%f right:%f bottom:%f top:%f}", this->left, this->right, this->bottom, this->top];
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
