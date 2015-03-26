#pragma once

// to avoid dependency on objc runtime headers in header itself we will define stuff we need ourselves

typedef struct objc_selector* SEL;
#if !OBJC_OLD_DISPATCH_PROTOTYPES
	typedef void (*IMP)(void);
#else
	typedef id (*IMP)(id, SEL, ...);
#endif


//OBJC_EXPORT id objc_msgSendSuper(struct objc_super* super, SEL op, ...);
#ifdef __OBJC__
	extern "C" id objc_msgSendSuper(struct objc_super* super, SEL op, ...);
#else
	extern "C" struct objc_object* objc_msgSendSuper(struct objc_super* super, SEL op, ...);
#endif


typedef struct
{
    __unsafe_unretained id receiver;
    __unsafe_unretained Class super_class;
} UnityObjcSuper;

#define UNITY_OBJC_FORWARD_TO_SUPER(self_, super_, selector, selectorType, ...)	\
	do																			\
	{																			\
		UnityObjcSuper super = { .receiver = self_, .super_class = super_ };	\
		selectorType msgSendFunc = (selectorType)objc_msgSendSuper;				\
		msgSendFunc((struct objc_super*)&super, selector, __VA_ARGS__);			\
	}																			\
	while(0)																	\


void ObjCCopyInstanceMethod(Class dstClass, Class srcClass, SEL selector);
void ObjCSetKnownInstanceMethod(Class dstClass, SEL selector, IMP impl);
