//
//  Matrix3x3d.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#ifndef __CardboardVR_iOS__Matrix3x3d__
#define __CardboardVR_iOS__Matrix3x3d__

#include "Vector3d.h"

class Matrix3x3d
{
public:
    double m[9];
public:
    Matrix3x3d();
    Matrix3x3d(double m00, double m01, double m02, double m10, double m11, double m12, double m20, double m21, double m22);
    Matrix3x3d(Matrix3x3d *o);
    void set(double m00, double m01, double m02, double m10, double m11, double m12, double m20, double m21, double m22);
    void set(Matrix3x3d *o);
    void setZero();
    void setIdentity();
    void setSameDiagonal(double d);
    double get(int row, int col);
    void set(int row, int col, double value);
    void getColumn(int col, Vector3d *v);
    void setColumn(int col, Vector3d *v);
    void scale(double s);
    void plusEquals(Matrix3x3d *b);
    void minusEquals(Matrix3x3d *b);
    void transpose();
    void transpose(Matrix3x3d *result);
    static void add(Matrix3x3d *a, Matrix3x3d *b, Matrix3x3d *result);
    static void mult(Matrix3x3d *a, Matrix3x3d *b, Matrix3x3d *result);
    static void mult(Matrix3x3d *a, Vector3d *v, Vector3d *result);
    double determinant();
    bool invert(Matrix3x3d *result);
};

#endif