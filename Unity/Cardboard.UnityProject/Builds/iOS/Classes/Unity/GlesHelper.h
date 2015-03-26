#pragma once


#ifdef __OBJC__
	@class CAEAGLLayer;
	@class EAGLContext;
#else
	typedef struct objc_object CAEAGLLayer;
	typedef struct objc_object EAGLContext;
#endif


#define ENABLE_UNITY_GLES_DEBUG 1
#define MSAA_DEFAULT_SAMPLE_COUNT 0

// in case of rendering to non-native resolution the texture filter we will use for upscale blit
#define GLES_UPSCALE_FILTER GL_LINEAR
//#define GLES_UPSCALE_FILTER GL_NEAREST

// if gles support MSAA. We will need to recreate unity view if AA samples count was changed
extern	bool	_supportsMSAA;


#ifdef __cplusplus
extern "C" {
#endif

void CheckGLESError(const char* file, int line);

#ifdef __cplusplus
} // extern "C"
#endif


#if ENABLE_UNITY_GLES_DEBUG
	#define GLESAssert()	do { CheckGLESError (__FILE__, __LINE__); } while(0)
	#define GLES_CHK(expr)	do { {expr;} GLESAssert(); } while(0)
#else
	#define GLESAssert()	do { } while(0)
	#define GLES_CHK(expr)	do { expr; } while(0)
#endif
