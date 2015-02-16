//
//  DebugUtils.h
//
//  Created by Ricardo Sánchez-Sáez on 11/03/13.
//
//
// Adapted from: http://iphoneprogrammingfordummies.blogspot.ie/2010/09/nslog-tricks-log-only-in-debug-mode-add.html
//

#ifndef _DebugUtils_h
#define _DebugUtils_h

// Lean and clean NSLog
#ifdef DEBUG
#define NSLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#endif

// Print only in Debug mode
#ifdef DEBUG
#define DBLog(fmt, ...) NSLog(@"%@", [NSString stringWithFormat:(fmt), ##__VA_ARGS__]);
#else
#define DBLog(...)
#endif

// DBLog but only print out if assert is true
#ifdef DEBUG
#define DBALog( assert , fmt , ... ) if ( assert ) { DBLog(fmt, ##__VA_ARGS__); }
#else
#define DBALog(...)
#endif

// Print function name only in Debug
#ifdef DEBUG
#define DLog(fmt, ...) NSLog((@"%p %s " fmt), self, __PRETTY_FUNCTION__, ##__VA_ARGS__);
#else
#define DLog(...)
#endif

// Print function name only in Debug if DDLOG_DEBUG_SYMBOL defined to a non-zero value
#ifdef DEBUG
#define DDLog(DDLOG_DEBUG_SYMBOL, fmt, ...) \
    if (DDLOG_DEBUG_SYMBOL) \
        { NSLog((@"%p %s " fmt), self, __PRETTY_FUNCTION__, ##__VA_ARGS__); }
#else
#define DDLog(...)
#endif

// Print function name only in Debug if DDLOG_DEBUG_SYMBOL defined to a non-zero value
#ifdef DEBUG
#define DCLog(DDLOG_DEBUG_SYMBOL, fmt, ...) \
    if (DDLOG_DEBUG_SYMBOL) \
        { NSLog((@"%s " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__); }
#else
#define DCLog(...)
#endif


// DLog but only print out if assert is true
#ifdef DEBUG
#define DALog( assert , fmt , ... ) if( assert ) { DLog(fmt,##__VA_ARGS__); }
#else
#define DALog(...)
#endif

// Print function name in Debug and release
#define ALog(fmt, ...) NSLog((@"%s " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__);

#endif