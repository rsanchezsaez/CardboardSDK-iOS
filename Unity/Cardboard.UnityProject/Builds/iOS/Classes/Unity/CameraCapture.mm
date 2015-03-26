#include "CameraCapture.h"
#include "AVCapture.h"
#include "CMVideoSampling.h"

#import <CoreVideo/CoreVideo.h>

#include <cmath>

@implementation CameraCaptureController
{
	AVCaptureDevice*			_captureDevice;
	AVCaptureSession*			_captureSession;
	AVCaptureDeviceInput*		_captureInput;
	AVCaptureVideoDataOutput*	_captureOutput;


	@public CMVideoSampling		_cmVideoSampling;
	@public void*				_userData;
	@public size_t				_width, _height;
}

- (bool)initCapture:(AVCaptureDevice*)device width:(int)w height:(int)h fps:(float)fps
{
	if(UnityGetAVCapturePermission(avVideoCapture) == avCapturePermissionDenied)
		return false;

	self.captureDevice= device;

	self.captureInput	= [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
	self.captureOutput	= [[AVCaptureVideoDataOutput alloc] init];

	if(self.captureOutput == nil || self.captureInput == nil)
		return false;

	self.captureOutput.alwaysDiscardsLateVideoFrames = YES;
	if([device lockForConfiguration:nil])
	{
		AVFrameRateRange* range = [self pickFrameRateRange:fps];
		if(range)
		{
			if([device respondsToSelector:@selector(activeVideoMinFrameDuration)])
				device.activeVideoMinFrameDuration = range.minFrameDuration;
			if([device respondsToSelector:@selector(activeVideoMaxFrameDuration)])
				device.activeVideoMaxFrameDuration = range.maxFrameDuration;
		}
		else
		{
		#pragma clang diagnostic push
		#pragma clang diagnostic ignored "-Wdeprecated-declarations"

			self.captureOutput.minFrameDuration = CMTimeMake(1, fps);

		#pragma clang diagnostic pop
		}
		[device unlockForConfiguration];
	}

	// queue on main thread to simplify gles life
	[self.captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

	NSDictionary* options = @{ (NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
	[self.captureOutput setVideoSettings:options];

	self.captureSession = [[AVCaptureSession alloc] init];
	[self.captureSession addInput:self.captureInput];
	[self.captureSession addOutput:self.captureOutput];
	self.captureSession.sessionPreset = [self pickPresetFromWidth:w height:h];

	CMVideoSampling_Initialize(&self->_cmVideoSampling);

	_width = _height = 0;

	return true;
}

- (void)captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection
{
	intptr_t tex = (intptr_t)CMVideoSampling_SampleBuffer(&self->_cmVideoSampling, sampleBuffer, &_width, &_height);
	UnityDidCaptureVideoFrame(tex, self->_userData);
}

- (void)start	{ [self.captureSession startRunning]; }
- (void)pause	{ [self.captureSession stopRunning]; }

- (void)stop
{
	[self.captureSession stopRunning];
	[self.captureSession removeInput: self.captureInput];
	[self.captureSession removeOutput: self.captureOutput];

	self.captureDevice = nil;
	self.captureInput = nil;
	self.captureOutput = nil;
	self.captureSession = nil;

	CMVideoSampling_Uninitialize(&self->_cmVideoSampling);
}

- (NSString*)pickPresetFromWidth:(int)w height:(int)h
{
	static NSString* preset[] =
	{
		AVCaptureSessionPreset352x288,
		AVCaptureSessionPreset640x480,
		AVCaptureSessionPreset1280x720,
		AVCaptureSessionPreset1920x1080,
	};
	static int presetW[] = { 352, 640, 1280, 1920 };

	#define countof(arr) sizeof(arr)/sizeof(arr[0])

	static_assert(countof(presetW) == countof(preset), "preset and preset width arrrays have different elem count");

	int ret = -1, curW = -10000;
	for(int i = 0, n = countof(presetW) ; i < n ; ++i)
	{
		if(::abs(w - presetW[i]) < ::abs(w - curW) && [self.captureSession canSetSessionPreset:preset[i]])
		{
			ret = i;
			curW = presetW[i];
		}
	}

	NSAssert(ret != -1, @"Cannot pick capture preset");
	return ret != -1 ? preset[ret] : AVCaptureSessionPresetHigh;

	#undef countof
}
- (AVFrameRateRange*)pickFrameRateRange:(float)fps
{
	AVFrameRateRange* ret = nil;

	if([self.captureDevice respondsToSelector:@selector(activeFormat)])
	{
		float minDiff = INFINITY;
		for(AVFrameRateRange* rate in self.captureDevice.activeFormat.videoSupportedFrameRateRanges)
		{
			float bestMatch = rate.minFrameRate;
			if (fps > rate.maxFrameRate)		bestMatch = rate.maxFrameRate;
			else if (fps > rate.minFrameRate)	bestMatch = fps;

			float diff = ::fabs(fps - bestMatch);
			if(diff < minDiff)
			{
				minDiff = diff;
				ret = rate;
			}
		}

		NSAssert(ret != nil, @"Cannot pick frame rate range");
		if(ret == nil)
			ret = self.captureDevice.activeFormat.videoSupportedFrameRateRanges[0];
	}
	return ret;
}

@synthesize captureDevice	= _captureDevice;
@synthesize captureSession	= _captureSession;
@synthesize captureOutput	= _captureOutput;
@synthesize captureInput	= _captureInput;

@end

extern "C" void	UnityEnumVideoCaptureDevices(void* udata, void(*callback)(void* udata, const char* name, int frontFacing))
{
	for (AVCaptureDevice* device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
	{
		int frontFacing = device.position == AVCaptureDevicePositionFront ? 1 : 0;
		callback(udata, [device.localizedName UTF8String], frontFacing);
	}
}

extern "C" void* UnityInitCameraCapture(int deviceIndex, int w, int h, int fps, void* udata)
{
	AVCaptureDevice* device = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][deviceIndex];

	CameraCaptureController* controller = [CameraCaptureController alloc];
	if([controller initCapture:device width:w height:h fps:(float)fps])
	{
		controller->_userData = udata;
		return (__bridge_retained void*)controller;
	}

	controller = nil;
	return 0;
}

extern "C" void UnityStartCameraCapture(void* capture)
{
	[(__bridge CameraCaptureController*)capture start];
}
extern "C" void UnityPauseCameraCapture(void* capture)
{
	[(__bridge CameraCaptureController*)capture pause];
}
extern "C" void UnityStopCameraCapture(void* capture)
{
	CameraCaptureController* controller = (__bridge_transfer CameraCaptureController*)capture;
	[controller stop];
	controller = nil;
}

extern "C" void UnityCameraCaptureExtents(void* capture, int* w, int* h)
{
	CameraCaptureController* controller = (__bridge CameraCaptureController*)capture;
	*w = controller->_width;
	*h = controller->_height;
}

extern "C" void UnityCameraCaptureReadToMemory(void* capture, void* dst_, int w, int h)
{
	CameraCaptureController* controller = (__bridge CameraCaptureController*)capture;
	assert(w == controller->_width && h == controller->_height);

	CVPixelBufferRef pbuf = (CVPixelBufferRef)controller->_cmVideoSampling.cvImageBuffer;

	const size_t srcRowSize	= CVPixelBufferGetBytesPerRow(pbuf);
	const size_t dstRowSize	= w*sizeof(uint32_t);
	const size_t bufSize	= srcRowSize * h;

	// while not the best way memory-wise, we want to minimize stalling
	uint8_t* tmpMem = (uint8_t*)::malloc(bufSize);
	CVPixelBufferLockBaseAddress(pbuf, kCVPixelBufferLock_ReadOnly);
	{
		::memcpy(tmpMem, CVPixelBufferGetBaseAddress(pbuf), bufSize);
	}
	CVPixelBufferUnlockBaseAddress(pbuf, kCVPixelBufferLock_ReadOnly);

	uint8_t* dst = (uint8_t*)dst_;
	uint8_t* src = tmpMem + (h - 1)*srcRowSize;
	for( int i = 0, n = h ; i < n ; ++i)
	{
		::memcpy(dst, src, dstRowSize);
		dst += dstRowSize;
		src -= srcRowSize;
	}
}

extern "C" int UnityCameraCaptureVideoRotationDeg(void* capture)
{
	CameraCaptureController* controller = (__bridge CameraCaptureController*)capture;

	// all cams are landscape.
	switch(UnityCurrentOrientation())
	{
		case portrait:				return 90;
		case portraitUpsideDown:	return 270;
		case landscapeLeft:			return controller.captureDevice.position == AVCaptureDevicePositionFront ? 180 : 0;
		case landscapeRight:		return controller.captureDevice.position == AVCaptureDevicePositionFront ? 0 : 180;

		default:					assert(false && "bad orientation returned from UnityCurrentOrientation()");	break;
	}
	return 0;
}

extern "C" int UnityCameraCaptureVerticallyMirrored(void* capture)
{
	CameraCaptureController* controller = (__bridge CameraCaptureController*)capture;
	return CVOpenGLESTextureIsFlipped((CVOpenGLESTextureRef)controller->_cmVideoSampling.cvTextureCacheTexture);
}
