CardboardSDK-iOS
===============

*March 2016 update*

Google has released an official [iOS CardboardSDK](https://developers.google.com/cardboard/ios/get-started#downloading_and_building_the_app). However, for now it's a closed source precompiled library.

---

iOS port of  [Google's CardboardSDK](https://github.com/rsanchezsaez/cardboard-java).

*Treasure* example fully running with magnetic trigger detection. Successfully tested on an iPhone 6 running iOS 8 and on a iPhone 5 running iOS 7.

It (mostly) has feature parity with *Android's CardboardSDK v0.5.1*.

### Unity

There is a bundled sample *Unity project* compatible with *Unity 5.0.0f4* (use other Unity versions at your own risk).

The `Unity\Cardboard.UnityProject` folder contains the sample project based on [Google's CardboardSDK-Unity plugin](https://github.com/googlesamples/cardboard-unity).

#### Unity Instructions

There are two ways of running the *Unity project* on an *iOS device*:

##### a. Pre-built Unity Xcode project

You can use the bundled pre-built *Unity Xcode project*, but you need to regenerate `libiPhone-lib.a`, as it's too big to commit to *GitHub*.

This method is useful for updating the *Xcode project* after changing the *Unity project* or its *Cardboard Unity scripts*.

1. Open the *Unity project* on *Unity 5.0.0f4*.
2. Go to `File -> Build Settings`, choose `iOS` and click `Build`. Choose the already existing `Unity\Cardboard.UnityProject\builds\iOS` as the output folder and click on `Append`. *Unity* should then update your current project with the needed Unity library binary without overwriting the *CardboardSDK* native code.
4. Open `Unity\Cardboard.UnityProject\builds\iOS\Unity-iPhone.xcodeproj` on *Xcode* and run on an *iOS device* (tested on *Xcode 6.2*).
 
##### b. Build your own Unity Xcode project

You can disregard the `Unity\Cardboard.UnityProject\builds\iOS\` folder and build your own project from scratch.

This method is useful if you want to rebuild the *Unity Xcode project* after updating *Unity* to a newer version (newer *Unity* versions won't let you append to an already built *Xcode* project).

1. Open the *Unity project* on *Unity 5.0.0f4* or later.
2. Go to `File -> Build Settings`, choose `iOS`, click `Build` and save it to any folder of your choosing.
3. Open the built project on *Xcode*.
4. Add the *CardboardSDK* source files to the *Classes* group: right click on *Classes* and choose `Add files to "Unity-iPhone"`. Do not copy the *CardboardSDK* source, just link them at their original location by unchecking `Copy items if needed`.
5. Add the *GLKit framework*: go to the `Unity-iPhone target` -> `Build Phases` -> `Link Binary With Libraries` and add the `GLKit.framework`.
6. Go to Project -> Build Settings and set: `C++ Language Dialect` to `GNU++11`.

#### Unity Issues

- Magnetic trigger not working
- Distortion correction not working

### General Todo

- Update native code and Unity project to *CardboardSDK v0.5.2*. 
- Fix Unity issues
- Replace `Matrix3x3d` and `Vector3d` by [eigen3](http://eigen.tuxfamily.org/).
- Provide easy way of configuring custom Cardboard devices.
- Add additional examples.

### Discusion

#### Overlay Views

The `CBStereoGLView`class allows any `UIView` to be rendered to `OpenGL`. You can subclass it for your app overlay (lens distortion correction is correctly applied to it). See the `TextOverlayView` subclass on the *Treasure* example.

Avoid updating the texture on every frame as it's an expensive operation (performing `UIView` animations is not a good idea).

#### Headtracker

 The `HeadTracker` can either use:

- Google's `OrientationEKF` class with raw gyro and accelerometer data. Has very low latency but suffers from gyro drift (slight continuous rotation movement when stationary). This is the current *Android*'s *CardboardSDK* approach.
- *CoreMotion*'s `CMDeviceMotion.attitude`. Improves the gyro drift, but very noticeably worsens the latency (*CoreMotion* does its own *EKF*-like internal *IMU*-fusion algorithm).
- *CoreMotion*'s `CMDeviceMotion.attitude` data with Google's `OrientationEKF`. Best of both worlds: low latency and low gyro drift, but uses more CPU (basically it does the *IMU* integration twice).

In general using `HEAD_TRACKER_MODE_CORE_MOTION_EKF` is recommended. 

In `HeadTracker.mm`, you can set `#define HEAD_TRACKER_MODE` to either
`HEAD_TRACKER_MODE_EKF`,
`HEAD_TRACKER_MODE_CORE_MOTION`, or
` HEAD_TRACKER_MODE_CORE_MOTION_EKF`.

### General Issues

- Reading the Cardboard configuration from NFC has not been implemented, as there's no public *NFC API* available on *iOS 8*. Hopefully Apple will provide one on *iOS 9* (only the *iPhone 6/6+* or higher have an NFC sensor).


### License & Contributors

*CardboardSDK-iOS*, as the original *CardboardSDK*, is available under the *Apache license*. See the [`LICENSE`](./LICENSE) file for more info.

See  [`AUTHORS.md`](./AUTHORS.md) for some of the project contributors.
