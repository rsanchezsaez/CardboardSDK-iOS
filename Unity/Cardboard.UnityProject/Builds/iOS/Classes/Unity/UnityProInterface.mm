#include "UnityProInterface.h"
#include "UnityAppController.h"

extern "C" void				UnityPlayMPMovie(const char* path, const float* color, unsigned control, unsigned scaling);
extern "C" void				UnityStopMPMovieIfPlaying();


@interface UnityAppController(RegisterProInterface)
{
}
+(void)load;
@end
@implementation UnityAppController(RegisterProInterface)
+(void)load
{
	UnityProInterface unityInterface =
	{
		&UnityPlayMPMovie, &UnityStopMPMovieIfPlaying
	};
	UnityRegisterProInterface(&unityInterface);
}
@end
