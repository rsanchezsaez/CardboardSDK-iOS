// Copyright 2014 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if UNITY_ANDROID && !UNITY_EDITOR
#define ANDROID_DEVICE
#endif

#if UNITY_IPHONE && !UNITY_EDITOR
#define IOS_DEVICE
#endif


using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;

// A Cardboard object serves as the bridge between the C# and the Java/native
// components of the plugin.
//
// On each frame, it's responsible for
//  - Reading the current head orientation and eye transforms from the Java
//    vrtoolkit
//  - Triggering the native (C++) UnityRenderEvent callback at the end of the
//    frame.  This sends the texture containing the latest frame that Unity
//    rendered into the Java vrtoolkit to be corrected for lens distortion and
//    displayed on the device.
public class Cardboard : MonoBehaviour {
  // Distinguish the two stereo eyes.
  public enum Eye {
    Left,
    Right
  }

  // Lacking any better knowledge, use this as the inter-pupillary distance.
  public const float NOMINAL_IPD = 0.06f;

  // The singleton instance of the Cardboard class.
  private static Cardboard sdk = null;

  public static Cardboard SDK {
    get {
      if (sdk == null) {
        Debug.Log("Creating SDK object");
        var go = new GameObject("Cardboard SDK", typeof(Cardboard));
        go.transform.localPosition = Vector3.zero;
      }
      return sdk;
    }
  }

  // Whether VR-mode is enabled.
  [SerializeField]
  [HideInInspector]
  private bool vrModeEnabled = true;

  public bool VRModeEnabled {
    get { return vrModeEnabled; }
    set {
      vrModeEnabled = value;
    }
  }

  [SerializeField]
  [HideInInspector]
  private bool enableAlignmentMarker = true;

  // Whether to draw the alignment marker. The marker is a vertical line that
  // splits the viewport in half, designed to help users align the screen with the Cardboard.
  public bool EnableAlignmentMarker {
      get { return enableAlignmentMarker; }
      set {
          enableAlignmentMarker = value;
#if ANDROID_DEVICE
          try {
              cardboardActivity.Call("setEnableAlignmentMarker", enableAlignmentMarker);
          } catch (AndroidJavaException e) {
              Debug.LogError("Failed to SetEnableAlignmentMarker: " + e);
          }
#elif IOS_DEVICE
			//UILAYER, IGNORE FOR NOW
			enableAlignmentMarker = true;
#endif
      }
  }

  [SerializeField]
  [HideInInspector]
  private bool enableSettingsButton = true;

  // Whether to draw the settings button. The settings button opens the Google
  // Cardboard app to allow the user to  configure their individual settings and Cardboard
  // headset parameters
  public bool EnableSettingsButton {
      get { return enableSettingsButton; }
      set {
          enableSettingsButton = value;
#if ANDROID_DEVICE
          try {
              cardboardActivity.Call("setEnableSettingsButton", enableSettingsButton);
          } catch (AndroidJavaException e) {
              Debug.LogError("Failed to SetEnableSettingsButton: " + e);
          }
#elif IOS_DEVICE
			//UILAYER, IGNORE FOR NOW
#endif
      }
  }

  // Whether the device is in the Cardboard.
  public bool InCardboard { get; private set; }

  // Defer updating InCardboard till end of frame.
  private bool newInCardboard;

#if UNITY_EDITOR
  // Helper for the custom editor script.
  public void SetInCardboard(bool value) {
      newInCardboard = value; // Takes effect at end of frame.
  }
#endif

  // Whether the Cardboard trigger (i.e. magnet) was pulled.
  // True for exactly one frame (between 2 EndOfFrames) on each pull.
  public bool CardboardTriggered { get; private set; }

  // Next frame's value of CardboardTriggered.
  private bool newCardboardTriggered = false;

  // Whether screen taps are converted to Cardboard trigger events.
  public bool TapIsTrigger {
      get { return tapIsTrigger; }
      set {
          tapIsTrigger = value;
#if ANDROID_DEVICE
          try {
              cardboardActivity.Call("setConvertTapIntoTrigger", tapIsTrigger);
          } catch (AndroidJavaException e) {
              Debug.LogError("Failed to setConvertTapIntoTrigger: " + e);
          }
#elif IOS_DEVICE
			//TODO: PORT THIS CODE
			// convertTapIntoTrigger(tapIsTrigger);
#endif
      }
  }

  [SerializeField]
  [HideInInspector]
  private bool tapIsTrigger = false;

  // The texture that Unity renders the scene to. This is sent to the plugin,
  // which renders it to screen, correcting for lens distortion.
  public RenderTexture StereoScreen { get; private set; }

  // Transform from body to head.
  public Matrix4x4 HeadView { get { return headView; } }

  // The transformation from head to eye.
  public Matrix4x4 EyeView(Cardboard.Eye eye) {
      return eye == Cardboard.Eye.Left ? leftEyeView : rightEyeView;
  }

  // The projection matrix for a given eye.  This encodes the field of view,
  // IPD, and other parameters configured by the SDK.
  public Matrix4x4 Projection(Cardboard.Eye eye) {
      return eye == Cardboard.Eye.Left ? leftEyeProj : rightEyeProj;
  }

  // Local transformation of head.
  public Quaternion HeadRotation { get; private set; }

  // Local transformations of eyes relative to head.
  public Vector3 LeftEyeOffset  { get; private set; }
  public Vector3 RightEyeOffset { get; private set; }
  public Vector3 EyeOffset(Cardboard.Eye eye) {
      return eye == Cardboard.Eye.Left ? LeftEyeOffset : RightEyeOffset;
  }

  // Minimum distance from the user that an object may be viewed in stereo
  // without eye strain, in meters.  The stereo eye separation should
  // be scaled down if the "center of interest" is closer than this.  This
  // will set a lower limit on the disparity of the COI between the two eyes.
  // See CardboardEye.OnPreCull().
  public float MinimumComfortDistance {
      get {
          return 1.0f;
      }
  }

  // Maximum distance from the user that an object may be viewed in
  // stereo without eye strain, in meters.  The stereo eye separation
  // should be scaled up of if the COI is farther than this.  This will
  // set an upper limit on the disparity of the COI between the two eyes.
  // See CardboardEye.OnPreCull().
  // Note: For HMDs with optics that focus at infinity there really isn't a
  // maximum distance, so this number can be set to "really really big".
  public float MaximumComfortDistance {
      get {
          return 100000f;  // i.e. really really big.
      }
  }

  public float IPD {
      get { return NOMINAL_IPD; }
  }

#if UNITY_IPHONE && !UNITY_EDITOR
//	[DllImport("__Internal")]
//	private static extern void _initFromUnity(string unityObjectName);
	[DllImport("__Internal")]
	private static extern float[] _unity_getFrameParameters(float[] frameParams, float near, float far);
//	[DllImport("__Internal")]
//	private static extern void convertTapIntoTrigger(bool enabled);
	[DllImport("RenderingPlugin")]
	private static extern void InitFromUnity(int textureID);  
#else
      [DllImport("RenderingPlugin")]
	private static extern void InitFromUnity(int textureID);  

#endif


#if ANDROID_DEVICE
  private const string cardboardClass =
      "com.google.vrtoolkit.cardboard.plugins.unity.UnityCardboardActivity";
  private AndroidJavaObject cardboardActivity;
#elif IOS_DEVICE
	//TODO: PORT THIS CODE
	/*
	private const string cardboardClass =
		"com.google.vrtoolkit.cardboard.plugins.unity.UnityCardboardActivity";
	private AndroidJavaObject cardboardActivity;
	*/
#endif

  // Only call native layer once per frame.
  private bool updated = false;

  // Head and eye transforms retrieved from native SDK.
  private Matrix4x4 headView;
  private Matrix4x4 leftEyeView;
  private Matrix4x4 leftEyeProj;
  private Matrix4x4 rightEyeView;
  private Matrix4x4 rightEyeProj;

  // Configures which Cardboard features are enabled, depending on
  // the Unity features available.
  private class Config {
      // Features.
      public bool supportsRenderTextures;
      public bool isAndroid;
      public bool supportsAndroidRenderEvent;
      public bool isAtLeastUnity4_5;

      // Access to plugin.
      public bool canAccessActivity = false;

      // Should be called on main thread.
      public void initialize() {
          supportsRenderTextures = SystemInfo.supportsRenderTextures;
          isAndroid = Application.platform == RuntimePlatform.Android;
          try {
              Regex r = new Regex(@"(\d+\.\d+)\..*");
              string version = r.Replace(Application.unityVersion, "$1");
              if (new Version(version) >= new Version("4.5")) {
                  isAtLeastUnity4_5 = true;
              }
          } catch {
              Debug.LogWarning("Unable to determine Unity version from: "
                      + Application.unityVersion);
          }
          supportsAndroidRenderEvent = isAtLeastUnity4_5 && isAndroid;
      }

      public bool canApplyDistortionCorrection() {
          return supportsRenderTextures && supportsAndroidRenderEvent
              && canAccessActivity;
      }

      public string getDistortionCorrectionDiagnostic() {
          List<string> causes = new List<string>();
          if (!isAndroid) {
              causes.Add("Must be running on Android device");
          } else if (!canAccessActivity) {
              causes.Add("Cannot access UnityCardboardActivity. "
                      + "Verify that the jar is in Assets/Plugins/Android");
          }
          if (!supportsRenderTextures) {
              causes.Add("RenderTexture (Unity Pro feature) is unavailable");
          }
          if (!isAtLeastUnity4_5) {
              causes.Add("Unity 4.5+ is needed for Android UnityPluginEvent");
          }
          return String.Join("; ", causes.ToArray());
      }
  }

  private Config config = new Config();

  void Awake() {
      if (sdk == null) {
          sdk = this;
      } else {
          Debug.LogWarning("Cardboard SDK object should be a singleton.");
          enabled = false;
      }

      config.initialize();

#if ANDROID_DEVICE
      try {
          AndroidJavaClass player = new AndroidJavaClass(cardboardClass);
          cardboardActivity = player.CallStatic<AndroidJavaObject>("getActivity");
          player.Dispose();
          cardboardActivity.Call("initFromUnity", gameObject.name);
          config.canAccessActivity = true;
      } catch (AndroidJavaException e) {
          Debug.LogError("Cannot access UnityCardboardActivity. "
                  + "Verify that the jar is in Assets/Plugins/Android. " + e);
      }
      // Force side-effectful initialization using serialized values.
      EnableAlignmentMarker = enableAlignmentMarker;
      EnableSettingsButton = enableSettingsButton;
      TapIsTrigger = tapIsTrigger;
#elif IOS_DEVICE
		//_initFromUnity(gameObject.name);
		config.canAccessActivity = true;
		EnableAlignmentMarker = enableAlignmentMarker;
		EnableSettingsButton = enableSettingsButton;
		TapIsTrigger = tapIsTrigger;

#endif

#if IOS_DEVICE
	  Debug.Log("Creating new cardboard screen texture");
	  StereoScreen = new RenderTexture(Screen.width, Screen.height, 16,
	                                 RenderTextureFormat.RGB565);
	  StereoScreen.Create();
#else
      if (config.canApplyDistortionCorrection()) {
          Debug.Log("Creating new cardboard screen texture");
          StereoScreen = new RenderTexture(Screen.width, Screen.height, 16,
                                           RenderTextureFormat.RGB565);
          StereoScreen.Create();
          InitFromUnity(StereoScreen.GetNativeTextureID());
      } else {
          if (!Application.isEditor) {
            Debug.LogWarning("Lens distortion-correction disabled. Causes: ["
                             + config.getDistortionCorrectionDiagnostic() + "]");
          }
      }
#endif

      InCardboard = newInCardboard = false;
#if UNITY_EDITOR
      if (VRModeEnabled && Application.isPlaying) {
          SetInCardboard(true);
      }
#endif
      StartCoroutine("EndOfFrame");
  }

#if UNITY_EDITOR
  private const float TAP_TIME_LIMIT = 0.2f;
  private float touchStartTime = 0;

  void Update() {
      if (!InCardboard) {
          return;  // Only simulate trigger pull if there is a trigger to pull.
      }
      if (Input.GetMouseButtonDown(0)) {
          touchStartTime = Time.time;
      } else if (Input.GetMouseButtonUp(0)) {
          if (Time.time - touchStartTime <= TAP_TIME_LIMIT) {
              newCardboardTriggered = true;
          }
          touchStartTime = 0;
      }
  }
#endif

#if IOS_DEVICE
	// Right-handed to left-handed matrix converter.
	private static readonly Matrix4x4 flipZ = Matrix4x4.Scale(new Vector3(1, 1, -1));
	
	// Call the SDK (if needed) to get the current transforms for the frame.
	// This is public so any game script can do this if they need the values.
	public bool UpdateState() {
		if (updated) {
			return true;
		}
		
		float[] frameInfo = new float[80];

		
		// Pass nominal clip distances - will correct later for each camera.
		_unity_getFrameParameters(frameInfo, 1.0f, 1000.0f);
		
		// FIXME: Should not call getFrameParams() more than once.
		if (frameInfo == null) {
			return false;
		}
		
		// Extract the matrices (currently that's all we get back).
		int j = 0;
		//Debug.Log(frameInfo);
		for (int i = 0; i < 16; ++i, ++j) {
			headView[i] = frameInfo[j];
		}
		for (int i = 0; i < 16; ++i, ++j) {
			leftEyeView[i] = frameInfo[j];
		}
		for (int i = 0; i < 16; ++i, ++j) {
			leftEyeProj[i] = frameInfo[j];
		}
		for (int i = 0; i < 16; ++i, ++j) {
			rightEyeView[i] = frameInfo[j];
		}
		for (int i = 0; i < 16; ++i, ++j) {
			rightEyeProj[i] = frameInfo[j];
		}
		
		// Convert views to left-handed coordinates because Unity uses them
		// for Transforms, which is what we will update from the views.
		// Also invert because the incoming matrices go from camera space to
		// cardboard space, and we want the opposite.
		// Lastly, cancel out the head rotation from the eye views,
		// because we are applying that on a parent object.
		leftEyeView = flipZ * headView * leftEyeView.inverse * flipZ;
		rightEyeView = flipZ * headView * rightEyeView.inverse * flipZ;
		headView = flipZ * headView.inverse * flipZ;
		
		HeadRotation = Quaternion.LookRotation(headView.GetColumn(2),
		                                       headView.GetColumn(1));
		LeftEyeOffset = leftEyeView.GetColumn(3);
		RightEyeOffset = rightEyeView.GetColumn(3);
		
		updated = true;
		return true;
	}
#elif ANDROID_DEVICE
  // Right-handed to left-handed matrix converter.
  private static readonly Matrix4x4 flipZ = Matrix4x4.Scale(new Vector3(1, 1, -1));

  // Call the SDK (if needed) to get the current transforms for the frame.
  // This is public so any game script can do this if they need the values.
  public bool UpdateState() {
      if (updated) {
          return true;
      }

      float[] frameInfo = null;
      try {
          // Pass nominal clip distances - will correct later for each camera.
          frameInfo = cardboardActivity.Call<float[]>("getFrameParams",
                  1.0f /* near */,
                  1000.0f /* far */);
      } catch (AndroidJavaException e) {
          Debug.LogError("Exception: " + e);
      }

      // FIXME: Should not call getFrameParams() more than once.
      if (frameInfo == null) {
          return false;
      }

      // Extract the matrices (currently that's all we get back).
      int j = 0;
      for (int i = 0; i < 16; ++i, ++j) {
          headView[i] = frameInfo[j];
      }
      for (int i = 0; i < 16; ++i, ++j) {
          leftEyeView[i] = frameInfo[j];
      }
      for (int i = 0; i < 16; ++i, ++j) {
          leftEyeProj[i] = frameInfo[j];
      }
      for (int i = 0; i < 16; ++i, ++j) {
          rightEyeView[i] = frameInfo[j];
      }
      for (int i = 0; i < 16; ++i, ++j) {
          rightEyeProj[i] = frameInfo[j];
      }

      // Convert views to left-handed coordinates because Unity uses them
      // for Transforms, which is what we will update from the views.
      // Also invert because the incoming matrices go from camera space to
      // cardboard space, and we want the opposite.
      // Lastly, cancel out the head rotation from the eye views,
      // because we are applying that on a parent object.
      leftEyeView = flipZ * headView * leftEyeView.inverse * flipZ;
      rightEyeView = flipZ * headView * rightEyeView.inverse * flipZ;
      headView = flipZ * headView.inverse * flipZ;

      HeadRotation = Quaternion.LookRotation(headView.GetColumn(2),
              headView.GetColumn(1));
      LeftEyeOffset = leftEyeView.GetColumn(3);
      RightEyeOffset = rightEyeView.GetColumn(3);

      updated = true;
      return true;
  }
#else
  private float mockFieldOfView = 77.0f; // Vertical degrees.
  private float zeroParallaxDistance = 0.308f; // Meters in real world.

#if UNITY_EDITOR
  [Tooltip("When playing in the editor, just release Ctrl to untilt the head.")]
      public bool autoUntiltHead = true;

  // Use mouse to emulate head in the editor.
  private float mouseX = 0;
  private float mouseY = 0;
  private float mouseZ = 0;
#endif

  // Mock implementation for use in the Unity editor.
  public bool UpdateState() {
      if (updated) {
          return true;
      }

      // NOTE: View matrices have to be camera->world and use left-handed
      // coordinates (+Z is forward).  See the flip/invert/flip code
      // in the Android version of this function.

      headView = Matrix4x4.identity;

#if UNITY_EDITOR
      bool rolled = false;
      if (Input.GetKey(KeyCode.LeftAlt) || Input.GetKey(KeyCode.RightAlt)) {
          mouseX += Input.GetAxis("Mouse X") * 5;
          if (mouseX <= -180) {
              mouseX += 360;
          } else if (mouseX > 180)
              mouseX -= 360;
          mouseY -= Input.GetAxis("Mouse Y") * 2.4f;
          mouseY = Mathf.Clamp(mouseY, -80, 80);
      } else if (Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.RightControl)) {
          rolled = true;
          mouseZ += Input.GetAxis("Mouse X") * 5;
          mouseZ = Mathf.Clamp(mouseZ, -80, 80);
      }
      if (!rolled && autoUntiltHead) {
          // People don't usually leave their heads tilted to one side for long.
          mouseZ = Mathf.Lerp(mouseZ, 0, Time.deltaTime / (Time.deltaTime + 0.1f));
      }
      var rot = Quaternion.Euler(mouseY, mouseX, mouseZ);
      headView = Matrix4x4.TRS(Vector3.zero, rot, Vector3.one);
#endif

      float eyeoffset = -IPD / 2;

      leftEyeView = Matrix4x4.identity;
      leftEyeView[0, 3] = eyeoffset;

      leftEyeProj = Matrix4x4.Perspective(mockFieldOfView,
              0.5f * Screen.width / Screen.height,
              1.0f, 1000.0f);
      leftEyeProj[0, 2] = eyeoffset / zeroParallaxDistance * leftEyeProj[0, 0];

      // Right matrices same as left ones but for some sign flippage.
      rightEyeView = leftEyeView;
      rightEyeView[0, 3] *= -1;
      rightEyeProj = leftEyeProj;
      rightEyeProj[0, 2] *= -1;

      HeadRotation = Quaternion.LookRotation(headView.GetColumn(2),
              headView.GetColumn(1));
      LeftEyeOffset = leftEyeView.GetColumn(3);
      RightEyeOffset = rightEyeView.GetColumn(3);

      updated = true;
      return true;
  }
#endif

#if ANDROID_DEVICE
  // How long to hold a simulated screen tap.
  private const float TAP_INJECTION_TIME = 0.1f;

  private const long NO_DOWNTIME = -1;  // Sentinel for when down time is not set.

  private long downTime = NO_DOWNTIME;  // Time the current tap injection started, if any.

  // Fakes a screen tap by injecting a pointer-down and pointer-up events
  // with a suitable delay between them.
  IEnumerator DoAndroidScreenTap(int x, int y) {
      if (downTime != NO_DOWNTIME) {  // Sanity check.
        yield break;
      }
      try {
          downTime = cardboardActivity.Call<long>("injectTouchDown", x, y);
      } catch (AndroidJavaException e) {
          Debug.LogError("Failed to inject touch down: " + e);
          yield break;
      }
      yield return new WaitForSeconds(TAP_INJECTION_TIME);
      try {
          cardboardActivity.Call("injectTouchUp", x, y, downTime);
      } catch (AndroidJavaException e) {
          Debug.LogError("Failed to inject touch up: " + e);
      }
      downTime = NO_DOWNTIME;
  }
#elif IOS_DEVICE
	// How long to hold a simulated screen tap.
	private const float TAP_INJECTION_TIME = 0.1f;

	private const long NO_DOWNTIME = -1;  // Sentinel for when down time is not set.

	private long downTime = NO_DOWNTIME;  // Time the current tap injection started, if any.

	// Fakes a screen tap by injecting a pointer-down and pointer-up events
	// with a suitable delay between them.
	IEnumerator DoIOSScreenTap(int x, int y) {
		if (downTime != NO_DOWNTIME) {  // Sanity check.
			yield break;
		}
		/*
		try {
			//TODO: PORT THIS CODE
			downTime = cardboardActivity.Call<long>("injectTouchDown", x, y);
		} catch (AndroidJavaException e) {
			Debug.LogError("Failed to inject touch down: " + e);
			yield break;
		}
		yield return new WaitForSeconds(TAP_INJECTION_TIME);
		try {
			cardboardActivity.Call("injectTouchUp", x, y, downTime);
		} catch (AndroidJavaException e) {
			Debug.LogError("Failed to inject touch up: " + e);
		}
		*/
		downTime = NO_DOWNTIME;
	}
#endif

  // Makes Unity see a mouse click (down + up) at the given pixel.
  public void InjectMouseClick(int x, int y) {
#if ANDROID_DEVICE
      if (downTime == NO_DOWNTIME) {  // If not in the middle of a tap injection.
          StartCoroutine(DoAndroidScreenTap(x, y));
      }
#elif IOS_DEVICE
		if (downTime == NO_DOWNTIME) {  // If not in the middle of a tap injection.
			StartCoroutine(DoIOSScreenTap(x, y));
		}
#endif
  }

  // Makes Unity see a mouse move to the given pixel.
  public void InjectMouseMove(int x, int y) {
      if (x == (int)Input.mousePosition.x && y == (int)Input.mousePosition.y) {
          return;  // Don't send a 0-pixel move.
      }
#if ANDROID_DEVICE
      if (downTime == NO_DOWNTIME) {  // If not in the middle of a tap injection.
          try {
              cardboardActivity.Call("injectMouseMove", x, y);
          } catch (AndroidJavaException e) {
              Debug.LogError("Failed to inject mouse move: " + e);
          }
      }
#elif IOS_DEVICE
		//TODO: PORT THIS CODE
		if (downTime == NO_DOWNTIME) {  // If not in the middle of a tap injection.
			/*
			try {
				cardboardActivity.Call("injectMouseMove", x, y);
			} catch (AndroidJavaException e) {
				Debug.LogError("Failed to inject mouse move: " + e);
			}
			*/
		}
#endif
  }

  void OnInsertedIntoCardboardInternal() {
      newInCardboard = true;
  }

  void OnRemovedFromCardboardInternal() {
      newInCardboard = false;
  }

  void OnCardboardTriggerInternal() {
      newCardboardTriggered = true;
  }

  void OnDestroy() {
      StopCoroutine("EndOfFrame");
      if (sdk == this) {
          sdk = null;
      }
  }

  IEnumerator EndOfFrame() {
      while (true) {
          yield return new WaitForEndOfFrame();
          if (vrModeEnabled && StereoScreen != null && UpdateState()) {
              GL.InvalidateState();  // necessary for Windows, but not Mac.
              GL.IssuePluginEvent(1);
          }
          InCardboard = newInCardboard;
          CardboardTriggered = newCardboardTriggered;
          newCardboardTriggered = false;
          updated = false;
      }
  }

#if !UNITY_EDITOR
  private GUIStyle style;

  // The amount of time (in seconds) to show error message on GUI.
  private const float GUI_ERROR_MSG_DURATION = 10;

  private const string warning =
      @"Distortion correction is disabled.
      Requires Unity Android Pro v4.5+.
      See log for details.";

  void OnGUI() {
      if (Debug.isDebugBuild && !config.canApplyDistortionCorrection() &&
              Time.realtimeSinceStartup <= GUI_ERROR_MSG_DURATION) {
          DisplayDistortionCorrectionDisabledWarning();
      }
  }

  private void DisplayDistortionCorrectionDisabledWarning() {
      if (style == null) {
          style = new GUIStyle();
          style.normal.textColor = Color.red;
          style.alignment = TextAnchor.LowerCenter;
      }
      if (VRModeEnabled) {
          style.fontSize = (int)(50 * Screen.width / 1920f / 2);
          GUI.Label(new Rect(0, 0, Screen.width / 2, Screen.height), warning, style);
          GUI.Label(new Rect(Screen.width / 2, 0, Screen.width / 2, Screen.height), warning, style);
      } else {
          style.fontSize = (int)(50 * Screen.width / 1920f);
          GUI.Label(new Rect(0, 0, Screen.width, Screen.height), warning, style);
      }
  }
#endif
}
