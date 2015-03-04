#ifndef _TRAMPOLINE_UNITY_DISPLAYMANAGER_H_
#define _TRAMPOLINE_UNITY_DISPLAYMANAGER_H_

#include "GlesHelper.h"

@class EAGLContext;
@class UnityView;

typedef struct
RenderingSurfaceParams
{
	int  msaaSampleCount;
	int  renderW;
	int  renderH;

	bool use32bitColor;
	bool use24bitDepth;
	bool useCVTextureCache;
}
RenderingSurfaceParams;


@interface DisplayConnection : NSObject
{
@public
    UIScreen*       screen;
    UIWindow*       window;
    UIView*         view;

    CGSize          screenSize;

    UnityRenderingSurface   surface;
}
- (id)init:(UIScreen*)targetScreen;
- (id)createView:(BOOL)useWithGles showRightAway:(BOOL)showRightAway;
- (id)createView:(BOOL)useWithGles;

- (void)shouldShowWindow:(BOOL)show;

- (void)dealloc;

- (void)createContext:(EAGLContext*)parent;
- (void)recreateSurface:(RenderingSurfaceParams)params;

- (void)requestRenderingResolution:(CGSize)res;

- (void)present;
@end


@interface DisplayManager : NSObject
{
    NSMutableDictionary*    displayConnection;
    DisplayConnection*      mainDisplay;
}
- (int)displayCount;
- (BOOL)displayAvailable:(UIScreen*)targetScreen;
- (DisplayConnection*)display:(UIScreen*)targetScreen;
- (DisplayConnection*)mainDisplay;

- (void)updateDisplayListInUnity;

- (void)presentAll;
- (void)presentAllButMain;

+ (void)Initialize;
+ (DisplayManager*)Instance;
@end

inline DisplayConnection* 		GetMainDisplay()
{
	return [[DisplayManager Instance] mainDisplay];
}
inline UnityRenderingSurface*	GetMainRenderingSurface()
{
	return &GetMainDisplay()->surface;
}

#endif // _TRAMPOLINE_UNITY_DISPLAYMANAGER_H_
