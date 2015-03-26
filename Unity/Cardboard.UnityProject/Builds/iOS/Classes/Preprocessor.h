#pragma once

#include <Availability.h>

//------------------------------------------------------------------------------
//
// ensuring proper compiler/xcode/whatever selection
//

#ifndef __clang__
#error please use clang compiler.
#endif

// NOT the best way but apple do not care about adding extensions properly
#if __clang_major__ < 5
#error please use xcode 5.0 or newer
#endif

#if !defined(__IPHONE_7_0) || __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_7_0
#error please use ios sdk 7.0 or newer
#endif

#if !defined(__IPHONE_6_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
#error please target ios 6.0 or newer
#endif


//------------------------------------------------------------------------------
//
// defines for sdk/target version
//

#ifdef __IPHONE_7_0
	#define UNITY_PRE_IOS7_TARGET (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0)
#else
	#define UNITY_PRE_IOS7_TARGET 1
#endif

#ifdef __IPHONE_8_0
	#define UNITY_IOS8_ORNEWER_SDK (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0)
#else
	#define UNITY_IOS8_ORNEWER_SDK 0
#endif

#if defined(__IPHONE_8_0) && !TARGET_IPHONE_SIMULATOR
	#define UNITY_CAN_USE_METAL		1
#else
	#define UNITY_CAN_USE_METAL		0
#endif

#define USE_IL2CPP_PCH 0
