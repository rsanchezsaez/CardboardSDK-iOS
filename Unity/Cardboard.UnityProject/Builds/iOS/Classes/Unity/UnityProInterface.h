#pragma once

typedef void (*UnityPlayMPMovieFunc)(const char* path, const float* color, unsigned control, unsigned scaling);
typedef void (*UnityStopMPMovieIfPlayingFunc)(void);

typedef struct
UnityProInterface
{
	UnityPlayMPMovieFunc			unityPlayMPMovie;
	UnityStopMPMovieIfPlayingFunc	unityStopMPMovieIfPlaying;
}
UnityProInterface;

extern "C" void	UnityRegisterProInterface(const UnityProInterface* unityInterface);
