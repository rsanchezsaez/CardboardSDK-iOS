#pragma once

#include "Unity/GlesHelper.h"

@interface UnityView : UnityRenderingView
{
}

// we take scale factor into account because gl backbuffer size depends on it
- (id)initWithFrame:(CGRect)frame scaleFactor:(CGFloat)scale;
- (id)initWithFrame:(CGRect)frame;
- (id)initFromMainScreen;

// layoutSubviews can be called from non-main thread, so we only set flag here
- (void)layoutSubviews;

// will simply update content orientation (it might be tweaked in layoutSubviews, due to disagreement between unity and view controller)
- (void)willRotateToOrientation:(UIInterfaceOrientation)toOrientation fromOrientation:(UIInterfaceOrientation)fromOrientation;
// will recreate gles backing if needed and repaint once to make sure we dont have black frame creeping in
- (void)didRotate;

- (void)recreateGLESSurfaceIfNeeded;
- (void)recreateGLESSurface;

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event;

// will match script-side Screen.orientation
@property (nonatomic, readonly) ScreenOrientation contentOrientation;

@end
