#ifndef _TRAMPOLINE_UNITY_CVTEXTURECACHE_H_
#define _TRAMPOLINE_UNITY_CVTEXTURECACHE_H_

bool		CanUseCVTextureCache();
// returns CVOpenGLESTextureCacheRef
void*		CreateCVTextureCache();
// cache = CVOpenGLESTextureCacheRef
void		FlushCVTextureCache(void* cache);

// returns CVOpenGLESTextureRef
// cache = CVOpenGLESTextureCacheRef
// image = CVImageBufferRef/CVPixelBufferRef
void*		CreateTextureFromCVTextureCache(void* cache, void* image, unsigned w, unsigned h, int iosFormat, int glesFormat, int type);
// texture = CVOpenGLESTextureRef
unsigned	GetGLTextureFromCVTextureCache(void* texture);

// returns CVPixelBufferRef
// enforces kCVPixelFormatType_32BGRA
void*		CreatePixelBufferForCVTextureCache(unsigned w, unsigned h);
// returns CVOpenGLESTextureRef
// cache = CVOpenGLESTextureCacheRef
// pb = CVPixelBufferRef (out)
// enforces rgba texture with bgra backing
void*		CreateReadableRTFromCVTextureCache(void* cache, unsigned w, unsigned h, void** pb);

#endif // _TRAMPOLINE_UNITY_CVTEXTURECACHE_H_
