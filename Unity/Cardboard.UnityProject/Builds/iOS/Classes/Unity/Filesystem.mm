#include <sys/xattr.h>

extern "C" const char* UnityApplicationDir()
{
	static const char* dir = NULL;
	if (dir == NULL)
		dir = AllocCString([NSBundle mainBundle].bundlePath);
	return dir;
}

#define RETURN_SPECIAL_DIR(dir)				\
	do {									\
		static const char* var = NULL;		\
		if (var == NULL)					\
			var = AllocCString(NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES)[0]);	\
		return var;							\
	} while (0)

extern "C" const char* UnityDocumentsDir() { RETURN_SPECIAL_DIR(NSDocumentDirectory); }
extern "C" const char* UnityLibraryDir() { RETURN_SPECIAL_DIR(NSLibraryDirectory); }
extern "C" const char* UnityCachesDir() { RETURN_SPECIAL_DIR(NSCachesDirectory); }

#undef RETURN_SPECIAL_DIR

extern "C" int UnityUpdateNoBackupFlag(const char* path, int setFlag)
{
	int result;
	if(setFlag)
	{
		u_int8_t b = 1;
		result = ::setxattr(path, "com.apple.MobileBackup", &b, 1, 0, 0);
	}
	else
	{
		result = ::removexattr(path, "com.apple.MobileBackup", 0);
	}
	return result == 0 ? 1 : 0;
}

extern "C" const char* const* UnityFontDirs()
{
	static const char* const dirs[] = {
		"/System/Library/Fonts/Cache",		// before iOS 8.2
		"/System/Library/Fonts/AppFonts",	// iOS 8.2
		"/System/Library/Fonts/Core",		// iOS 8.2
		"/System/Library/Fonts/Extra",		// iOS 8.2
		NULL
	};
	return dirs;
}
