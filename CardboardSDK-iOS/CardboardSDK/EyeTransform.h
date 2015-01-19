//
//  EyeTransform.h
//  CardboardSDK-iOS
//
//

#ifndef __CardboardVR_iOS__EyeTransform__
#define __CardboardVR_iOS__EyeTransform__

#import <GLKit/GLKit.h>

class EyeParams;

class EyeTransform
{
  public:
    EyeTransform(EyeParams *params);

    GLKMatrix4 eyeView();
    void setEyeView(GLKMatrix4 eyeView);

    GLKMatrix4 perspective();
    void setPerspective(GLKMatrix4 perspective);

    EyeParams *eyeParams();

  private:
    EyeParams *_eyeParams;
    GLKMatrix4 _eyeView;
    GLKMatrix4 _perspective;
};

#endif 