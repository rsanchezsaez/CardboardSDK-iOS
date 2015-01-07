//
//  Vector3d.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "Vector3d.h"
#include <cmath>

Vector3d::Vector3d()
{
    this->setZero();
}

Vector3d::Vector3d(Vector3d *v)
{
    this->set(v->x, v->y, v->z);
}

Vector3d::Vector3d(double xx, double yy, double zz)
{
    this->set(xx, yy, zz);
}

void Vector3d::set(double xx, double yy, double zz)
{
    this->x = xx;
    this->y = yy;
    this->z = zz;
}

void Vector3d::setComponent(int i, double val)
{
    if (i == 0) {
        this->x = val;
    } else if (i == 1) {
        this->y = val;
    } else {
        this->z = val;
    }
}

void Vector3d::setZero()
{
    this->set(0, 0, 0);
}

void Vector3d::set(Vector3d *other)
{
    this->set(other->x, other->y, other->z);
}

void Vector3d::scale(double s)
{
    this->x *= s;
    this->y *= s;
    this->z *= s;
}

void Vector3d::normalize()
{
    double d = this->length();
    if (d != 0.0) {
        this->scale(1.0 / d);
    }
}

double Vector3d::dot(Vector3d *a, Vector3d *b)
{
    return a->x * b->x + a->y * b->y + a->z * b->z;
}

double Vector3d::length()
{
    return sqrt(this->x * this->x + this->y * this->y + this->z * this->z);
}

bool Vector3d::sameValues(Vector3d *other)
{
    return (this->x == other->x) && (this->y == other->y) && (this->z == other->z);
}

void Vector3d::sub(Vector3d *a, Vector3d *b, Vector3d *result)
{
    result->set(a->x - b->x, a->y - b->y, a->z - b->z);
}

void Vector3d::cross(Vector3d *a, Vector3d *b, Vector3d *result)
{
    result->set(a->y * b->z - a->z * b->y, a->z * b->x - a->x * b->z, a->x * b->y - a->y * b->x);
}

void Vector3d::ortho(Vector3d *v, Vector3d *result)
{
    int k = largestAbsComponent(v) - 1;
    if (k < 0) {
        k = 2;
    }
    result->setZero();
    result->setComponent(k, 1.0);
    cross(v, result, result);
    result->normalize();
}

int Vector3d::largestAbsComponent(Vector3d *v)
{
    double xAbs = fabs(v->x);
    double yAbs = fabs(v->y);
    double zAbs = fabs(v->z);
    if (xAbs > yAbs) {
        if (xAbs > zAbs) {
            return 0;
        }
        return 2;
    }
    if (yAbs > zAbs) {
        return 1;
    }
    return 2;
}