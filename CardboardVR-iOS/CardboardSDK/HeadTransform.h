//
//  HeadTransform.h
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-26.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#ifndef __CardboardVR_iOS__HeadTransform__
#define __CardboardVR_iOS__HeadTransform__

#import <GLKit/GLKit.h>

class HeadTransform
{
public:
    HeadTransform();
    void setHeadView(GLKMatrix4 headView);
    GLKMatrix4 getHeadView();
    GLKVector3 getTranslation();
    GLKVector3 getForwardVector();
    GLKVector3 getUpVector();
    GLKVector3 getRightVector();
    GLKQuaternion getQuaternion();
    GLKVector3 getEulerAngles();
private:
    GLKMatrix4 headView;
};

#endif 
