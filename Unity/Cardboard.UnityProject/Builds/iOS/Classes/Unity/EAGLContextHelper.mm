
#include "EAGLContextHelper.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

extern "C" bool AllocateRenderBufferStorageFromEAGLLayer(void* eaglContext, void* eaglLayer)
{
	return [(__bridge EAGLContext*)eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(__bridge CAEAGLLayer*)eaglLayer];
}
extern "C" void DeallocateRenderBufferStorageFromEAGLLayer(void* eaglContext)
{
	[(__bridge EAGLContext*)eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:nil];
}

extern "C" EAGLContext* UnityCreateContextEAGL(EAGLContext* parent, int api)
{
	const int		targetApi	= parent ? parent.API : api;
	EAGLSharegroup*	group		= parent ? parent.sharegroup : nil;

	return [[EAGLContext alloc] initWithAPI:(EAGLRenderingAPI)targetApi sharegroup:group];
}

extern "C" void UnityMakeCurrentContextEAGL(EAGLContext* context)
{
	[EAGLContext setCurrentContext:context];
}


EAGLContextSetCurrentAutoRestore::EAGLContextSetCurrentAutoRestore(EAGLContext* cur_)
  : old([EAGLContext currentContext]),
	cur(cur_)
{
	if (old != cur)
		[EAGLContext setCurrentContext:cur];
}

EAGLContextSetCurrentAutoRestore::~EAGLContextSetCurrentAutoRestore()
{
	if (old != cur)
		[EAGLContext setCurrentContext:old];
}
