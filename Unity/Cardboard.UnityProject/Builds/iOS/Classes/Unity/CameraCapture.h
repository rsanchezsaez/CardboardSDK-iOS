#pragma once

#import <AVFoundation/AVFoundation.h>

@interface CameraCaptureController : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

- (bool)initCapture:(AVCaptureDevice*)device width:(int)width height:(int)height fps:(float)fps;
- (void)captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection;

- (void)start;
- (void)pause;
- (void)stop;

@property (nonatomic, retain) AVCaptureDevice*			captureDevice;
@property (nonatomic, retain) AVCaptureSession*			captureSession;
@property (nonatomic, retain) AVCaptureDeviceInput*		captureInput;
@property (nonatomic, retain) AVCaptureVideoDataOutput*	captureOutput;

// override these two for custom preset/fps selection
// they will be called on inited capture
- (NSString*)pickPresetFromWidth:(int)w height:(int)h;
- (AVFrameRateRange*)pickFrameRateRange:(float)fps;

@end
