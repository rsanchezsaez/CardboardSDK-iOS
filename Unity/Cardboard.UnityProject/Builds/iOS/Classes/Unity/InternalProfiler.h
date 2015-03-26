#pragma once

#define ENABLE_INTERNAL_PROFILER 0
#define ENABLE_BLOCK_ON_GPU_PROFILER 0
#define INCLUDE_OPENGLES_IN_RENDER_TIME 0


#if ENABLE_INTERNAL_PROFILER

void Profiler_InitProfiler();
void Profiler_UninitProfiler();
void Profiler_FrameStart();
void Profiler_FrameEnd();
void Profiler_FrameUpdate(const UnityFrameStats*);

// TODO: enum? do we need more strange counters
void Profiler_StartMSAAResolve();
void Profiler_EndMSAAResolve();

#else

inline void Profiler_InitProfiler()								{}
inline void Profiler_UninitProfiler()							{}
inline void Profiler_FrameStart()								{}
inline void Profiler_FrameEnd()									{}
inline void Profiler_FrameUpdate(const struct UnityFrameStats*) {}

inline void Profiler_StartMSAAResolve()							{}
inline void Profiler_EndMSAAResolve()							{}


#endif // ENABLE_INTERNAL_PROFILER
