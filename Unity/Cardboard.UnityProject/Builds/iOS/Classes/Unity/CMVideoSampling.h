#ifndef _TRAMPOLINE_UNITY_CMVIDEOSAMPLING_H_
#define _TRAMPOLINE_UNITY_CMVIDEOSAMPLING_H_

// small helper for getting texture from CMSampleBuffer
// uses CVOpenGLESTextureCache if available and falls back to simple copy otherwise

typedef struct
CMVideoSampling
{
    // CVOpenGLESTextureCache support
    void*   cvTextureCache;
    void*   cvTextureCacheTexture;

    // double-buffered pixel read if no CVOpenGLESTextureCache support
    int     glTex[2];
}
CMVideoSampling;

void CMVideoSampling_Initialize(CMVideoSampling* sampling);
void CMVideoSampling_Uninitialize(CMVideoSampling* sampling);

// buffer is CMSampleBufferRef
// returns gltex id
int  CMVideoSampling_SampleBuffer(CMVideoSampling* sampling, void* buffer, int w, int h);
int  CMVideoSampling_LastSampledTexture(CMVideoSampling* sampling);


#endif // _TRAMPOLINE_UNITY_CMVIDEOSAMPLING_H_
