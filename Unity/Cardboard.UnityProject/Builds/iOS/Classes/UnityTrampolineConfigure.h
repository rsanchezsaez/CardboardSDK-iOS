#pragma once

//	Auto Generated File, do not edit!
//	It will be updated whenever we update unity version
//	When unity version is changed:
//		UNITY_VERSION value will be changed
//		UNITY_X_Y_Z for this new version will be added
//
//	If you want conditional on unity version you have several options:
//	1. apple like:
//		#if !defined(UNITY_4_5_0)
//	is equivalent to saying unity trampoline version is pre-4.5.0 (as 4.5.0 will define the macro)
//	2. explicit version specified:
//		#if UNITY_VERSION < 450
//	is equivalent to saying unity trampoline version is pre-4.5.0
//	3. most robust would be to check both presence and comparison with unity version
//	it is not needed now but who knows what we come up with ;-)
//		#if !defined(UNITY_4_5_0) || UNITY_VERSION < UNITY_4_5_0
//	is equivalent to saying unity trampoline version is pre-4.5.0

#define UNITY_VERSION 500

// known unity versions
#define UNITY_4_2_0 420
#define UNITY_4_2_1 421
#define UNITY_4_2_2 422
#define UNITY_4_3_0 430
#define UNITY_4_3_1 431
#define UNITY_4_3_2 432
#define UNITY_4_3_3 433
#define UNITY_4_3_4 434
#define UNITY_4_5_0 450
#define UNITY_4_5_1 451
#define UNITY_4_5_2 452
#define UNITY_4_5_3 453
#define UNITY_4_6_0 460
#define UNITY_5_0_0 500
