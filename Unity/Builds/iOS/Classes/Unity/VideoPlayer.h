#ifndef _TRAMPOLINE_UNITY_VIDEOPLAYER_H_
#define _TRAMPOLINE_UNITY_VIDEOPLAYER_H_

#import <CoreMedia/CMTime.h>

@class AVPlayer;


@interface VideoPlayerView : UIView {}
@property(nonatomic, retain) AVPlayer* player;
@end

@protocol VideoPlayerDelegate<NSObject>
- (void)onPlayerReady;
- (void)onPlayerDidFinishPlayingVideo;
@end

@interface VideoPlayer : NSObject
{
    id<VideoPlayerDelegate> delegate;
}
@property (nonatomic, assign) id delegate;

+ (BOOL)CanPlayToTexture:(NSURL*)url;

- (BOOL)loadVideo:(NSURL*)url;
- (BOOL)readyToPlay;
- (void)unloadPlayer;

- (BOOL)playToView:(VideoPlayerView*)view;
- (BOOL)playToTexture;
- (BOOL)isPlaying;

- (int)curFrameTexture;

- (void)pause;
- (void)resume;

- (void)rewind;
- (void)seekToTimestamp:(CMTime)time;
- (void)seekTo:(float)timeSeconds;

- (BOOL)setAudioVolume:(float)volume;

- (CMTime)duration;
- (float)durationSeconds;
- (CGSize)videoSize;
@end



#endif // _TRAMPOLINE_UNITY_VIDEOPLAYER_H_
