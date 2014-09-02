//
//  Vector3d.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#ifndef __CardboardVR_iOS__Vector3d__
#define __CardboardVR_iOS__Vector3d__

class Vector3d
{
public:
    double x;
    double y;
    double z;
public:
    Vector3d();
    Vector3d(double xx, double yy, double zz);
    Vector3d(Vector3d *other);
    void set(double xx, double yy, double zz);
    void setComponent(int i, double val);
    void setZero();
    void set(Vector3d *other);
    void scale(double s);
    void normalize();
    static double dot(Vector3d *a, Vector3d *b);
    double length();
    bool sameValues(Vector3d *other);
    static void sub(Vector3d *a, Vector3d *b, Vector3d *result);
    static void cross(Vector3d *a, Vector3d *b, Vector3d *result);
    static void ortho(Vector3d *v, Vector3d *result);
    static int largestAbsComponent(Vector3d *v);
};

#endif