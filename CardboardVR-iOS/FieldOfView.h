//
//  FieldOfView.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-26.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#ifndef __CardboardVR_iOS__FieldOfView__
#define __CardboardVR_iOS__FieldOfView__

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

class FieldOfView
{
public:
    FieldOfView();
    FieldOfView(float left, float right, float bottom, float top);
    FieldOfView(FieldOfView *other);
    void setLeft(float left);
    float getLeft();
    void setRight(float right);
    float getRight();
    void setBottom(float bottom);
    float getBottom();
    void setTop(float top);
    float getTop();
    GLKMatrix4 toPerspectiveMatrix(float near, float far);
    bool equals(FieldOfView *other);
    NSString* toString();
private:
    float left;
    float right;
    float bottom;
    float top;
private:
    GLKMatrix4 frustumM(float left, float right, float bottom, float top, float near, float far);
};

#endif 
