//
//  EyeTransform.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-26.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#ifndef __CardboardVR_iOS__EyeTransform__
#define __CardboardVR_iOS__EyeTransform__

#import <GLKit/GLKit.h>

class EyeParams;

class EyeTransform
{
public:
    EyeTransform(EyeParams *params);
    GLKMatrix4 getEyeView();
    void setEyeView(GLKMatrix4 eyeView);
    GLKMatrix4 getPerspective();
    void setPerspective(GLKMatrix4 perspective);
    EyeParams* getParams();
private:
    EyeParams *eyeParams;
    GLKMatrix4 eyeView;
    GLKMatrix4 perspective;
};

#endif 