#include "AVCapture.h"

#include <AVFoundation/AVFoundation.h>


static NSString* MediaTypeFromEnum(int captureType)
{
	if(captureType == avAudioCapture)		return AVMediaTypeAudio;
	else if(captureType == avVideoCapture)	return AVMediaTypeVideo;
	return nil;
}

extern "C" int UnityGetAVCapturePermission(int captureType)
{
	NSString* mediaType = MediaTypeFromEnum(captureType);
	if(mediaType == nil)
		return avCapturePermissionDenied;

	NSInteger status = AVAuthorizationStatusAuthorized;
	if([AVCaptureDevice respondsToSelector:@selector(authorizationStatusForMediaType:)])
		status = [AVCaptureDevice authorizationStatusForMediaType:mediaType];

	if(status == AVAuthorizationStatusNotDetermined)	return avCapturePermissionUnknown;
	else if(status == AVAuthorizationStatusAuthorized)	return avCapturePermissionGranted;

	return avCapturePermissionDenied;
}

extern "C" void UnityRequestAVCapturePermission(int captureType)
{
	if([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType:completionHandler:)])
	{
		NSString* mediaType = MediaTypeFromEnum(captureType);
		if(mediaType == nil)
			return;

		[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted)
		{
			UnityReportAVCapturePermission();
		}];
	}
}
