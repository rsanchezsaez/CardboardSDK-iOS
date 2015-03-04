
#include "DisplayManager.h"
#include "EAGLContextHelper.h"
#include "GlesHelper.h"
#include "UI/UnityView.h"

#include "UnityAppController.h"
#include "UI/UnityAppController+ViewHandling.h"

#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

static DisplayManager* _DisplayManager = nil;
extern bool _ios80orNewer;

extern "C" void InitEAGLLayer(void* eaglLayer, bool use32bitColor);

@implementation DisplayConnection
{
	BOOL            needRecreateSurface;
	CGSize          requestedRenderingSize;
}

- (id)init:(UIScreen*)targetScreen
{
	if( (self = [super init]) )
	{
		self->screen = targetScreen;

		if([targetScreen respondsToSelector:@selector(preferredMode)])
			targetScreen.currentMode = targetScreen.preferredMode;
		if([targetScreen respondsToSelector:@selector(overscanCompensation)])
			targetScreen.overscanCompensation = UIScreenOverscanCompensationInsetApplicationFrame;

		self->screenSize = targetScreen.currentMode.size;

		self->needRecreateSurface = NO;
		self->requestedRenderingSize = CGSizeMake(-1,-1);

		self->window = nil;
		self->view = nil;
		::memset(&self->surface, 0x00, sizeof(UnityRenderingSurface));
	}
	return self;
}

- (id)createView:(BOOL)useWithGles
{
	return [self createView:useWithGles showRightAway:YES];
}

- (id)createView:(BOOL)useWithGles showRightAway:(BOOL)showRightAway;
{
	if(view == nil)
	{
		window = [[UIWindow alloc] initWithFrame: [screen bounds]];
		window.screen = screen;

		if(screen == [UIScreen mainScreen])
		{
			view = [GetAppController() initUnityView];
			NSAssert([view isKindOfClass:[UnityView class]], @"You MUST use UnityView subclass as unity view");
		}
		else
		{
			view = useWithGles ? [GLView alloc] : [UIView alloc];
			[view initWithFrame: [self->screen bounds]];
		}

		view.contentScaleFactor = UnityScreenScaleFactor(self->screen);

		if(showRightAway)
		{
			[window addSubview:view];
			[window makeKeyAndVisible];
		}

		CGSize	layerSize	= [view.layer bounds].size;
		CGFloat	scale		= view.contentScaleFactor;
		screenSize = CGSizeMake(layerSize.width * scale, layerSize.height * scale);
	}
	// TODO: create context here: for now we cant call it as we will query unity for target api
	/*
	if(surface.context == nil)
	{
		surface.layer = (CAEAGLLayer*)view.layer;
		surface.context = CreateContext([[DisplayManager Instance] mainDisplay]->surface.context);
	}
	*/

	return self;
}

- (void)shouldShowWindow:(BOOL)show
{
	window.hidden = show ? NO : YES;
	window.screen = show ? screen : nil;
}


- (void)createContext:(EAGLContext*)parent
{
	if(surface.context == nil)
	{
		surface.layer = (CAEAGLLayer*)view.layer;
		surface.context = CreateContext(parent);
	}
}

- (void)recreateSurface:(RenderingSurfaceParams)params
{
	[self createContext:[[DisplayManager Instance] mainDisplay]->surface.context];

	CGSize	layerSize	= [view.layer bounds].size;
	CGFloat	scale		= UnityScreenScaleFactor(screen);
	screenSize = CGSizeMake(layerSize.width * scale, layerSize.height * scale);

	bool systemSizeChanged	= screenSize.width != surface.systemW || screenSize.height != surface.systemH;
	bool msaaChanged		= (surface.msaaSamples != params.msaaSampleCount && _supportsMSAA);
	bool colorfmtChanged	= params.use32bitColor != surface.use32bitColor;
	bool depthfmtChanged	= params.use24bitDepth != surface.use24bitDepth;
	bool useCVCacheChanged	= params.useCVTextureCache != surface.useCVTextureCache;

	bool renderSizeChanged  = false;
	if(		(params.renderW > 0 && surface.targetW != params.renderW)	// changed resolution
		||	(params.renderH > 0 && surface.targetH != params.renderH)	// changed resolution
		||	(params.renderW <= 0 && surface.targetW != surface.systemW)	// no longer need intermediate fb
		||	(params.renderH <= 0 && surface.targetH != surface.systemH)	// no longer need intermediate fb
	  )
	{
		renderSizeChanged = true;
	}

	bool recreateSystemSurface		= (surface.systemFB == 0) || systemSizeChanged || colorfmtChanged;
	bool recreateRenderingSurface	= systemSizeChanged || renderSizeChanged || msaaChanged || colorfmtChanged || useCVCacheChanged;
	bool recreateDepthbuffer		= systemSizeChanged || renderSizeChanged || msaaChanged || depthfmtChanged;


	surface.use32bitColor		= params.use32bitColor;
	surface.use24bitDepth		= params.use24bitDepth;
	surface.useCVTextureCache	= params.useCVTextureCache;

	surface.systemW = screenSize.width;
	surface.systemH = screenSize.height;

	surface.targetW = params.renderW > 0 ? params.renderW : surface.systemW;
	surface.targetH = params.renderH > 0 ? params.renderH : surface.systemH;

	surface.msaaSamples = _supportsMSAA ? params.msaaSampleCount : 0;


	if(recreateSystemSurface)
		CreateSystemRenderingSurface(&surface);
	if(recreateRenderingSurface)
		CreateRenderingSurface(&surface);
	if(recreateDepthbuffer)
		CreateSharedDepthbuffer(&surface);
	if(recreateSystemSurface || recreateRenderingSurface || recreateDepthbuffer)
		CreateUnityRenderBuffers(&surface);
}

- (void)dealloc
{
	if(surface.context != nil)
	{
		DestroySystemRenderingSurface(&surface);
		DestroyRenderingSurface(&surface);
		DestroySharedDepthbuffer(&surface);
		DestroyUnityRenderBuffers(&surface);

		[surface.context release];
		surface.context = nil;
		surface.layer   = nil;

		::memset(&self->surface, 0x00, sizeof(UnityRenderingSurface));
	}

	[view release];
	view = nil;

	[window release];
	window = nil;

	[super dealloc];
}

- (void)present
{
	if(surface.context != nil)
	{
		PreparePresentRenderingSurface(&surface, [[DisplayManager Instance] mainDisplay]->surface.context);

		EAGLContextSetCurrentAutoRestore autorestore(surface.context);
		GLES_CHK(glBindRenderbuffer(GL_RENDERBUFFER, surface.systemColorRB));
		[surface.context presentRenderbuffer:GL_RENDERBUFFER];

		if(needRecreateSurface)
		{
			RenderingSurfaceParams params =
			{
				surface.msaaSamples, (int)requestedRenderingSize.width, (int)requestedRenderingSize.height,
				surface.use32bitColor, surface.use24bitDepth, surface.cvTextureCache != 0
			};
			[self recreateSurface:params];

			needRecreateSurface = NO;
			requestedRenderingSize = CGSizeMake(surface.targetW, surface.targetH);
		}
	}
}


- (void)requestRenderingResolution:(CGSize)res
{
	requestedRenderingSize = res;
	needRecreateSurface    = YES;
}
@end


@implementation DisplayManager

- (void)registerScreen:(UIScreen*)screen
{
	NSValue* key = [NSValue valueWithPointer:screen];
	NSValue* val = [NSValue valueWithPointer: [[DisplayConnection alloc] init:screen]];
	[displayConnection setObject:val forKey:key];
}

- (id)init
{
	if( (self = [super init]) )
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
											  selector:@selector(screenDidConnect:)
											  name:UIScreenDidConnectNotification
											  object:nil
		];

		[[NSNotificationCenter defaultCenter] addObserver:self
											  selector:@selector(screenDidDisconnect:)
											  name:UIScreenDidDisconnectNotification
											  object:nil
		];

		displayConnection = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
		[[UIScreen screens] enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL* stop) {
			[self registerScreen:(UIScreen*)object];
		}];

		// on pre-ios6 on devices that dont support airplay (iphone3gs) [UIScreen screens] will return empty array
		if([displayConnection count] == 0)
			[self registerScreen:[UIScreen mainScreen]];

		mainDisplay = [self display:[UIScreen mainScreen]];
	}
	return self;
}

- (int)displayCount
{
	return displayConnection.count;
}

- (DisplayConnection*)mainDisplay
{
	return mainDisplay;
}

- (BOOL)displayAvailable:(UIScreen*)targetScreen;
{
	return [self display:targetScreen] != nil;
}

- (DisplayConnection*)display:(UIScreen*)targetScreen
{
	NSValue* key = [NSValue valueWithPointer:targetScreen];
	NSValue* val = [displayConnection objectForKey:key];

	return val ? (DisplayConnection*)(val.pointerValue) : nil;
}

- (void)updateDisplayListInUnity
{
	UnityUpdateDisplayList();
}

- (void)presentAll
{
	[displayConnection enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
		void* conn = ((NSValue*)obj).pointerValue;
		[(DisplayConnection*)conn present];
	}];
}

- (void)presentAllButMain
{
	[displayConnection enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
		void* conn = ((NSValue*)obj).pointerValue;
		if((DisplayConnection*)conn != [self mainDisplay])
			[(DisplayConnection*)conn present];
	}];
}


- (void)screenDidConnect:(NSNotification*)notification
{
	[self registerScreen: (UIScreen*)[notification object]];
	[self updateDisplayListInUnity];
}

- (void)screenDidDisconnect:(NSNotification*)notification
{
	UIScreen* screen = (UIScreen*)[notification object];

	// first of all disable rendering to these buffers
	{
		DisplayConnection* conn = [[DisplayManager Instance] display:screen];
		if(conn->surface.systemFB != 0)
			UnityDisableRenderBuffers(conn->surface.unityColorBuffer, conn->surface.unityDepthBuffer);
	}

	NSValue* key = [NSValue valueWithPointer:screen];
	NSValue* val = [displayConnection objectForKey:key];
	if(val != nil)
	{
		[(DisplayConnection*)val.pointerValue release];
		[displayConnection removeObjectForKey:key];
	}

	[self updateDisplayListInUnity];
}

+ (void)Initialize
{
	NSAssert(_DisplayManager == nil, @"[DisplayManager Initialize] called after creating handler");
	if(!_DisplayManager)
		_DisplayManager = [[DisplayManager alloc] init];
}

+ (DisplayManager*)Instance
{
	if(!_DisplayManager)
		_DisplayManager = [[DisplayManager alloc] init];

	return _DisplayManager;
}

@end

//==============================================================================
//
//  Unity Interface:

static void EnsureDisplayIsInited(DisplayConnection* conn)
{
	// main screen view will be created in AppController,
	// so we can assume that we need to init secondary display from script
	// meaning: gles + show right away

	if(conn->view == nil)
		[conn createView:YES];

	// careful here: we dont want to trigger surface recreation
	if(conn->surface.systemFB == 0)
	{
		RenderingSurfaceParams params = {0, -1, -1, UnityUse32bitDisplayBuffer(), UnityUse24bitDepthBuffer(), false};
		[conn recreateSurface:params];
		{
			// make sure we end up with correct context/fbo setup
			DisplayConnection* main = [[DisplayManager Instance] mainDisplay];
			[EAGLContext setCurrentContext:main->surface.context];
			SetupUnityDefaultFBO(&main->surface);
		}
	}
}

extern "C" int UnityDisplayManager_DisplayCount()
{
	return [[DisplayManager Instance] displayCount];
}

extern "C" bool UnityDisplayManager_DisplayAvailable(void* nativeDisplay)
{
	return [[DisplayManager Instance] displayAvailable:(UIScreen*)nativeDisplay];
}

extern "C" void UnityDisplayManager_DisplaySystemResolution(void* nativeDisplay, int* w, int* h)
{
	DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
	EnsureDisplayIsInited(conn);

	*w = (int)conn->surface.systemW;
	*h = (int)conn->surface.systemH;
}

extern "C" void UnityDisplayManager_DisplayRenderingResolution(void* nativeDisplay, int* w, int* h)
{
	DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
	EnsureDisplayIsInited(conn);

	*w = (int)conn->surface.targetW;
	*h = (int)conn->surface.targetH;
}

extern "C" void UnityDisplayManager_DisplayRenderingBuffers(void* nativeDisplay, void** colorBuffer, void** depthBuffer)
{
	DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
	EnsureDisplayIsInited(conn);

	if(colorBuffer) *colorBuffer = conn->surface.unityColorBuffer;
	if(depthBuffer) *depthBuffer = conn->surface.unityDepthBuffer;
}

extern "C" void UnityDisplayManager_SetRenderingResolution(void* nativeDisplay, int w, int h)
{
	DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
	EnsureDisplayIsInited(conn);

	if((UIScreen*)nativeDisplay == [UIScreen mainScreen])
		UnityRequestRenderingResolution(w,h);
	else
		[conn requestRenderingResolution:CGSizeMake(w,h)];
}

extern "C" void UnityDisplayManager_ShouldShowWindowOnDisplay(void* nativeDisplay, bool show)
{
	DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
	if(conn != [DisplayManager Instance].mainDisplay)
		[conn shouldShowWindow:show];
}

extern "C" float UnityScreenScaleFactor(UIScreen* screen)
{
#if defined(__IPHONE_8_0)
	if([screen respondsToSelector:@selector(nativeScale)])
		return screen.nativeScale;
#endif
	return screen.scale;
}
