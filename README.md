CardboardSDK-iOS
===============

iOS port of  [Google's CardboardSDK](https://github.com/rsanchezsaez/cardboard-java).

*Treasure* example fully running with magnetic trigger detection. Successfully tested on an iPhone 6 running iOS 8 and on a iPhone 5 running iOS 7.

It (mostly) has feature parity with *Android's CardboardSDK v0.5.1*.

### Todo

- Replace `Matrix3x3d` and `Vector3d` by [eigen3](http://eigen.tuxfamily.org/).
- Provide easy way of configuring custom Cardboard devices.
- Additional examples.

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

### Issues

- Reading the Cardboard configuration from NFC has not been implemented, as there's no public NFC API available on iOS 8. Hopefully Apple will provide one on iOS 9 (only the iPhone 6/6+ or higher have NFC).


### License & Contributors

*CardboardSDK-iOS*, as the original *CardboardSDK*, is available under the *Apache license*. See the [`LICENSE`](./LICENSE) file for more info.

See  [`AUTHORS.md`](./AUTHORS.md) for some of the project contributors.
