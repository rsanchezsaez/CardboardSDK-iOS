
#include "CVTextureCache.h"

#ifdef __IPHONE_5_0

#include "GlesHelper.h"
#include "DisplayManager.h"

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include <CoreVideo/CVOpenGLESTextureCache.h>

const CFStringRef kCVPixelBufferOpenGLESCompatibilityKey = CFSTR("OpenGLESCompatibility");



bool CanUseCVTextureCache()
{
	return _ios50orNewer;
}

void* CreateCVTextureCache()
{
	if(!CanUseCVTextureCache())
		return 0;

	EAGLContext* context = GetMainRenderingSurface()->context;

	CVOpenGLESTextureCacheRef cache = 0;
	CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, 0, context, 0, &cache);
	if (err)
	{
		::printf_console("Error at CVOpenGLESTextureCacheCreate: %d", err);
		cache = 0;
	}

	return cache;
}

void FlushCVTextureCache(void* cache_)
{
	if(!CanUseCVTextureCache())
		return;

	CVOpenGLESTextureCacheRef	cache = (CVOpenGLESTextureCacheRef)cache_;
	if(cache == 0)
		return;

	CVOpenGLESTextureCacheFlush(cache, 0);
}

void* CreateTextureFromCVTextureCache(void* cache_, void* image_, unsigned w, unsigned h, int format, int internalFormat, int type)
{
	if(!CanUseCVTextureCache())
		return 0;

	CVOpenGLESTextureCacheRef	cache = (CVOpenGLESTextureCacheRef)cache_;
	CVImageBufferRef			image = (CVImageBufferRef)image_;
	if(!cache || !image)
		return 0;

	CVOpenGLESTextureRef texture = 0;
	CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage( kCFAllocatorDefault, cache, image, 0,
																 GL_TEXTURE_2D, (GLint)internalFormat,
																 w, h, (GLenum)format, (GLenum)type,
																 0, &texture
																);
	if (err)
	{
		::printf_console("Error at CVOpenGLESTextureCacheCreateTextureFromImage: %d", err);
		texture = 0;
	}

	return texture;
}

unsigned GetGLTextureFromCVTextureCache(void* texture_)
{
	if(!CanUseCVTextureCache())
		return 0;

	CVOpenGLESTextureRef texture = (CVOpenGLESTextureRef)texture_;
	if(texture == 0)
		return 0;

	return CVOpenGLESTextureGetName(texture);
}

void* CreatePixelBufferForCVTextureCache(unsigned w, unsigned h)
{
	CVPixelBufferRef pb = 0;

#if __has_feature(objc_dictionary_literals)
	NSDictionary* options = @{	(NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
								(NSString*)kCVPixelBufferWidthKey : @(w),
								(NSString*)kCVPixelBufferHeightKey : @(h),
								(NSString*)kCVPixelBufferOpenGLESCompatibilityKey : @(YES),
								(NSString*)kCVPixelBufferIOSurfacePropertiesKey : @{}
							};
#else
	NSArray* keys = [NSArray arrayWithObjects:
		(NSString*)kCVPixelBufferPixelFormatTypeKey,
		(NSString*)kCVPixelBufferWidthKey,
		(NSString*)kCVPixelBufferHeightKey,
		(NSString*)kCVPixelBufferOpenGLESCompatibilityKey,
		(NSString*)kCVPixelBufferIOSurfacePropertiesKey,
		nil
	];
	NSArray* values = [NSArray arrayWithObjects:
		[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],
		[NSNumber numberWithInt:w],
		[NSNumber numberWithInt:h],
		[NSNumber numberWithInt:YES],
		[NSDictionary dictionary],
		nil
	];
	NSDictionary* options = [NSDictionary dictionaryWithObjects:values forKeys:keys];
#endif

	CVPixelBufferCreate(kCFAllocatorDefault, w, h, kCVPixelFormatType_32BGRA, (CFDictionaryRef)options, &pb);
	return pb;
}

void* CreateReadableRTFromCVTextureCache(void* cache, unsigned w, unsigned h, void** pb)
{
	*pb = CreatePixelBufferForCVTextureCache(w, h);
	return CreateTextureFromCVTextureCache(cache, *pb, w, h, GL_BGRA_EXT, GL_RGBA, GL_UNSIGNED_BYTE);
}

#else

bool		CanUseCVTextureCache()																{ return false; }
void*		CreateCVTextureCache()																{ return 0; }
void		FlushCVTextureCache(void*)															{}
void*		CreateTextureFromCVTextureCache(void*, void*, unsigned, unsigned, int, int, int)	{ return 0; }
unsigned	GetGLTextureFromCVTextureCache(void*)												{ return 0; }
void*		CreatePixelBufferForTextureCache(unsigned, unsigned)								{ return 0; }
void* 		CreateReadableRTFromCVTextureCache(void*, unsigned, unsigned, void**)				{ return 0;}

#endif // __IPHONE_5_0
