#pragma once

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
@property (nonatomic, retain) id delegate;

+ (BOOL)CanPlayToTexture:(NSURL*)url;

- (BOOL)loadVideo:(NSURL*)url;
- (BOOL)readyToPlay;
- (void)unloadPlayer;

- (BOOL)playToView:(VideoPlayerView*)view;
- (BOOL)playToTexture;
- (BOOL)isPlaying;

- (intptr_t)curFrameTexture;

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
