#pragma once

// depending on selected rendering api it will be or GLES or Metal texture cache

// returns CVOpenGLESTextureCacheRef/CVMetalTextureCacheRef
void*		CreateCVTextureCache();
// cache = CVOpenGLESTextureCacheRef/CVMetalTextureCacheRef
void		FlushCVTextureCache(void* cache);

// returns CVOpenGLESTextureRef/CVMetalTextureRef
// cache = CVOpenGLESTextureCacheRef/CVMetalTextureCacheRef
// image = CVImageBufferRef/CVPixelBufferRef
void*		CreateTextureFromCVTextureCache(void* cache, void* image, unsigned w, unsigned h);

// texture = CVOpenGLESTextureRef
unsigned		GetGLTextureFromCVTextureCache(void* texture);
// texture = CVMetalTextureRef
MTLTextureRef	GetMetalTextureFromCVTextureCache(void* texture);

// texture = CVOpenGLESTextureRef/CVMetalTextureRef
uintptr_t		GetTextureFromCVTextureCache(void* texture);


// returns CVPixelBufferRef
// enforces kCVPixelFormatType_32BGRA
void*		CreatePixelBufferForCVTextureCache(unsigned w, unsigned h);
// returns CVOpenGLESTextureRef
// cache = CVOpenGLESTextureCacheRef
// pb = CVPixelBufferRef (out)
// enforces rgba texture with bgra backing
void*		CreateReadableRTFromCVTextureCache(void* cache, unsigned w, unsigned h, void** pb);
