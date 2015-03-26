#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#include "UnityAppController.h"
#include "UI/UnityView.h"
#include "UI/UnityViewControllerBase.h"
#include "UI/OrientationSupport.h"
#include "Unity/ObjCRuntime.h"


@interface UnityVideoViewController : MPMoviePlayerViewController {}
@end

@interface MPVideoContext : NSObject
{
@public
	MPMoviePlayerController*	moviePlayer;
	UnityVideoViewController*	movieController;
	UIView*						overlayView;

	MPMovieControlStyle			controlMode;
	MPMovieScalingMode			scalingMode;
	UIColor*					bgColor;

	bool						cancelOnTouch;
}

- (id)initAndPlay:(NSURL*)url bgColor:(UIColor*)color control:(MPMovieControlStyle)control scaling:(MPMovieScalingMode)scaling cancelOnTouch:(bool)cot;

- (void)actuallyStartTheMovie:(NSURL*)url;
- (void)moviePlayBackDidFinish:(NSNotification*)notification;
- (void)finish;
@end

@interface CancelMovieView : UIView	{}
@end


static bool				_IsPlaying	= false;
static MPVideoContext*	_CurContext	= nil;

@implementation MPVideoContext
- (id)initAndPlay:(NSURL*)url bgColor:(UIColor*)color control:(MPMovieControlStyle)control scaling:(MPMovieScalingMode)scaling cancelOnTouch:(bool)cot
{
	_IsPlaying	= true;

	UnityPause(1);

	moviePlayer		= nil;
	movieController	= nil;
	overlayView		= nil;

	controlMode		= control;
	scalingMode		= scaling;
	bgColor			= color;
	cancelOnTouch	= cot;

	[self performSelector:@selector(actuallyStartTheMovie:) withObject:url afterDelay:0];
	return self;
}
- (void)dealloc
{
	[self finish];
}


- (void)actuallyStartTheMovie:(NSURL*)url
{
	@autoreleasepool
	{
		movieController = [[UnityVideoViewController alloc] initWithContentURL:url];
		if (movieController == nil)
			return;

		moviePlayer = [movieController moviePlayer];
		if (moviePlayer == nil)
			return;

		UIView* bgView = [moviePlayer backgroundView];
		bgView.backgroundColor = bgColor;

		[moviePlayer setControlStyle:controlMode];
		[moviePlayer setScalingMode:scalingMode];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:moviePlayer];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerDidExitFullscreenNotification object:moviePlayer];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChanged:) name:AVAudioSessionRouteChangeNotification object:nil];

		// TODO: wrong controller
		[UnityGetGLViewController() presentMoviePlayerViewControllerAnimated:movieController];

		if (cancelOnTouch)
		{
			// Add our overlay view to the movie player's subviews so touches could be intercepted
			overlayView = [[CancelMovieView alloc] initWithFrame:UnityGetMainWindow().frame];
			overlayView.backgroundColor = [UIColor clearColor];
			[UnityGetMainWindow() addSubview:overlayView];
		}
	}
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification
{
	[self finish];
}
- (void)audioRouteChanged:(NSNotification*)notification
{
	// not really cool:
	// it might happen that due to audio route changing ios can pause playback
	// alas at this point playbackRate might be not yet changed, so we just resume always
	if(moviePlayer)
		[moviePlayer play];
}

- (void)finish
{
	if(moviePlayer)
	{
		// remove notifications right away to avoid recursively calling finish from callback
		[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:moviePlayer];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerDidExitFullscreenNotification object:moviePlayer];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
	}

	if(overlayView)
		[overlayView removeFromSuperview];
	overlayView = nil;

	// TODO: wrong controller
	if(movieController)
		[UnityGetGLViewController() dismissMoviePlayerViewControllerAnimated];
	movieController = nil;

	if(moviePlayer)
	{
		[moviePlayer pause];
		[moviePlayer stop];
	}
	moviePlayer = nil;

	_IsPlaying	= false;
	_CurContext	= nil;
}
@end

@implementation CancelMovieView
- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	[self removeFromSuperview];

	if(_CurContext)
		[_CurContext finish];
}
@end


@implementation UnityVideoViewController
- (id)initWithContentURL:(NSURL*)contentURL
{
	if( (self = [super initWithContentURL:contentURL]) )
	{
		Class dstClass = [self class];
		Class srcClass = [GetAppController().rootViewController class];
		ObjCCopyInstanceMethod(dstClass, srcClass, @selector(shouldAutorotate));
		ObjCCopyInstanceMethod(dstClass, srcClass, @selector(supportedInterfaceOrientations));
		ObjCCopyInstanceMethod(dstClass, srcClass, @selector(prefersStatusBarHidden));
		ObjCCopyInstanceMethod(dstClass, srcClass, @selector(preferredStatusBarStyle));
		AddViewControllerDefaultRotationHandling(dstClass);
	}
	return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent*)event
{
	for (UITouch* touch in touches)
	{
		for(UIGestureRecognizer* gesture in touch.gestureRecognizers)
		{
			if(gesture.enabled && [gesture isMemberOfClass:[UIPinchGestureRecognizer class]])
				gesture.enabled = NO;
		}
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	UnityPause(0);
}
@end

extern "C" void UnityPlayMPMovie(const char* path, const float* color, unsigned control, unsigned scaling)
{
	const bool cancelOnTouch[] = { false, false, true, false };

	const MPMovieControlStyle controlMode[] =
	{
		MPMovieControlStyleFullscreen,
		MPMovieControlStyleEmbedded,
		MPMovieControlStyleNone,
		MPMovieControlStyleNone,
	};
	const MPMovieScalingMode scalingMode[] =
	{
		MPMovieScalingModeNone,
		MPMovieScalingModeAspectFit,
		MPMovieScalingModeAspectFill,
		MPMovieScalingModeFill,
	};

	const bool isURL = ::strstr(path, "://") != 0;

	NSURL* url = nil;
	if(isURL)
	{
		url = [NSURL URLWithString:[NSString stringWithUTF8String:path]];
	}
	else
	{
		NSString* relPath	= path[0] == '/' ? [NSString stringWithUTF8String:path] : [NSString stringWithFormat:@"Data/Raw/%s", path];
		NSString* fullPath	= [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:relPath];
		url = [NSURL fileURLWithPath:fullPath];
	}

	if(_CurContext)
		[_CurContext finish];

	_CurContext = [[MPVideoContext alloc] initAndPlay:url
		bgColor:[UIColor colorWithRed:color[0] green:color[1] blue:color[2] alpha:color[3]]
		control:controlMode[control] scaling:scalingMode[scaling] cancelOnTouch:cancelOnTouch[control]
	];
}

extern "C" void UnityStopMPMovieIfPlaying()
{
	if(_CurContext)
		[_CurContext finish];
}
