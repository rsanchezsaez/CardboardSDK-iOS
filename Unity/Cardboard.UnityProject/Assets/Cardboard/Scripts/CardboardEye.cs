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

using UnityEngine;
using System.Reflection;

// Controls one camera of a stereo pair.  Each frame, it mirrors the settings of
// the parent mono Camera, and then sets up side-by-side stereo with an appropriate
// projection based on the head-tracking data from the Cardboard.SDK object.
// To enable a stereo camera pair, enable the parent mono camera and set
// Cardboard.SDK.VRModeEnabled = true.
[RequireComponent(typeof(Camera))]
public class CardboardEye : MonoBehaviour {
  // Whether this is the left eye or the right eye.
  public Cardboard.Eye eye;

  // The stereo controller in charge of this eye (and whose mono camera
  // we will copy settings from).
  private StereoController controller;
  public StereoController Controller {
    // This property is set up to work both in editor and in player.
    get {
      if (transform.parent == null) { // Should not happen.
        return null;
      }
      if ((Application.isEditor && !Application.isPlaying)
          || controller == null) {
        // Go find our controller.
        return transform.parent.GetComponentInParent<StereoController>();
      }
      return controller;
    }
  }

  public CardboardHead Head {
    get {
      return GetComponentInParent<CardboardHead>();
    }
  }

  void Start() {
    var ctlr = Controller;
    if (ctlr == null) {
      Debug.LogError("CardboardEye must be child of a StereoController.");
      enabled = false;
    }
    // Save reference to the found controller.
    controller = ctlr;
  }

  public void Render() {
    // Shouldn't happen because of the check in Start(), but just in case...
    if (controller == null) {
      return;
    }

    var camera = GetComponent<Camera>();
    var monoCamera = controller.GetComponent<Camera>();
    Matrix4x4 proj = Cardboard.SDK.Projection(eye);

    CopyCameraAndMakeSideBySide(controller, proj[0,2], proj[1,2]);

    // Calculate stereo adjustments based on the center of interest.
    float ipdScale;
    float eyeOffset;
    controller.ComputeStereoAdjustment(proj[1, 1], transform.lossyScale.z,
                                       out ipdScale, out eyeOffset);

    // Set up the eye's view transform.
    transform.localPosition = ipdScale * Cardboard.SDK.EyeOffset(eye) +
                              eyeOffset * Vector3.forward;

    // Set up the eye's projection.

    // Adjust for non-fullscreen camera.  Cardboard SDK assumes fullscreen,
    // so the aspect ratio might not match.
    proj[0, 0] *= camera.rect.height / camera.rect.width / 2;

    // Adjust for IPD scale.  This changes the vergence of the two frustums.
    Vector2 dir = transform.localPosition; // ignore Z
    dir = dir.normalized * ipdScale;
    proj[0, 2] *= Mathf.Abs(dir.x);
    proj[1, 2] *= Mathf.Abs(dir.y);

    // Cardboard had to pass "nominal" values of near/far to the SDK, which
    // we fix here to match our mono camera's specific values.
    float near = monoCamera.nearClipPlane;
    float far = monoCamera.farClipPlane;
    proj[2, 2] = (near + far) / (near - far);
    proj[2, 3] = 2 * near * far / (near - far);

    camera.projectionMatrix = proj;

    if (Application.isEditor) {
      // So you can see the approximate frustum in the Scene view when the camera is selected.
      camera.fieldOfView = 2 * Mathf.Atan(1 / proj[1, 1]) * Mathf.Rad2Deg;
    }

    RenderTexture stereoScreen = controller.StereoScreen;

    // Use the "fast" or "slow" method.  Fast means the camera draws right into one half of
    // the stereo screen.  Slow means it draws first to a side buffer, and then the buffer
    // is written to the screen. The slow method is provided because a lot of Image Effects
    // don't work if you draw to only part of the window.
    if (controller.directRender) {
      // Redirect to our stereo screen.
      camera.targetTexture = stereoScreen;
      // Draw!
      camera.Render();
    } else {
      // Save the viewport rectangle and reset to "full screen".
      Rect pixRect = camera.pixelRect;
      camera.rect = new Rect (0, 0, 1, 1);
      // Redirect to a temporary texture.  The defaults are supposedly Android-friendly.
      int depth = stereoScreen ? stereoScreen.depth : 16;
      RenderTextureFormat format = stereoScreen ? stereoScreen.format : RenderTextureFormat.RGB565;
      camera.targetTexture = RenderTexture.GetTemporary((int)pixRect.width, (int)pixRect.height,
                                                        depth, format);
      // Draw!
      camera.Render();
      // Blit the temp texture to the stereo screen.
      RenderTexture oldTarget = RenderTexture.active;
      RenderTexture.active = stereoScreen;
      GL.PushMatrix();
      GL.LoadPixelMatrix(0, stereoScreen ? stereoScreen.width : Screen.width,
                         stereoScreen ? stereoScreen.height : Screen.height, 0);
      Graphics.DrawTexture(pixRect, camera.targetTexture);
      // Clean up.
      GL.PopMatrix();
      RenderTexture.active = oldTarget;
      RenderTexture.ReleaseTemporary(camera.targetTexture);
      camera.targetTexture = null;
    }
  }

  // Helper to copy camera settings from the controller's mono camera.
  // Used in OnPreCull and the custom editor for StereoController.
  // The parameters parx and pary, if not left at default, should come from a
  // projection matrix returned by the SDK.
  // They affect the apparent depth of the camera's window.  See OnPreCull().
  public void CopyCameraAndMakeSideBySide(StereoController controller,
                                          float parx = 0, float pary = 0) {
    var camera = GetComponent<Camera>();

    // Sync the camera properties.
    camera.CopyFrom(controller.GetComponent<Camera>());

    // Reset transform, which was clobbered by the CopyFrom() call.
    // Since we are a child of the mono camera, we inherit its
    // transform already.
    // Use nominal IPD for the editor.  During play, OnPreCull() will
    // compute a real value.
    float ipd = Cardboard.NOMINAL_IPD * controller.stereoMultiplier;
    transform.localPosition = (eye == Cardboard.Eye.Left ? -ipd/2 : ipd/2) * Vector3.right;
    transform.localRotation = Quaternion.identity;
    transform.localScale = Vector3.one;

    // Set up side-by-side stereo.
    // Note: The code is written this way so that non-fullscreen cameras
    // (PIP: picture-in-picture) still work in stereo.  Even if the PIP's content is
    // not going to be in stereo, the PIP itself still has to be rendered in both eyes.
    Rect rect = camera.rect;

    // Move away from edges if padding requested.  Some HMDs make the edges of the
    // screen a bit hard to see.
    Vector2 center = rect.center;
    center.x = Mathf.Lerp(center.x, 0.5f, Mathf.Clamp01(controller.stereoPaddingX));
    center.y = Mathf.Lerp(center.y, 0.5f, Mathf.Clamp01(controller.stereoPaddingY));
    rect.center = center;

    // Semi-hacky aspect ratio adjustment because the screen is only half as wide due
    // to side-by-side stereo, to make sure the PIP width fits.
    float width = Mathf.SmoothStep(-0.5f, 0.5f, (rect.width + 1) / 2);
    rect.x += (rect.width - width) / 2;
    rect.width = width;

    // Divide the outside region of window proportionally in each half of the screen.
    rect.x *= (0.5f - rect.width) / (1 - rect.width);
    if (eye == Cardboard.Eye.Right) {
      rect.x += 0.5f; // Move to right half of the screen.
    }

    // Adjust the window for requested parallax.  This affects the apparent depth of the
    // window in the main camera's screen.  Useful for PIP windows only, where rect.width < 1.
    float parallax = Mathf.Clamp01(controller.screenParallax);
    if (controller.GetComponent<Camera>().rect.width < 1 && parallax > 0) {
      // Note: parx and pary are signed, with opposite signs in each eye.
      rect.x -= parx / 4 * parallax; // Extra factor of 1/2 because of side-by-side stereo.
      rect.y -= pary / 2 * parallax;
    }

    camera.rect = rect;
  }
}
