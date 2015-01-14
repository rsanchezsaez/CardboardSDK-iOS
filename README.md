CardboardVR-iOS
===============

Port of [Google's CardboardSDK](https://github.com/rsanchezsaez/cardboard-java) (with manually decompiled sources) for iOS.

Treasure example fully running with magnetic trigger detection. Missing: text overlay messages (`CardboardOverlayView`). Successfully tested on an iPhone 6 running iOS 8 and on a iPhone 5 running iOS 7.

Note that this currently uses `CoreMotion`'s attitude on the HeadTracker (I'm not using Google's OrientationEKF at all, probably `CoreMotion` does it's own EKF internally).  

Todo:

- Update it to be on par with the latest CardboardSDK (some refactoring which moved some transformations from CardboardView into EyeParams and the such; adding optional neck support on the HeadTracker; optional vignetting on the distortion renderer; etc).

Issues:

- Latency seems a bit worse on iOS than on some Android devices. I'm not sure if this is due to `CoreMotion`'s attitude estimation being less responsive than EKF; due to the iOS hardware delivering updated readings less frequentlu; or due to some other inefficiency in the current OpenGL pipeline.
- NFC doesn't work, as there's no NFC API available on iOS 8.