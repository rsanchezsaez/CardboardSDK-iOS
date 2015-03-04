#include "RenderPluginDelegate.h"

@implementation RenderPluginDelegate

- (void)mainDisplayInited:(struct UnityRenderingSurface*)surface
{
	mainDisplaySurface = surface;

	// TODO: move lifecycle to init?
	UnityRegisterLifeCycleListener(self);
}
@end


@implementation RenderPluginArrayDelegate

@synthesize delegateArray;

- (void)callSelectorOnArray:(SEL)sel
{
	[delegateArray enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL* stop) {
		NSAssert([[object class] conformsToProtocol:@protocol(RenderPluginDelegate)], @"only render delegates can be added to RenderPluginArrayDelegate");
		if([object respondsToSelector:sel])
			[object performSelector:sel];
	}];
}
- (void)callSelectorOnArray:(SEL)sel withArg:(id)arg
{
	[delegateArray enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL* stop) {
		NSAssert([[object class] conformsToProtocol:@protocol(RenderPluginDelegate)], @"only render delegates can be added to RenderPluginArrayDelegate");
		if([object respondsToSelector:sel])
			[object performSelector:sel withObject:arg];
	}];
}


- (void)mainDisplayInited:(struct UnityRenderingSurface*)surface
{
	[super mainDisplayInited:surface];
	[self callSelectorOnArray:@selector(mainDisplayInited:) withArg:(id)surface];
}

- (void)onBeforeMainDisplaySurfaceRecreate:(struct RenderingSurfaceParams*)params
{
	[self callSelectorOnArray:@selector(onBeforeMainDisplaySurfaceRecreate:) withArg:(id)params];
}
- (void)onAfterMainDisplaySurfaceRecreate;
{
	[self callSelectorOnArray:@selector(onAfterMainDisplaySurfaceRecreate)];
}

- (void)onOrientationChange:(ScreenOrientation)newOrientation
{
	[self callSelectorOnArray:@selector(onOrientationChange:) withArg:(id)newOrientation];
}

- (void)onFrameResolved;
{
	[self callSelectorOnArray:@selector(onFrameResolved)];
}

- (void)onDidBecomeActive
{
	[self callSelectorOnArray:@selector(onDidBecomeActive)];
}
- (void)onWillResignActive;
{
	[self callSelectorOnArray:@selector(onWillResignActive)];
}
- (void)onDidReceiveMemoryWarning
{
	[self callSelectorOnArray:@selector(onDidReceiveMemoryWarning)];
}
- (void)onWillTerminate
{
	[self callSelectorOnArray:@selector(onWillTerminate)];
}

@end
