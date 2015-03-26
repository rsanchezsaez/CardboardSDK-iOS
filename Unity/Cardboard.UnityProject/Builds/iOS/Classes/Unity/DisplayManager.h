#pragma once

#include "GlesHelper.h"

@class EAGLContext;
@class UnityView;

typedef struct
RenderingSurfaceParams
{
	// rendering setup
	int	msaaSampleCount;
	int	renderW;
	int	renderH;
	int	srgb;

	// unity setup
	int	disableDepthAndStencil;
	int	useCVTextureCache;
}
RenderingSurfaceParams;


@interface DisplayConnection : NSObject
- (id)init:(UIScreen*)targetScreen;
- (void)dealloc;

- (void)createView:(BOOL)useForRendering showRightAway:(BOOL)showRightAway;
- (void)createView:(BOOL)useForRendering;
- (void)createWithWindow:(UIWindow*)window andView:(UIView*)view;
- (void)initRendering;
- (void)recreateSurface:(RenderingSurfaceParams)params;

- (void)shouldShowWindow:(BOOL)show;
- (void)requestRenderingResolution:(CGSize)res;
- (void)present;

@property (readonly, copy, nonatomic)	UIScreen*				screen;
@property (readonly, copy, nonatomic)	UIWindow*				window;
@property (readonly, copy, nonatomic)	UIView*					view;


@property (readonly, nonatomic)			CGSize						screenSize;
@property (readonly, nonatomic)			UnityDisplaySurfaceBase*	surface;

@end


@interface DisplayManager : NSObject
- (id)objectForKeyedSubscript:(id)key;
- (BOOL)displayAvailable:(UIScreen*)targetScreen;
- (void)updateDisplayListInUnity;

- (void)prepareRendering;
- (void)present;
- (void)teardownRendering;

- (void)enumerateDisplaysWithBlock:(void (^)(DisplayConnection* conn))block;

+ (void)Initialize;
+ (DisplayManager*)Instance;

@property (readonly, nonatomic)	DisplayConnection*	mainDisplay;

@property (readonly, nonatomic)	int					displayCount;

@end

inline DisplayConnection*			GetMainDisplay()
{
	return [DisplayManager Instance].mainDisplay;
}
inline UnityDisplaySurfaceBase*		GetMainDisplaySurface()
{
	return GetMainDisplay().surface;
}
