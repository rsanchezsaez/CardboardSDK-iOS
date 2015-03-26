#pragma once

#ifdef __OBJC__
	@class EAGLContext;
#else
	typedef struct objc_object EAGLContext;
#endif


extern "C" bool AllocateRenderBufferStorageFromEAGLLayer(void* eaglContext, void* eaglLayer);
extern "C" void DeallocateRenderBufferStorageFromEAGLLayer(void* eaglContext);

extern "C" EAGLContext*	UnityCreateContextEAGL(EAGLContext* parent, int api);
extern "C" void			UnityMakeCurrentContextEAGL(EAGLContext* context);

#if __OBJC__

	class
	EAGLContextSetCurrentAutoRestore
	{
	public:
		EAGLContext* old;
		EAGLContext* cur;

		EAGLContextSetCurrentAutoRestore(EAGLContext* cur);
		~EAGLContextSetCurrentAutoRestore();
	};

#endif // __OBJC__
