
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
#include "UnityMetalSupport.h"

static DisplayManager* _DisplayManager = nil;
extern bool _ios80orNewer;

@interface DisplayConnection()
@property (readonly, nonatomic)	UnityDisplaySurfaceGLES*	surfaceGLES;
@property (readonly, nonatomic)	UnityDisplaySurfaceMTL*		surfaceMTL;
@end

@implementation DisplayConnection
{
	BOOL						_needRecreateSurface;
	CGSize						_requestedRenderingSize;

	UIScreen*					_screen;
	UIWindow*					_window;
	UIView*						_view;

	CGSize						_screenSize;

	UnityDisplaySurfaceBase*	_surface;
}

@synthesize screen      = _screen;
@synthesize window      = _window;
@synthesize view        = _view;
@synthesize screenSize  = _screenSize;
@synthesize surface		= _surface;

@synthesize surfaceGLES;
- (UnityDisplaySurfaceGLES*)surfaceGLES	{ assert(_surface->api != apiMetal); return (UnityDisplaySurfaceGLES*)_surface; }
@synthesize surfaceMTL;
- (UnityDisplaySurfaceMTL*)surfaceMTL	{ assert(_surface->api == apiMetal); return (UnityDisplaySurfaceMTL*)_surface; }


- (id)init:(UIScreen*)targetScreen
{
	if( (self = [super init]) )
	{
		self->_screen = targetScreen;

		targetScreen.currentMode = targetScreen.preferredMode;
		targetScreen.overscanCompensation = UIScreenOverscanCompensationInsetApplicationFrame;

		self->_screenSize = targetScreen.currentMode.size;

		self->_needRecreateSurface = NO;
		self->_requestedRenderingSize = CGSizeMake(-1,-1);
	}
	return self;
}

- (void)createWithWindow:(UIWindow*)window andView:(UIView*)view
{
	_window = window;
	_view	= view;

	CGSize layerSize = _view.layer.bounds.size;
	_screenSize = CGSizeMake(roundf(layerSize.width) * _view.contentScaleFactor, roundf(layerSize.height) * _view.contentScaleFactor);

}

- (void)createView:(BOOL)useForRendering
{
	[self createView:useForRendering showRightAway:YES];
}
- (void)createView:(BOOL)useForRendering showRightAway:(BOOL)showRightAway;
{
	NSAssert(_screen != [UIScreen mainScreen], @"DisplayConnection for mainScreen should be created with createWithWindow:andView:");
	if(_view == nil)
	{
		UIWindow* window = [[UIWindow alloc] initWithFrame: _screen.bounds];
		window.screen = _screen;

		UIView* view = [(useForRendering ? [UnityRenderingView alloc] : [UIView alloc]) initWithFrame: _screen.bounds];
		view.contentScaleFactor = UnityScreenScaleFactor(_screen);

		[self createWithWindow:window andView:view];

		if(showRightAway)
		{
			[window addSubview:view];
			[window makeKeyAndVisible];
		}
	}
}

- (void)shouldShowWindow:(BOOL)show
{
	_window.hidden = show ? NO : YES;
	_window.screen = show ? _screen : nil;
}

- (void)initRendering
{
	if(_surface == 0)
	{
		int api = UnitySelectedRenderingAPI();
		if(api == apiMetal)
		{
			UnityDisplaySurfaceMTL* surf = new UnityDisplaySurfaceMTL();
			surf->layer			= (CAMetalLayer*)_view.layer;
			surf->device		= UnityGetMetalDevice();
			surf->commandQueue	= [surf->device newCommandQueue];
			_surface = surf;
		}
		else
		{
			UnityDisplaySurfaceGLES* surf = new UnityDisplaySurfaceGLES();
			surf->layer		= (CAEAGLLayer*)_view.layer;
			surf->context	= UnityCreateContextEAGL(UnityGetDataContextGLES(), 0);
			_surface = surf;
		}
		_surface->api	= api;
	}
}


- (void)recreateSurface:(RenderingSurfaceParams)params
{
	[self initRendering];

	CGSize layerSize = _view.layer.bounds.size;
	float scale = UnityScreenScaleFactor(_screen);
	_screenSize = CGSizeMake(layerSize.width * scale, layerSize.height * scale);

	bool systemSizeChanged	= _surface->systemW != _screenSize.width || _surface->systemH != _screenSize.height;
	bool msaaChanged		= _supportsMSAA && (_surface->msaaSamples != params.msaaSampleCount);
	bool depthfmtChanged	= _surface->disableDepthAndStencil != params.disableDepthAndStencil;
	bool cvCacheChanged		= _surface->useCVTextureCache != params.useCVTextureCache;

	bool renderSizeChanged  = false;
	if(		(params.renderW > 0 && _surface->targetW != params.renderW)		// changed resolution
		||	(params.renderH > 0 && _surface->targetH != params.renderH)		// changed resolution
		||	(params.renderW <= 0 && _surface->targetW != _surface->systemW) // no longer need intermediate fb
		||	(params.renderH <= 0 && _surface->targetH != _surface->systemH) // no longer need intermediate fb
	)
	{
		renderSizeChanged = true;
	}

	bool recreateSystemSurface		= systemSizeChanged;
	bool recreateRenderingSurface	= systemSizeChanged || renderSizeChanged || msaaChanged || cvCacheChanged;
	bool recreateDepthbuffer		= systemSizeChanged || renderSizeChanged || msaaChanged || depthfmtChanged;

	_surface->disableDepthAndStencil= params.disableDepthAndStencil;

	_surface->systemW = _screenSize.width;
	_surface->systemH = _screenSize.height;

	_surface->targetW = params.renderW > 0 ? params.renderW : _surface->systemW;
	_surface->targetH = params.renderH > 0 ? params.renderH : _surface->systemH;

	_surface->msaaSamples = _supportsMSAA ? params.msaaSampleCount : 0;
	_surface->srgb = params.srgb;
	_surface->useCVTextureCache	= params.useCVTextureCache;

	if(UnitySelectedRenderingAPI() == apiMetal)
		recreateSystemSurface = recreateSystemSurface || self.surfaceMTL->systemColorRB == 0;
	else
		recreateSystemSurface = recreateSystemSurface || self.surfaceGLES->systemFB == 0;

	if (recreateSystemSurface)
		CreateSystemRenderingSurface(_surface);
	if(recreateRenderingSurface)
		CreateRenderingSurface(_surface);
	if(recreateDepthbuffer)
		CreateSharedDepthbuffer(_surface);
	if (recreateSystemSurface || recreateRenderingSurface)
		CreateUnityRenderBuffers(_surface);
}

- (void)dealloc
{
	if(_surface)
	{
		DestroySystemRenderingSurface(_surface);
		DestroyRenderingSurface(_surface);
		DestroySharedDepthbuffer(_surface);
		DestroyUnityRenderBuffers(_surface);

		if(UnitySelectedRenderingAPI() == apiMetal)
		{
			self.surfaceMTL->device	= nil;
			self.surfaceMTL->layer	= nil;
		}
		else
		{
			self.surfaceGLES->context	= nil;
			self.surfaceGLES->layer		= nil;
		}
	}

	delete _surface;
	_surface = 0;

	_view	= nil;
	_window	= nil;
}

- (void)present
{
	PreparePresent(self.surface);
	Present(self.surface);

	if(_needRecreateSurface)
	{
		RenderingSurfaceParams params =
		{
			_surface->msaaSamples, (int)_requestedRenderingSize.width, (int)_requestedRenderingSize.height,
			_surface->disableDepthAndStencil, self.surface->cvTextureCache != 0
		};
		[self recreateSurface:params];

		_needRecreateSurface = NO;
		_requestedRenderingSize = CGSizeMake(_surface->targetW, _surface->targetH);
	}
}


- (void)requestRenderingResolution:(CGSize)res
{
	_requestedRenderingSize = res;
	_needRecreateSurface    = YES;
}
@end


@implementation DisplayManager
{
	NSMapTable*         _displayConnection;
	DisplayConnection*  _mainDisplay;
}

@synthesize mainDisplay     = _mainDisplay;
@synthesize displayCount;
- (int)displayCount { return _displayConnection.count; }


- (void)registerScreen:(UIScreen*)screen
{
	[_displayConnection setObject: [[DisplayConnection alloc] init:screen] forKey:screen];
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

		_displayConnection = [NSMapTable
			mapTableWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality
			valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality
		];

		for(UIScreen* screen in [UIScreen screens])
			[self registerScreen:screen];

		_mainDisplay = self[[UIScreen mainScreen]];
	}
	return self;
}

- (BOOL)displayAvailable:(UIScreen*)targetScreen;
{
	return self[targetScreen] != nil;
}

- (DisplayConnection*)display:(UIScreen*)targetScreen
{
	return self[targetScreen];
}

- (id)objectForKeyedSubscript:(id)key
{
	NSAssert([key isKindOfClass:[UIScreen class]], @"DisplayManager allows only UIScreen as subscript");
	return [_displayConnection objectForKey:(UIScreen*)key];
}

- (void)updateDisplayListInUnity
{
	UnityUpdateDisplayList();
}

- (void)enumerateDisplaysWithBlock:(void (^)(DisplayConnection* conn))block
{
	for(UIScreen* screen in _displayConnection)
	{
		// if we want simple mirroring unity wont create rendering backing for display
		// in that case we dont want to touch Display
		DisplayConnection* conn = [_displayConnection objectForKey:screen];
		if(conn.surface != nil)
			block(conn);
	}
}

- (void)prepareRendering
{
	[self enumerateDisplaysWithBlock:^(DisplayConnection* conn)
		{
			PrepareRendering(conn.surface);
		}
	];
	PrepareFrameRendering();
}
- (void)teardownRendering
{
	[self enumerateDisplaysWithBlock:^(DisplayConnection* conn)
		{
			TeardownRendering(conn.surface);
		}
	];
	TeardownFrameRendering();
}
- (void)present
{
	[self enumerateDisplaysWithBlock:^(DisplayConnection* conn)
		{
			[conn present];
		}
	];
}


- (void)screenDidConnect:(NSNotification*)notification
{
	[self registerScreen: (UIScreen*)[notification object]];
	[self updateDisplayListInUnity];
}

- (void)screenDidDisconnect:(NSNotification*)notification
{
	UIScreen*           screen  = (UIScreen*)[notification object];
	DisplayConnection*  conn    = (DisplayConnection*)self[screen];

	if(conn != nil && conn.surface != nil)
		UnityDisableRenderBuffers(conn.surface->unityColorBuffer, conn.surface->unityDepthBuffer);

	[_displayConnection removeObjectForKey:screen];
	conn = nil;
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

	if(conn.view == nil)
		[conn createView:YES];

	int api = UnitySelectedRenderingAPI();

	bool needRecreate = false;
	if(conn.surface == 0)		needRecreate = true;
	else if(api == apiMetal)	needRecreate = conn.surfaceMTL->layer == nil;
	else						needRecreate = conn.surfaceGLES->systemFB == 0;

	if(needRecreate)
	{
		RenderingSurfaceParams params = {0, -1, -1, UnityDisableDepthAndStencilBuffers(), false};
		[conn recreateSurface:params];
		{
			DisplayConnection* main = [DisplayManager Instance].mainDisplay;

			if(api != apiMetal)
				[EAGLContext setCurrentContext:UnityGetMainScreenContextGLES()];

			PrepareRendering(main.surface);
		}
	}
}

extern "C" int UnityDisplayManager_DisplayCount()
{
	return [DisplayManager Instance].displayCount;
}

extern "C" bool UnityDisplayManager_DisplayAvailable(void* nativeDisplay)
{
	return [[DisplayManager Instance] displayAvailable:(__bridge UIScreen*)nativeDisplay];
}

extern "C" void UnityDisplayManager_DisplaySystemResolution(void* nativeDisplay, int* w, int* h)
{
	DisplayConnection* conn = [DisplayManager Instance][(__bridge UIScreen*)nativeDisplay];
	EnsureDisplayIsInited(conn);

	*w = (int)conn.surface->systemW;
	*h = (int)conn.surface->systemH;
}

extern "C" void UnityDisplayManager_DisplayRenderingResolution(void* nativeDisplay, int* w, int* h)
{
	DisplayConnection* conn = [DisplayManager Instance][(__bridge UIScreen*)nativeDisplay];
	EnsureDisplayIsInited(conn);

	*w = (int)conn.surface->targetW;
	*h = (int)conn.surface->targetH;
}

extern "C" void UnityDisplayManager_DisplayRenderingBuffers(void* nativeDisplay, void** colorBuffer, void** depthBuffer)
{
	DisplayConnection* conn = [DisplayManager Instance][(__bridge UIScreen*)nativeDisplay];
	EnsureDisplayIsInited(conn);

	if(colorBuffer) *colorBuffer = conn.surface->unityColorBuffer;
	if(depthBuffer) *depthBuffer = conn.surface->unityDepthBuffer;
}

extern "C" void UnityDisplayManager_SetRenderingResolution(void* nativeDisplay, int w, int h)
{
	UIScreen*           screen  = (__bridge UIScreen*)nativeDisplay;
	DisplayConnection*  conn    = [DisplayManager Instance][screen];
	EnsureDisplayIsInited(conn);

	if(screen == [UIScreen mainScreen])
		UnityRequestRenderingResolution(w,h);
	else
		[conn requestRenderingResolution:CGSizeMake(w,h)];
}

extern "C" void UnityDisplayManager_ShouldShowWindowOnDisplay(void* nativeDisplay, bool show)
{
	UIScreen*           screen  = (__bridge UIScreen*)nativeDisplay;
	DisplayConnection*  conn    = [DisplayManager Instance][screen];
	EnsureDisplayIsInited(conn);

	if(screen != [UIScreen mainScreen])
		[conn shouldShowWindow:show];
}

extern "C" EAGLContext* UnityGetMainScreenContextGLES()
{
	return GetMainDisplay().surfaceGLES->context;
}
extern "C" EAGLContext* UnityGetContextEAGL(int)
{
	return GetMainDisplay().surfaceGLES->context;
}

extern "C" float UnityScreenScaleFactor(UIScreen* screen)
{
#if defined(__IPHONE_8_0)
	// iPhone 6+ pretends to be a x3 device, while its physical screen is x2.6 something. So we
	// query nativeScale to get the true device resolution to avoid unnecessarily large frame
	// buffers and downscaling.
	if([screen respondsToSelector:@selector(nativeScale)])
		return screen.nativeScale;
#endif
	return screen.scale;
}
