CardboardSDK-iOS
===============

iOS port of  [Google's CardboardSDK](https://github.com/rsanchezsaez/cardboard-java).

*Treasure* example fully running with magnetic trigger detection. Successfully tested on an iPhone 6 running iOS 8 and on a iPhone 5 running iOS 7.

### Todo

- Text overlay messages (`CardboardOverlayView`, part of  *Treasure* example).
- Match latest CardboardSDK functionality (some refactoring which moved some transformations from CardboardView into EyeParams and the such; adding optional neck support on the HeadTracker; optional vignetting on the distortion renderer; etc).
- Having additional examples would be nice.

### Issues

- NFC doesn't work, as there's no NFC API available on iOS 8. (Hopefully Apple will provide one on iOS 9. But then, only the iPhone 6/6+ or higher have NFC).

### Discusion

 The `HeadTracker` can either use:

- Google's `OrientationEKF` class with raw gyro and accelerometer data. Has very low latency but suffers from gyro drift (slight continuous rotation movement when stationary). This is the current *Android*'s *CardboardSDK* approach.
 - *CoreMotion*'s `CMDeviceMotion.attitude` improves the gyro drift, but very noticeably worsens the latency (*CoreMotion* does its own *EKF*-like internal *IMU*-fusion algorithm).
- *CoreMotion*'s `CMDeviceMotion.attitude` data with Google's `OrientationEKF`. Best of both worlds: low latency and low gyro drift, but uses more CPU (basically it does the *IMU* integration twice).

In general using `HEAD_TRACKER_MODE_CORE_MOTION_EKF` is recommended. 

In `HeadTracker.mm`, you can set `#define HEAD_TRACKER_MODE` to either
`HEAD_TRACKER_MODE_EKF`,
`HEAD_TRACKER_MODE_CORE_MOTION`, or
` HEAD_TRACKER_MODE_CORE_MOTION_EKF`.

### License & Contributors

*CardboardSDK-iOS*, as the original *CardboardSDK*, is available under the *Apache license*. See the [`LICENSE`](./LICENSE) file for more info.

See  [`AUTHORS.md`](./AUTHORS.md) for some of the project contributors.