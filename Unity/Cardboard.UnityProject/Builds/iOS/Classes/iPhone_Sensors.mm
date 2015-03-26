#import "iPhone_Sensors.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <GameController/GameController.h>

#include "OrientationSupport.h"
#include "Unity/UnityInterface.h"

typedef void (^ControllerPausedHandler)(GCController *controller);
static NSArray* QueryControllerCollection();

static bool gCompensateSensors = true;
bool gEnableGyroscope = false;
static bool gJoysticksInited = false;
#define MAX_JOYSTICKS 4
static bool gPausedJoysticks[MAX_JOYSTICKS] = {false, false, false, false};
static id gGameControllerClass = nil;
static ControllerPausedHandler gControllerHandler = ^(GCController *controller)
{
	NSArray* list = QueryControllerCollection();
	if (list != nil)
	{
		NSUInteger idx = [list indexOfObject:controller];
		if (idx < MAX_JOYSTICKS)
		{
			gPausedJoysticks[idx] = !gPausedJoysticks[idx];
		}
	}
};

bool IsCompensatingSensors() { return gCompensateSensors; }
void SetCompensatingSensors(bool val) { gCompensateSensors = val;}

struct Vector3f
{
	float x, y, z;
};

struct Quaternion4f
{
	float x, y, z, w;
};

inline float UnityReorientHeading(float heading)
{
	if (IsCompensatingSensors())
	{
		float rotateBy = 0.f;
		switch (UnityCurrentOrientation())
		{
			case portraitUpsideDown:
				rotateBy = -180.f;
				break;
			case landscapeLeft:
				rotateBy = -270.f;
				break;
			case landscapeRight:
				rotateBy = -90.f;
				break;
			default:
				break;
		}

		return fmodf((360.f + heading + rotateBy), 360.f);
	}
	else
	{
		return heading;
	}
}

inline Vector3f UnityReorientVector3(float x, float y, float z)
{
	if (IsCompensatingSensors())
	{
		Vector3f res;
		switch (UnityCurrentOrientation())
		{
			case portraitUpsideDown:
				{ res = (Vector3f){-x, -y, z}; }
				break;
			case landscapeLeft:
				{ res = (Vector3f){-y, x, z}; }
				break;
			case landscapeRight:
				{ res = (Vector3f){y, -x, z}; }
				break;
			default:
				{ res = (Vector3f){x, y, z}; }
		}
		return res;
	}
	else
	{
		return (Vector3f){x, y, z};
	}
}

static Quaternion4f gQuatRot[4] =
{	// { x*sin(theta/2), y*sin(theta/2), z*sin(theta/2), cos(theta/2) }
	// => { 0, 0, sin(theta/2), cos(theta/2) } (since <vec> = { 0, 0, +/-1})
	{ 0.f, 0.f, 0.f /*sin(0)*/, 1.f /*cos(0)*/},	// ROTATION_0, theta = 0 rad
	{ 0.f, 0.f, (float)sqrt(2) * 0.5f /*sin(pi/4)*/, -(float)sqrt(2) * 0.5f /*cos(pi/4)*/},	// ROTATION_90, theta = pi/4 rad
	{ 0.f, 0.f, 1.f /*sin(pi/2)*/, 0.f /*cos(pi/2)*/},	// ROTATION_180, theta = pi rad
	{ 0.f, 0.f, -(float)sqrt(2) * 0.5f/*sin(3pi/4)*/, -(float)sqrt(2) * 0.5f /*cos(3pi/4)*/}	// ROTATION_270, theta = 3pi/2 rad
};

inline void MultQuat(Quaternion4f& result, const Quaternion4f& lhs, const Quaternion4f& rhs)
{
	result.x = lhs.w*rhs.x + lhs.x*rhs.w + lhs.y*rhs.z - lhs.z*rhs.y;
	result.y = lhs.w*rhs.y + lhs.y*rhs.w + lhs.z*rhs.x - lhs.x*rhs.z;
	result.z = lhs.w*rhs.z + lhs.z*rhs.w + lhs.x*rhs.y - lhs.y*rhs.x;
	result.w = lhs.w*rhs.w - lhs.x*rhs.x - lhs.y*rhs.y - lhs.z*rhs.z;
}

inline Quaternion4f UnityReorientQuaternion(float x, float y, float z, float w)
{
	if (IsCompensatingSensors())
	{
		Quaternion4f res, inp = {x, y, z, w};
		switch (UnityCurrentOrientation())
		{
			case landscapeLeft:
				MultQuat(res, inp, gQuatRot[1]);
				break;
			case portraitUpsideDown:
				MultQuat(res, inp, gQuatRot[2]);
				break;
			case landscapeRight:
				MultQuat(res, inp, gQuatRot[3]);
				break;
			default:
				res = inp;
		}
		return res;
	}
	else
	{
		return (Quaternion4f){x, y, z, w};
	}
}


static CMMotionManager*		sMotionManager	= nil;
static NSOperationQueue*	sMotionQueue	= nil;

// Current update interval or 0.0f if not initialized. This is returned
// to the user as current update interval and this value is set to 0.0f when
// gyroscope is disabled.
static float sUpdateInterval = 0.0f;

// Update interval set by the user. Core motion will be set-up to use
// this update interval after disabling and re-enabling gyroscope
// so users can set update interval, disable gyroscope, enable gyroscope and
// after that gyroscope will be updated at this previously set interval.
static float sUserUpdateInterval = 1.0f / 30.0f;


void SensorsCleanup()
{
	if (sMotionManager != nil)
	{
		[sMotionManager stopGyroUpdates];
		[sMotionManager stopDeviceMotionUpdates];
		[sMotionManager stopAccelerometerUpdates];
		sMotionManager = nil;
	}

	sMotionQueue = nil;
}

extern "C" void UnityCoreMotionStart()
{
	if(sMotionQueue == nil)
		sMotionQueue = [[NSOperationQueue alloc] init];

	bool initMotionManager = (sMotionManager == nil);
	if(initMotionManager)
		sMotionManager = [[CMMotionManager alloc] init];

	if(gEnableGyroscope && sMotionManager.gyroAvailable)
	{
		[sMotionManager startGyroUpdates];
		[sMotionManager setGyroUpdateInterval: sUpdateInterval];
	}

	if(gEnableGyroscope && sMotionManager.deviceMotionAvailable)
	{
		[sMotionManager startDeviceMotionUpdates];
		[sMotionManager setDeviceMotionUpdateInterval: sUpdateInterval];
	}

	if(initMotionManager && sMotionManager.accelerometerAvailable)
	{
		int frequency = UnityGetAccelerometerFrequency();
		if (frequency > 0)
		{
			[sMotionManager startAccelerometerUpdatesToQueue: sMotionQueue withHandler:^( CMAccelerometerData* data, NSError* error){
				Vector3f res = UnityReorientVector3(data.acceleration.x, data.acceleration.y, data.acceleration.z);
				UnityDidAccelerate(res.x, res.y, res.z, data.timestamp);
			}];
			[sMotionManager setAccelerometerUpdateInterval:1.0f/frequency];
		}
	}
}

extern "C" void UnityCoreMotionStop()
{
	if(sMotionManager != nil)
	{
		[sMotionManager stopGyroUpdates];
		[sMotionManager stopDeviceMotionUpdates];
	}
}


extern "C" void UnitySetGyroUpdateInterval(int idx, float interval)
{
	static const float _MinUpdateInterval = 1.0f/60.0f;
	static const float _MaxUpdateInterval = 1.0f;

	if(interval < _MinUpdateInterval)		interval = _MinUpdateInterval;
	else if(interval > _MaxUpdateInterval)	interval = _MaxUpdateInterval;

	sUserUpdateInterval = interval;

	if(sMotionManager)
	{
		sUpdateInterval = interval;

		[sMotionManager setGyroUpdateInterval:interval];
		[sMotionManager setDeviceMotionUpdateInterval:interval];
	}
}

extern "C" float UnityGetGyroUpdateInterval(int idx)
{
	return sUpdateInterval;
}

extern "C" void UnityUpdateGyroData()
{
	CMRotationRate rotationRate = { 0.0, 0.0, 0.0 };
	CMRotationRate rotationRateUnbiased = { 0.0, 0.0, 0.0 };
	CMAcceleration userAcceleration = { 0.0, 0.0, 0.0 };
	CMAcceleration gravity = { 0.0, 0.0, 0.0 };
	CMQuaternion attitude = { 0.0, 0.0, 0.0, 1.0 };

	if (sMotionManager != nil)
	{
		CMGyroData *gyroData = sMotionManager.gyroData;
		CMDeviceMotion *motionData = sMotionManager.deviceMotion;

		if (gyroData != nil)
		{
			rotationRate = gyroData.rotationRate;
		}

		if (motionData != nil)
		{
			CMAttitude *att = motionData.attitude;

			attitude = att.quaternion;
			rotationRateUnbiased = motionData.rotationRate;
			userAcceleration = motionData.userAcceleration;
			gravity = motionData.gravity;
		}
	}

	Vector3f reorientedRotRate = UnityReorientVector3(rotationRate.x, rotationRate.y, rotationRate.z);
	UnitySensorsSetGyroRotationRate(0, reorientedRotRate.x, reorientedRotRate.y, reorientedRotRate.z);

	Vector3f reorientedRotRateUnbiased = UnityReorientVector3(rotationRateUnbiased.x, rotationRateUnbiased.y, rotationRateUnbiased.z);
	UnitySensorsSetGyroRotationRateUnbiased(0, reorientedRotRateUnbiased.x, reorientedRotRateUnbiased.y, reorientedRotRateUnbiased.z);

	Vector3f reorientedUserAcc = UnityReorientVector3(userAcceleration.x, userAcceleration.y, userAcceleration.z);
	UnitySensorsSetUserAcceleration(0, reorientedUserAcc.x, reorientedUserAcc.y, reorientedUserAcc.z);

	Vector3f reorientedG = UnityReorientVector3(gravity.x, gravity.y, gravity.z);
	UnitySensorsSetGravity(0, reorientedG.x, reorientedG.y, reorientedG.z);

	Quaternion4f reorientedAtt = UnityReorientQuaternion(attitude.x, attitude.y, attitude.z, attitude.w);
	UnitySensorsSetAttitude(0, reorientedAtt.x, reorientedAtt.y, reorientedAtt.z, reorientedAtt.w);
}

extern "C" int UnityIsGyroEnabled(int idx)
{
	if (sMotionManager == nil)
		return 0;

	return sMotionManager.gyroAvailable && sMotionManager.gyroActive;
}

extern "C" int UnityIsGyroAvailable()
{
	if (sMotionManager != nil)
		return sMotionManager.gyroAvailable;

	return 0;
}

// -- Joystick stuff --
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
enum JoystickButtonNumbers
{
	BTN_PAUSE = 0,
	BTN_DPAD_UP = 4,
	BTN_DPAD_RIGHT = 5,
	BTN_DPAD_DOWN = 6,
	BTN_DPAD_LEFT = 7,
	BTN_Y = 12,
	BTN_B = 13,
	BTN_A = 14,
	BTN_X = 15,
	BTN_L1 = 8,
	BTN_L2 = 10,
	BTN_R1 = 9,
	BTN_R2 = 11
};


static float GetAxisValue(GCControllerAxisInput* axis)
{
	return axis.value;
}

static BOOL GetButtonPressed(GCControllerButtonInput* button)
{
	return button.pressed;
}

static BOOL GetButtonValue(GCControllerButtonInput* button)
{
	return button.value;
}

extern "C" void UnityInitJoysticks()
{
	if (!gJoysticksInited)
	{
		NSBundle* bundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/GameController.framework"];
		if(bundle)
		{
			[bundle load];
			Class retClass = [bundle classNamed:@"GCController"];
			if( retClass &&	[retClass respondsToSelector:@selector(controllers)] )
				gGameControllerClass = retClass;
		}

		gJoysticksInited = true;
	}
}

static NSArray* QueryControllerCollection()
{
	return gGameControllerClass != nil ? (NSArray*)[gGameControllerClass performSelector:@selector(controllers)] : nil;
}

static void SetJoystickButtonState (int joyNum, int buttonNum, int state)
{
	char buf[128];
	sprintf (buf, "joystick %d button %d", joyNum, buttonNum);
	UnitySetKeyState (UnityStringToKey (buf), state);

	// Mirror button input into virtual joystick 0
	sprintf (buf, "joystick button %d", buttonNum);
	UnitySetKeyState (UnityStringToKey (buf), state);
}

static void ReportJoystick(GCController* controller, int idx)
{
	if (controller.controllerPausedHandler == nil)
		controller.controllerPausedHandler = gControllerHandler;

	// For basic profile map hatch to Vertical + Horizontal axes
	if ([controller extendedGamepad] == nil)
	{
		GCGamepad* gamepad = [controller gamepad];
		GCControllerDirectionPad* dpad = [gamepad dpad];

		UnitySetJoystickPosition(idx + 1, 0, GetAxisValue([dpad xAxis]));
		UnitySetJoystickPosition(idx + 1, 1, -GetAxisValue([dpad yAxis]));

		SetJoystickButtonState(idx + 1, BTN_DPAD_UP, GetButtonPressed([dpad up]));
		UnitySetJoystickPosition(idx + 1, BTN_DPAD_UP, GetButtonValue([dpad up]));
		SetJoystickButtonState(idx + 1, BTN_DPAD_RIGHT, GetButtonPressed([dpad right]));
		UnitySetJoystickPosition(idx + 1, BTN_DPAD_RIGHT, GetButtonValue([dpad right]));
		SetJoystickButtonState(idx + 1, BTN_DPAD_DOWN, GetButtonPressed([dpad down]));
		UnitySetJoystickPosition(idx + 1, BTN_DPAD_DOWN, GetButtonValue([dpad down]));
		SetJoystickButtonState(idx + 1, BTN_DPAD_LEFT, GetButtonPressed([dpad left]));
		UnitySetJoystickPosition(idx + 1, BTN_DPAD_LEFT, GetButtonValue([dpad left]));

		SetJoystickButtonState(idx + 1, BTN_A, GetButtonPressed([gamepad buttonA]));
		UnitySetJoystickPosition(idx + 1, BTN_A, GetButtonValue([gamepad buttonA]));
		SetJoystickButtonState(idx + 1, BTN_B, GetButtonPressed([gamepad buttonB]));
		UnitySetJoystickPosition(idx + 1, BTN_B, GetButtonValue([gamepad buttonB]));
		SetJoystickButtonState(idx + 1, BTN_Y, GetButtonPressed([gamepad buttonY]));
		UnitySetJoystickPosition(idx + 1, BTN_Y, GetButtonValue([gamepad buttonY]));
		SetJoystickButtonState(idx + 1, BTN_X, GetButtonPressed([gamepad buttonX]));
		UnitySetJoystickPosition(idx + 1, BTN_X, GetButtonValue([gamepad buttonX]));

		SetJoystickButtonState(idx + 1, BTN_L1, GetButtonPressed([gamepad leftShoulder]));
		UnitySetJoystickPosition(idx + 1, BTN_L1, GetButtonValue([gamepad leftShoulder]));
		SetJoystickButtonState(idx + 1, BTN_R1, GetButtonPressed([gamepad rightShoulder]));
		UnitySetJoystickPosition(idx + 1, BTN_R1, GetButtonValue([gamepad rightShoulder]));
	}
	else
	{
		GCExtendedGamepad* extendedPad = [controller extendedGamepad];
		GCControllerDirectionPad* dpad = [extendedPad dpad];
		GCControllerDirectionPad* leftStick = [extendedPad leftThumbstick];
		GCControllerDirectionPad* rightStick = [extendedPad rightThumbstick];

		UnitySetJoystickPosition(idx + 1, 0, GetAxisValue([leftStick xAxis]));
		UnitySetJoystickPosition(idx + 1, 1, -GetAxisValue([leftStick yAxis]));

		UnitySetJoystickPosition(idx + 1, 2, GetAxisValue([rightStick xAxis]));
		UnitySetJoystickPosition(idx + 1, 3, -GetAxisValue([rightStick yAxis]));


		SetJoystickButtonState(idx + 1, BTN_DPAD_UP, GetButtonPressed([dpad up]));
		UnitySetJoystickPosition(idx + 1, BTN_DPAD_UP, GetButtonValue([dpad up]));
		SetJoystickButtonState(idx + 1, BTN_DPAD_RIGHT, GetButtonPressed([dpad right]));
		UnitySetJoystickPosition(idx + 1, BTN_DPAD_RIGHT, GetButtonValue([dpad right]));
		SetJoystickButtonState(idx + 1, BTN_DPAD_DOWN, GetButtonPressed([dpad down]));
		UnitySetJoystickPosition(idx + 1, BTN_DPAD_DOWN, GetButtonValue([dpad down]));
		SetJoystickButtonState(idx + 1, BTN_DPAD_LEFT, GetButtonPressed([dpad left]));
		UnitySetJoystickPosition(idx + 1, BTN_DPAD_LEFT, GetButtonValue([dpad left]));

		SetJoystickButtonState(idx + 1, BTN_A, GetButtonPressed([extendedPad buttonA]));
		UnitySetJoystickPosition(idx + 1, BTN_A, GetButtonValue([extendedPad buttonA]));
		SetJoystickButtonState(idx + 1, BTN_B, GetButtonPressed([extendedPad buttonB]));
		UnitySetJoystickPosition(idx + 1, BTN_B, GetButtonValue([extendedPad buttonB]));
		SetJoystickButtonState(idx + 1, BTN_Y, GetButtonPressed([extendedPad buttonY]));
		UnitySetJoystickPosition(idx + 1, BTN_Y, GetButtonValue([extendedPad buttonY]));
		SetJoystickButtonState(idx + 1, BTN_X, GetButtonPressed([extendedPad buttonX]));
		UnitySetJoystickPosition(idx + 1, BTN_X, GetButtonValue([extendedPad buttonX]));

		SetJoystickButtonState(idx + 1, BTN_L1, GetButtonPressed([extendedPad leftShoulder]));
		UnitySetJoystickPosition(idx + 1, BTN_L1, GetButtonValue([extendedPad leftShoulder]));
		SetJoystickButtonState(idx + 1, BTN_R1, GetButtonPressed([extendedPad rightShoulder]));
		UnitySetJoystickPosition(idx + 1, BTN_R1, GetButtonValue([extendedPad rightShoulder]));
		SetJoystickButtonState(idx + 1, BTN_L2, GetButtonPressed([extendedPad leftTrigger]));
		UnitySetJoystickPosition(idx + 1, BTN_L2, GetButtonValue([extendedPad leftTrigger]));
		SetJoystickButtonState(idx + 1, BTN_R2, GetButtonPressed([extendedPad rightTrigger]));
		UnitySetJoystickPosition(idx + 1, BTN_R2, GetButtonValue([extendedPad rightTrigger]));
	}

	// Map pause button
	SetJoystickButtonState(idx + 1, BTN_PAUSE, gPausedJoysticks[idx]);

	// Reset pause button
	gPausedJoysticks[idx] = false;
}

extern "C" void UnityUpdateJoystickData()
{
	NSArray* list = QueryControllerCollection();
	if (list != nil)
	{
		for (int i = 0; i < [list count]; i++)
		{
			id controller = [list objectAtIndex:i];
			ReportJoystick(controller, i);
		}
	}
}

extern "C" int	UnityGetJoystickCount()
{
	NSArray* list = QueryControllerCollection();
	return list != nil ? [list count] : 0;
}

extern "C" void UnityGetJoystickName(int idx, char* buffer, int maxLen)
{
	GCController* controller = [QueryControllerCollection() objectAtIndex:idx];

	if (controller != nil)
	{
		// iOS 8 has bug, which is encountered when controller is being attached
		// while app is still running. It creates two instances of controller object:
		// one original and one "Forwarded", accesing later properties are causing crashes
		const char* attached = "unknown";

		// Controller is good one
		if ([[controller vendorName] rangeOfString:@"Forwarded"].location == NSNotFound)
			attached = (controller.attachedToDevice ? "wired" : "wireless");

		snprintf(buffer, maxLen, "[%s,%s] joystick %d by %s",
					([controller extendedGamepad] != nil ? "extended" : "basic"),
					attached,
					idx + 1,
					[[controller vendorName] UTF8String]);
	}
	else
	{
		strncpy(buffer, "unknown", maxLen);
	}
}

extern "C" void UnityGetJoystickAxisName(int idx, int axis, char* buffer, int maxLen)
{

}

extern "C" void UnityGetNiceKeyname(int key, char* buffer, int maxLen)
{

}
#pragma clang diagnostic pop



@interface LocationServiceDelegate : NSObject <CLLocationManagerDelegate>
@end

void
UnitySetLastLocation(double timestamp,
					 float latitude,
					 float longitude,
					 float altitude,
					 float horizontalAccuracy,
					 float verticalAccuracy);

void
UnitySetLastHeading(float magneticHeading,
					float trueHeading,
					float rawX, float rawY, float rawZ,
					double timestamp);

struct LocationServiceInfo
{
private:
	LocationServiceDelegate* delegate;
	CLLocationManager* locationManager;
public:
	LocationServiceStatus locationStatus;
	LocationServiceStatus headingStatus;

	float desiredAccuracy;
	float distanceFilter;

	LocationServiceInfo();
	CLLocationManager* GetLocationManager();
};

LocationServiceInfo::LocationServiceInfo()
{
	locationStatus = kLocationServiceStopped;
	desiredAccuracy = kCLLocationAccuracyKilometer;
	distanceFilter = 500;

	headingStatus = kLocationServiceStopped;
}

static LocationServiceInfo gLocationServiceStatus;

CLLocationManager*
LocationServiceInfo::GetLocationManager()
{
	if (locationManager == nil)
	{
		locationManager = [[CLLocationManager alloc] init];
		delegate = [LocationServiceDelegate alloc];

		locationManager.delegate = delegate;
	}

	return locationManager;
}


bool LocationService::IsServiceEnabledByUser()
{
	return [CLLocationManager locationServicesEnabled];
}


void LocationService::SetDesiredAccuracy(float val)
{
	gLocationServiceStatus.desiredAccuracy = val;
}

float LocationService::GetDesiredAccuracy()
{
	return gLocationServiceStatus.desiredAccuracy;
}

void LocationService::SetDistanceFilter(float val)
{
	gLocationServiceStatus.distanceFilter = val;
}

float LocationService::GetDistanceFilter()
{
	return gLocationServiceStatus.distanceFilter;
}

void LocationService::StartUpdatingLocation()
{
	if (gLocationServiceStatus.locationStatus != kLocationServiceRunning)
	{
		CLLocationManager* locationManager = gLocationServiceStatus.GetLocationManager();

		// request authorization on ios8
		if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
			[locationManager performSelector:@selector(requestWhenInUseAuthorization)];

		locationManager.desiredAccuracy = gLocationServiceStatus.desiredAccuracy;
		// Set a movement threshold for new events
		locationManager.distanceFilter = gLocationServiceStatus.distanceFilter;
		[locationManager startUpdatingLocation];

		gLocationServiceStatus.locationStatus = kLocationServiceInitializing;
	}
}

void LocationService::StopUpdatingLocation()
{
	if (gLocationServiceStatus.locationStatus == kLocationServiceRunning)
	{
		[gLocationServiceStatus.GetLocationManager() stopUpdatingLocation];
		gLocationServiceStatus.locationStatus = kLocationServiceStopped;
	}
}

void LocationService::SetHeadingUpdatesEnabled(bool enabled)
{
	if (enabled)
	{
		if (gLocationServiceStatus.headingStatus != kLocationServiceRunning &&
			IsHeadingAvailable())
		{
			CLLocationManager* locationManager = gLocationServiceStatus.GetLocationManager();

			[locationManager startUpdatingHeading];
			gLocationServiceStatus.headingStatus = kLocationServiceInitializing;
		}
	}
	else
	{
		if(gLocationServiceStatus.headingStatus == kLocationServiceRunning)
		{
			[gLocationServiceStatus.GetLocationManager() stopUpdatingHeading];
			gLocationServiceStatus.headingStatus = kLocationServiceStopped;
		}
	}

}

bool LocationService::IsHeadingUpdatesEnabled()
{
	return (gLocationServiceStatus.headingStatus == kLocationServiceRunning);
}

int UnityGetLocationStatus()
{
	return gLocationServiceStatus.locationStatus;
}

int UnityGetHeadingStatus()
{
	return gLocationServiceStatus.headingStatus;
}

bool LocationService::IsHeadingAvailable()
{
	return [CLLocationManager headingAvailable];
}

@implementation LocationServiceDelegate

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations
{
	CLLocation* lastLocation = locations.lastObject;

	gLocationServiceStatus.locationStatus = kLocationServiceRunning;

	UnitySetLastLocation([lastLocation.timestamp timeIntervalSince1970],
						 lastLocation.coordinate.latitude, lastLocation.coordinate.longitude, lastLocation.altitude,
						 lastLocation.horizontalAccuracy, lastLocation.verticalAccuracy
						);
}

- (void)locationManager:(CLLocationManager*)manager didUpdateHeading:(CLHeading*)newHeading
{
	gLocationServiceStatus.headingStatus = kLocationServiceRunning;

	Vector3f reorientedRawHeading = UnityReorientVector3(newHeading.x, newHeading.y, newHeading.z);

	UnitySetLastHeading(UnityReorientHeading(newHeading.magneticHeading),
						UnityReorientHeading(newHeading.trueHeading),
						reorientedRawHeading.x, reorientedRawHeading.y, reorientedRawHeading.z,
						[newHeading.timestamp timeIntervalSince1970]);
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager*)manager
{
	return NO;
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error;
{
	gLocationServiceStatus.locationStatus = kLocationServiceFailed;
	gLocationServiceStatus.headingStatus = kLocationServiceFailed;
}

@end
