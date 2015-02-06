//
//  Eye.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__Eye__
#define __CardboardSDK_iOS__Eye__

#import <GLKit/GLKit.h>


namespace CardboardSDK
{

class FieldOfView;
class Viewport;


class Eye
{
  public:

    typedef enum
    {
        TypeMonocular = 0,
        TypeLeft = 1,
        TypeRight = 2
    } Type;

    Eye(Type eye);
    ~Eye();

    Type type();

    GLKMatrix4 eyeView();
    void setEyeView(GLKMatrix4 eyeView);
    GLKMatrix4 perspective(float zNear, float zFar);
    
    Viewport *viewport();
    FieldOfView *fov();
    
    void setProjectionChanged();
    
  private:
    Type _type;
    GLKMatrix4 _eyeView;
    Viewport *_viewport;
    FieldOfView *_fov;
    bool _projectionChanged;
    GLKMatrix4 _perspective;
    float _lastZNear;
    float _lastZFar;
};

}

#endif