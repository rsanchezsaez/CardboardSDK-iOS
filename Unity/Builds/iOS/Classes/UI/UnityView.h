#ifndef _TRAMPOLINE_UI_UNITYVIEW_H_
#define _TRAMPOLINE_UI_UNITYVIEW_H_

#import <UIKit/UIKit.h>
#include "Unity/GlesHelper.h"

@interface UnityView : GLView
{
}
// we take scale factor into account because gl backbuffer size depends on it
- (id)initWithFrame:(CGRect)frame scaleFactor:(CGFloat)scale;
- (id)initWithFrame:(CGRect)frame;
- (id)initFromMainScreen;

- (void)layoutSubviews;

// please note that it is "orientation if was full-screen view"
// due to changing view extents, script-side orientation might be different
- (ScreenOrientation)contentOrientation;

// layoutSubviews can be called from non-main thread, so we only set flag here
// willRotateTo will set content orientation (call this from view controller willRotateToInterfaceOrientation)
// didRotate will recreate gles surface is needed (call this from view controller didRotateFromInterfaceOrientation)
// if you want to simply reorient view (outside of view controller orientation handling) you can do:
// willRotateTo
// OrientView
// didRotate
// you can use [UnityAppContoller onForcedOrientation] for main view
- (void)willRotateTo:(ScreenOrientation)orientation;
- (void)didRotate;

- (void)recreateGLESSurfaceIfNeeded;
- (void)recreateGLESSurface;

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event;
@end



#endif // _TRAMPOLINE_UI_UNITYVIEW_H_
