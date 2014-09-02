//
//  Matrix3x3d.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "Matrix3x3d.h"

Matrix3x3d::Matrix3x3d()
{
    this->setZero();
}

Matrix3x3d::Matrix3x3d(double m00, double m01, double m02, double m10, double m11, double m12, double m20, double m21, double m22)
{
    this->m[0] = m00;
    this->m[1] = m01;
    this->m[2] = m02;
    this->m[3] = m10;
    this->m[4] = m11;
    this->m[5] = m12;
    this->m[6] = m20;
    this->m[7] = m21;
    this->m[8] = m22;
}

Matrix3x3d::Matrix3x3d(Matrix3x3d *o)
{
    for (int i = 0; i < 9; i++) {
        this->m[i] = o->m[i];
    }
}

void Matrix3x3d::set(double m00, double m01, double m02, double m10, double m11, double m12, double m20, double m21, double m22)
{
    this->m[0] = m00;
    this->m[1] = m01;
    this->m[2] = m02;
    this->m[3] = m10;
    this->m[4] = m11;
    this->m[5] = m12;
    this->m[6] = m20;
    this->m[7] = m21;
    this->m[8] = m22;
}

void Matrix3x3d::set(Matrix3x3d *o)
{
    for (int i = 0; i < 9; i++) {
        this->m[i] = o->m[i];
    }
}

void Matrix3x3d::setZero()
{
    for (int i = 0; i < 9; i++) {
        this->m[i] = 0;
    }
}

void Matrix3x3d::setIdentity()
{
    this->m[0] = 1;
    this->m[1] = 0;
    this->m[2] = 0;
    this->m[3] = 0;
    this->m[4] = 1;
    this->m[5] = 0;
    this->m[6] = 0;
    this->m[7] = 0;
    this->m[8] = 1;
}

void Matrix3x3d::setSameDiagonal(double d)
{
    this->m[0] = d;
    this->m[4] = d;
    this->m[8] = d;
}

double Matrix3x3d::get(int row, int col)
{
    return this->m[(3 * row + col)];
}

void Matrix3x3d::set(int row, int col, double value)
{
    this->m[(3 * row + col)] = value;
}

void Matrix3x3d::getColumn(int col, Vector3d *v)
{
    v->x = this->m[col];
    v->y = this->m[col + 3];
    v->z = this->m[col + 6];
}

void Matrix3x3d::setColumn(int col, Vector3d *v)
{
    this->m[col] = v->x;
    this->m[col + 3] = v->y;
    this->m[col + 6] = v->z;
}

void Matrix3x3d::scale(double s)
{
    for (int i = 0; i < 9; i++) {
        this->m[i] *= s;
    }
}

void Matrix3x3d::plusEquals(Matrix3x3d *b)
{
    for (int i = 0; i < 9; i++) {
        this->m[i] += b->m[i];
    }
}

void Matrix3x3d::minusEquals(Matrix3x3d *b)
{
    for (int i = 0; i < 9; i++) {
        this->m[i] -= b->m[i];
    }
}

void Matrix3x3d::transpose()
{
    double tmp = this->m[1];
    this->m[1] = this->m[3];
    this->m[3] = tmp;
    tmp = this->m[2];
    this->m[2] = this->m[6];
    this->m[6] = tmp;
    tmp = this->m[5];
    this->m[5] = this->m[7];
    this->m[7] = tmp;
}

void Matrix3x3d::transpose(Matrix3x3d *result)
{
    double m1 = this->m[1];
    double m2 = this->m[2];
    double m5 = this->m[5];
    result->m[0] = this->m[0];
    result->m[1] = this->m[3];
    result->m[2] = this->m[6];
    result->m[3] = m1;
    result->m[4] = this->m[4];
    result->m[5] = this->m[7];
    result->m[6] = m2;
    result->m[7] = m5;
    result->m[8] = this->m[8];
}

void Matrix3x3d::add(Matrix3x3d *a, Matrix3x3d *b, Matrix3x3d *result)
{
    for (int i = 0; i < 9; i++) {
        result->m[i] = a->m[i] + b->m[i];
    }
}

void Matrix3x3d::mult(Matrix3x3d *a, Matrix3x3d *b, Matrix3x3d *result)
{
    result->set(a->m[0] * b->m[0] + a->m[1] * b->m[3] + a->m[2] * b->m[6],
                a->m[0] * b->m[1] + a->m[1] * b->m[4] + a->m[2] * b->m[7],
                a->m[0] * b->m[2] + a->m[1] * b->m[5] + a->m[2] * b->m[8],
                a->m[3] * b->m[0] + a->m[4] * b->m[3] + a->m[5] * b->m[6],
                a->m[3] * b->m[1] + a->m[4] * b->m[4] + a->m[5] * b->m[7],
                a->m[3] * b->m[2] + a->m[4] * b->m[5] + a->m[5] * b->m[8],
                a->m[6] * b->m[0] + a->m[7] * b->m[3] + a->m[8] * b->m[6],
                a->m[6] * b->m[1] + a->m[7] * b->m[4] + a->m[8] * b->m[7],
                a->m[6] * b->m[2] + a->m[7] * b->m[5] + a->m[8] * b->m[8]);
}

void Matrix3x3d::mult(Matrix3x3d *a, Vector3d *v, Vector3d *result)
{
    result->set(a->m[0] * v->x + a->m[1] * v->y + a->m[2] * v->z,
                a->m[3] * v->x + a->m[4] * v->y + a->m[5] * v->z,
                a->m[6] * v->x + a->m[7] * v->y + a->m[8] * v->z);
}

double Matrix3x3d::determinant()
{
    return this->get(0, 0) * (this->get(1, 1) * this->get(2, 2) - this->get(2, 1) * this->get(1, 2)) - this->get(0, 1) * (this->get(1, 0) * this->get(2, 2) - this->get(1, 2) * this->get(2, 0)) + this->get(0, 2) * (this->get(1, 0) * this->get(2, 1) - this->get(1, 1) * this->get(2, 0));
}

bool Matrix3x3d::invert(Matrix3x3d *result)
{
    double d = this->determinant();
    if (d == 0.0) {
        return false;
    }
    double invdet = 1.0 / d;
    result->set((this->m[4] * this->m[8] - this->m[7] * this->m[5]) * invdet,
                -(this->m[1] * this->m[8] - this->m[2] * this->m[7]) * invdet,
                (this->m[1] * this->m[5] - this->m[2] * this->m[4]) * invdet,
                -(this->m[3] * this->m[8] - this->m[5] * this->m[6]) * invdet,
                (this->m[0] * this->m[8] - this->m[2] * this->m[6]) * invdet,
                -(this->m[0] * this->m[5] - this->m[3] * this->m[2]) * invdet,
                (this->m[3] * this->m[7] - this->m[6] * this->m[4]) * invdet,
                -(this->m[0] * this->m[7] - this->m[6] * this->m[1]) * invdet,
                (this->m[0] * this->m[4] - this->m[3] * this->m[1]) * invdet);
    return true;
}
