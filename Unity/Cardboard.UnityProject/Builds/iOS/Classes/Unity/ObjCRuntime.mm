#include "ObjCRuntime.h"

#include <objc/objc.h>
#include <objc/runtime.h>

void ObjCSetKnownInstanceMethod(Class dstClass, SEL selector, IMP impl)
{
	Method m = class_getInstanceMethod(dstClass, selector);
	assert(m);

	if(!class_addMethod(dstClass, selector, impl, method_getTypeEncoding(m)))
		class_replaceMethod(dstClass, selector, impl, method_getTypeEncoding(m));
}

void ObjCCopyInstanceMethod(Class dstClass, Class srcClass, SEL selector)
{
	Method srcMethod = class_getInstanceMethod(srcClass, selector);

	// first we try to add method, and if that fails (already exists) we replace implemention
	if(!class_addMethod(dstClass, selector, method_getImplementation(srcMethod), method_getTypeEncoding(srcMethod)))
		class_replaceMethod(dstClass, selector, method_getImplementation(srcMethod), method_getTypeEncoding(srcMethod));
}
