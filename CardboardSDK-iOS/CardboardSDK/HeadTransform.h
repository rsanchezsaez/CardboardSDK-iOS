//
//  HeadTransform.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__HeadTransform__
#define __CardboardSDK_iOS__HeadTransform__

#import <GLKit/GLKit.h>


namespace CardboardSDK
{

class HeadTransform
{
  public:
    HeadTransform();

    void setHeadView(GLKMatrix4 headView);
    GLKMatrix4 headView();

    GLKVector3 translation();
    GLKVector3 forwardVector();
    GLKVector3 upVector();
    GLKVector3 rightVector();
    GLKQuaternion quaternion();
    GLKVector3 eulerAngles();

  private:
    GLKMatrix4 _headView;
};

}

#endif 
