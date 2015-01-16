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

 The `HeadTracker` can alternatively use  *CoreMotion*'s attitude  instead of Google's `OrientationEKF` class  (*CoreMotion* does its own *EKF*-like internal *IMU*-fusion algorithm). 

Using *CoreMotion* very noticeably worsens the latency , but improves the gyro drift (slight continuous rotation movement when stationary).

In general using `OrientationEKF` is recommended because the lag is much less noticeable. 

Set `#define USE_EKF (0)` to use *CoreMotion*.

### License & Contributors

*CardboardSDK-iOS*, as the original *CardboardSDK*, is available under the *Apache license*. See the [`LICENSE`](./LICENSE) file for more info.

See  [`AUTHORS.md`](./AUTHORS.md) for some of the project contributors.