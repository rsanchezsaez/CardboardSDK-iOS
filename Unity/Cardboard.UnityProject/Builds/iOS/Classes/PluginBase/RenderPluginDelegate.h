#ifndef _TRAMPOLINE_PLUGINBASE_RENDERPLUGINDELEGATE_H_
#define _TRAMPOLINE_PLUGINBASE_RENDERPLUGINDELEGATE_H_

#include "iPhone_Common.h"
#include "LifeCycleListener.h"

struct UnityRenderingSurface;	// GlesHelper.h
struct RenderingSurfaceParams;	// DisplayManager.h

// due to delicate nature of render loop we have just one delegate in app
// if you need to use several rendering delegates you need to do one of:
// 1. create custom delegate that will have code to combine effects by itself
// 2. use helper that simply holds array of delegates (which will work only in easiest cases)
@protocol RenderPluginDelegate<LifeCycleListener, NSObject>

@required
// this will be called right after gles intialization.
// surface pointer will never be changed, so you should keep it.
// the only valid fields in there as of now are layer and context
- (void)mainDisplayInited:(struct UnityRenderingSurface*)surface;

@optional

// this will be called before recreating main display surface (from [UnityView recreateGLESSurface])
// you can tweak params here.
// use it for enabling CVTextureCache support, or enforcing 32bit color and the likes
- (void)onBeforeMainDisplaySurfaceRecreate:(struct RenderingSurfaceParams*)params;

// this will be called right after recreating main display surface (from [UnityView recreateGLESSurface])
// as [UnityView recreateGLESSurface] is the only place where unity itself will trigger surface recreate
// you can use this method to update your rendering depending on changes
- (void)onAfterMainDisplaySurfaceRecreate;

// this will be called whenever we update orientation.
// please, use it only in cases where you need to adjust something due to this
// if you need to do some gles fiddling, onBefore(After)MainDisplaySurfaceRecreate should be better suited place,
// as, for example, if we go between landscapes, you dont need to change your framebuffers at all
- (void)onOrientationChange:(ScreenOrientation)newOrientation;

// this will be called after frame render and msaa resolve but before blitting to system FB
// you can expect that frame contents are ready (though still in target resolution)
// use it for anylizing/postprocessing rendered frame, taking screenshot and the like
// you should use targetFB if it is not 0
// otherwise use systemFB (covers case of intermediate fb not needed: no msaa, native res, no CVTextureCache involved)
- (void)onFrameResolved;
@end


// simple helper for common plugin stuff
// you can implement protocol directly, but subclassing this will provide some common implementation
@interface RenderPluginDelegate : NSObject<RenderPluginDelegate>
{
	struct UnityRenderingSurface* mainDisplaySurface;
}
- (void)mainDisplayInited:(struct UnityRenderingSurface*)surface;
@end


// simple helper to have an array of render delegates.
// be warned that it works in simplest cases only, when there is no interop between delegates
@interface RenderPluginArrayDelegate : RenderPluginDelegate
{
	NSArray* delegateArray;
}
@property(nonatomic, retain) NSArray* delegateArray;
- (void)mainDisplayInited:(struct UnityRenderingSurface*)surface;
- (void)onBeforeMainDisplaySurfaceRecreate:(struct RenderingSurfaceParams*)params;
- (void)onAfterMainDisplaySurfaceRecreate;
- (void)onOrientationChange:(ScreenOrientation)newOrientation;
- (void)onFrameResolved;
- (void)onDidBecomeActive;
- (void)onWillResignActive;
- (void)onDidReceiveMemoryWarning;
- (void)onWillTerminate;
@end


#endif // _TRAMPOLINE_PLUGINBASE_RENDERPLUGINDELEGATE_H_
