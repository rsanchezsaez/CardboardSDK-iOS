#pragma once

enum LocationServiceStatus
{
	kLocationServiceStopped,
	kLocationServiceInitializing,
	kLocationServiceRunning,
	kLocationServiceFailed
};

class LocationService
{
public:
	static void SetDesiredAccuracy (float val);
	static float GetDesiredAccuracy ();
	static void SetDistanceFilter (float val);
	static float GetDistanceFilter ();
	static bool IsServiceEnabledByUser ();
	static void StartUpdatingLocation ();
	static void StopUpdatingLocation ();
	static void SetHeadingUpdatesEnabled (bool enabled);
	static bool IsHeadingUpdatesEnabled();
	static LocationServiceStatus GetLocationStatus ();
	static LocationServiceStatus GetHeadingStatus ();
	static bool IsHeadingAvailable ();
};
