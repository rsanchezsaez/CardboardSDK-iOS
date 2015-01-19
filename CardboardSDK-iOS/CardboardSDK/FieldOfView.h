//
//  FieldOfView.h
//  CardboardSDK-iOS
//
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
    float left();

    void setRight(float right);
    float right();

    void setBottom(float bottom);
    float bottom();

    void setTop(float top);
    float top();
    
    GLKMatrix4 toPerspectiveMatrix(float near, float far);

    bool equals(FieldOfView *other);
    NSString* toString();

  private:
    float _left;
    float _right;
    float _bottom;
    float _top;

    GLKMatrix4 frustumM(float left, float right, float bottom, float top, float near, float far);
};

#endif 
