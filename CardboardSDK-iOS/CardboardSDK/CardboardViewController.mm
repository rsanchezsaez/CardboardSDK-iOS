//
//  CardboardViewController.mm
//  CardboardSDK-iOS
//

#import "CardboardViewController.h"

#include "CardboardDeviceParams.h"
#include "Distortion.h"
#include "DistortionRenderer.h"
#include "Eye.h"
#include "FieldOfView.h"
#include "HeadTracker.h"
#include "HeadTransform.h"
#include "HeadMountedDisplay.h"
#include "MagnetSensor.h"
#include "ScreenParams.h"
#include "Viewport.h"

#include "DebugUtils.h"
#include "GLHelpers.h"


@interface EyeWrapper ()

@property (nonatomic) Eye *eye;

- (instancetype)initWithEye:(Eye *)eye;

@end


@implementation EyeWrapper

- (instancetype)init
{
    return [self initWithEye:nullptr];
}

- (instancetype)initWithEye:(Eye *)eye
{
    self = [super init];
    if (!self) { return nil; }
    
    _eye = eye;
    
    return self;
}

- (GLKMatrix4)eyeViewMatrix
{
    if (_eye != nullptr)
    {
        return _eye->eyeView();
    }
    return GLKMatrix4Identity;
}

- (GLKMatrix4)perspectiveMatrixWithZNear:(float)zNear
                                    zFar:(float)zFar
{
    if (_eye != nullptr)
    {
        return _eye->perspective(zNear, zFar);
    }
    return GLKMatrix4Identity;
}

@end


@interface StereoRenderer : NSObject

@property (nonatomic) id <StereoRendererDelegate> stereoRendererDelegate;
@property (nonatomic) BOOL VRModeEnabled;

@property (nonatomic) EyeWrapper *leftEyeWrapper;
@property (nonatomic) EyeWrapper *rightEyeWrapper;

@end


@implementation StereoRenderer

- (void)setupRendererWithView:(GLKView *)GLView
{
    _leftEyeWrapper = [EyeWrapper new];
    _rightEyeWrapper = [EyeWrapper new];
    [self.stereoRendererDelegate setupRendererWithView:GLView];
}

- (void)shutdownRendererWithView:(GLKView *)GLView
{
    [self.stereoRendererDelegate shutdownRendererWithView:GLView];
}

- (void)updateRenderViewSize:(CGSize)size
{
    if (self.VRModeEnabled)
    {
        [self.stereoRendererDelegate renderViewDidChangeSize:CGSizeMake(size.width / 2, size.height)];
    }
    else
    {
        [self.stereoRendererDelegate renderViewDidChangeSize:CGSizeMake(size.width, size.height)];
    }
}

- (void)drawFrameWithHeadTransform:(HeadTransform *)headTransform leftEye:(Eye *)leftEye rightEye:(Eye *)rightEye
{
    GLCheckForError();
 
    // NSLog(@"%@", NSStringFromGLKMatrix4(leftEyeParams->transform()->eyeView()));

    [self.stereoRendererDelegate prepareNewFrameWithHeadViewMatrix:headTransform->headView()];
    
    GLCheckForError();
    
    glEnable(GL_SCISSOR_TEST);
    leftEye->viewport()->setGLViewport();
    leftEye->viewport()->setGLScissor();
    
    GLCheckForError();
    
    _leftEyeWrapper.eye = leftEye;
    [self.stereoRendererDelegate drawEyeWithEye:_leftEyeWrapper];

    GLCheckForError();

    if (rightEye == nullptr) { return; }

    rightEye->viewport()->setGLViewport();
    rightEye->viewport()->setGLScissor();

    GLCheckForError();
    
    _rightEyeWrapper.eye = rightEye;
    [self.stereoRendererDelegate drawEyeWithEye:_rightEyeWrapper];

    GLCheckForError();
}

- (void)finishFrameWithViewPort:(Viewport *)viewport
{
    viewport->setGLViewport();
    viewport->setGLScissor();
    [self.stereoRendererDelegate finishFrameWithViewportRect:viewport->toCGRect()];
}

@end


@interface CardboardViewController () <GLKViewControllerDelegate>

@property (nonatomic) GLKView *view;

@property (nonatomic, assign) MagnetSensor *magnetSensor;
@property (nonatomic, assign) HeadTracker *headTracker;
@property (nonatomic, assign) HeadTransform *headTransform;
@property (nonatomic, assign) HeadMountedDisplay *headMountedDisplay;

@property (nonatomic, assign) Eye *monocularEye;
@property (nonatomic, assign) Eye *leftEye;
@property (nonatomic, assign) Eye *rightEye;

@property (nonatomic, assign) DistortionRenderer *distortionRenderer;

@property (nonatomic, assign) float distortionCorrectionScale;

@property (nonatomic, assign) float zNear;
@property (nonatomic, assign) float zFar;

@property (nonatomic, assign) BOOL projectionChanged;

@property (nonatomic, strong) StereoRenderer *stereoRenderer;

@property (nonatomic, assign) UIDeviceOrientation currentOrientation;

@end


@implementation CardboardViewController

- (id)init
{
    self = [super init];
    if (!self) { return nil; }
    
    // Do not allow the display going into sleep
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    self.delegate = self;

    self.magnetSensor = new MagnetSensor();
    self.headTracker = new HeadTracker();
    self.headTransform = new HeadTransform();
    self.headMountedDisplay = new HeadMountedDisplay([UIScreen mainScreen]);
    
    self.monocularEye = new Eye(Eye::TypeMonocular);
    self.leftEye = new Eye(Eye::TypeLeft);
    self.rightEye = new Eye(Eye::TypeRight);

    self.distortionRenderer = new DistortionRenderer();
    
    self.stereoRenderer = [StereoRenderer new];
    self.distortionCorrectionScale = 1.0f;

    self.VRModeEnabled = YES;
    self.distortionCorrectionEnabled = YES;

    self.zNear = 0.1f;
    self.zFar = 100.0f;

    self.projectionChanged = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(magneticTriggerPressed:)
                                                 name:CBTriggerPressedNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];

    return self;
}

- (void)orientationDidChange:(NSNotification *)notification
{
    UIDeviceOrientation newOrientation = [UIDevice currentDevice].orientation;
    if (newOrientation != self.currentOrientation
        && (newOrientation == UIDeviceOrientationLandscapeRight
            || newOrientation == UIDeviceOrientationLandscapeLeft))
    {
        self.currentOrientation = newOrientation;
        _headTracker->updateDeviceOrientation(newOrientation);
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.preferredFramesPerSecond = 60;
    self.view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.view.context)
    {
        NSLog(@"Failed to create OpenGL ES 2.0 context");
    }
    self.view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
    [self.stereoRenderer setupRendererWithView:self.view];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.stereoRendererDelegate shutdownRendererWithView:self.view];

    if (self.magnetSensor != nullptr) { delete self.magnetSensor; }
    if (self.headTracker != nullptr) { delete self.headTracker; }
    if (self.headTransform != nullptr) { delete self.headTransform; }
    if (self.headMountedDisplay != nullptr) { delete self.headMountedDisplay; }
   
    if (self.monocularEye != nullptr) { delete self.monocularEye; }
    if (self.leftEye != nullptr) { delete self.leftEye; }
    if (self.rightEye != nullptr) { delete self.rightEye; }

    if (self.distortionRenderer != nullptr) { delete self.distortionRenderer; }
}

- (id<StereoRendererDelegate>)stereoRendererDelegate
{
    return self.stereoRenderer.stereoRendererDelegate;
}

- (void)setStereoRendererDelegate:(id<StereoRendererDelegate>)stereoRenderer
{
    self.stereoRenderer.stereoRendererDelegate = stereoRenderer;
}

- (BOOL)VRModeEnabled
{
    return self.stereoRenderer.VRModeEnabled;
}

- (void)setVRModeEnabled:(BOOL)VRModeEnabled
{
    self.stereoRenderer.VRModeEnabled = VRModeEnabled;
}

- (BOOL)vignetteEnabled
{
    return self.distortionRenderer->vignetteEnabled();
}

- (void)setVignetteEnabled:(BOOL)vignetteEnabled
{
    self.distortionRenderer->setVignetteEnabled(vignetteEnabled);
}

- (BOOL)chromaticAberrationCorrectionEnabled
{
    return self.distortionRenderer->chromaticAberrationEnabled();
}

- (void)setChromaticAberrationCorrectionEnabled:(BOOL)chromaticAberrationCorrectionEnabled
{
    self.distortionRenderer->setChromaticAberrationEnabled(chromaticAberrationCorrectionEnabled);
}

- (BOOL)restoreGLStateEnabled
{
    return self.distortionRenderer->restoreGLStateEnabled();
}

- (void)setRestoreGLStateEnabled:(BOOL)restoreGLStateEnabled
{
    self.distortionRenderer->setRestoreGLStateEnabled(restoreGLStateEnabled);
}

- (BOOL)neckModelEnabled
{
    return self.headTracker->neckModelEnabled();
}

- (void)setNeckModelEnabled:(BOOL)neckModelEnabled
{
    self.headTracker->setNeckModelEnabled(neckModelEnabled);
}

- (void)magneticTriggerPressed:(NSNotification *)notification
{
    if ([self.stereoRendererDelegate respondsToSelector:@selector(magneticTriggerPressed)])
    {
        [self.stereoRendererDelegate magneticTriggerPressed];
    }
}

- (void)glkViewController:(GLKViewController *)controller willPause:(BOOL)pause
{
    if (pause)
    {
        self.headTracker->stopTracking();
        self.magnetSensor->stop();
    }
    else
    {
        self.headTracker->startTracking();
        self.magnetSensor->start();
    }
}

- (void)glkViewControllerUpdate:(GLKViewController *)controller
{
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // glInsertEventMarkerEXT(0, "com.apple.GPUTools.event.debug-frame");

    GLCheckForError();
    
    [self calculateFrameParametersWithHeadTransform:_headTransform leftEye:_leftEye rightEye:_rightEye monocularEye:_monocularEye];
    
    if (self.VRModeEnabled)
    {
        if (_distortionCorrectionEnabled)
        {
            _distortionRenderer->beforeDrawFrame();
            
            [_stereoRenderer drawFrameWithHeadTransform:_headTransform
                                                leftEye:_leftEye
                                               rightEye:_rightEye];
            
            GLCheckForError();

            // Rebind original framebuffer
            [self.view bindDrawable];
            _distortionRenderer->afterDrawFrame();
            
            GLCheckForError();
        }
        else
        {
            [_stereoRenderer drawFrameWithHeadTransform:_headTransform
                                                leftEye:_leftEye
                                               rightEye:_rightEye];
        }
    }
    else
    {
        [_stereoRenderer drawFrameWithHeadTransform:_headTransform
                                            leftEye:_monocularEye
                                           rightEye:nullptr];
    }
    
    [_stereoRenderer finishFrameWithViewPort:_monocularEye->viewport()];
    
    GLCheckForError();
}

- (void)calculateFrameParametersWithHeadTransform:(HeadTransform *)headTransform
                                          leftEye:(Eye *)leftEye
                                         rightEye:(Eye *)rightEye
                                     monocularEye:(Eye *)monocularEye
{
    CardboardDeviceParams *cardboardDeviceParams = _headMountedDisplay->getCardboard();
    
    headTransform->setHeadView(_headTracker->lastHeadView());
    float halfInterLensDistance = cardboardDeviceParams->interLensDistance() * 0.5f;
    
    // NSLog(@"%@", NSStringFromGLKMatrix4(_headTracker->lastHeadView()));
    
    if (self.VRModeEnabled)
    {
        GLKMatrix4 leftEyeTranslate = GLKMatrix4Identity;
        GLKMatrix4 rightEyeTranslate = GLKMatrix4Identity;
        
        GLKMatrix4Translate(leftEyeTranslate, halfInterLensDistance, 0, 0);
        GLKMatrix4Translate(rightEyeTranslate, -halfInterLensDistance, 0, 0);
        
        leftEye->setEyeView( GLKMatrix4Multiply(leftEyeTranslate, headTransform->headView()));
        rightEye->setEyeView( GLKMatrix4Multiply(rightEyeTranslate, headTransform->headView()));
    }
    else
    {
        monocularEye->setEyeView(headTransform->headView());
    }
    
    if (_projectionChanged)
    {
        ScreenParams *screenParams = _headMountedDisplay->getScreen();
        monocularEye->viewport()->setViewport(0, 0, screenParams->width(), screenParams->height());
        
        if (!self.VRModeEnabled)
        {
            [self updateMonocularFov:monocularEye->fov()];
        }
        else if (_distortionCorrectionEnabled)
        {
            [self updateFovsWithLeftEyeFov:leftEye->fov() rightEyeFov:rightEye->fov()];
            _distortionRenderer->fovDidChange(_headMountedDisplay, leftEye->fov(), rightEye->fov(), [self virtualEyeToScreenDistance]);
        }
        else
        {
            [self updateUndistortedFOVAndViewport];
        }
        leftEye->setProjectionChanged();
        rightEye->setProjectionChanged();
        monocularEye->setProjectionChanged();
        _projectionChanged = NO;
    }
    
    if (self.distortionCorrectionEnabled && _distortionRenderer->viewportsChanged())
    {
        _distortionRenderer->updateViewports(leftEye->viewport(), rightEye->viewport());
    }
}

- (void)updateMonocularFov:(FieldOfView *)monocularFov
{
    ScreenParams *screenParams = _headMountedDisplay->getScreen();
    const float monocularBottomFov = 22.5f;
    const float monocularLeftFov = GLKMathRadiansToDegrees(
                                                           atanf(
                                                                 tanf(GLKMathDegreesToRadians(monocularBottomFov))
                                                                 * screenParams->widthInMeters()
                                                                 / screenParams->heightInMeters()));
    monocularFov->setLeft(monocularLeftFov);
    monocularFov->setRight(monocularLeftFov);
    monocularFov->setBottom(monocularBottomFov);
    monocularFov->setTop(monocularBottomFov);
}

- (void)updateFovsWithLeftEyeFov:(FieldOfView *)leftEyeFov rightEyeFov:(FieldOfView *)rightEyeFov
{
    CardboardDeviceParams *cardboardDeviceParams = _headMountedDisplay->getCardboard();
    ScreenParams *screenParams = _headMountedDisplay->getScreen();
    Distortion *distortion = cardboardDeviceParams->distortion();
    float eyeToScreenDistance = [self virtualEyeToScreenDistance];
    
    float outerDistance = (screenParams->widthInMeters() - cardboardDeviceParams->interLensDistance() ) / 2.0f;
    float innerDistance = cardboardDeviceParams->interLensDistance() / 2.0f;
    float bottomDistance = cardboardDeviceParams->verticalDistanceToLensCenter() - screenParams->borderSizeInMeters();
    float topDistance = screenParams->heightInMeters() + screenParams->borderSizeInMeters() - cardboardDeviceParams->verticalDistanceToLensCenter();
    
    float outerAngle = GLKMathRadiansToDegrees(atanf(distortion->distort(outerDistance / eyeToScreenDistance)));
    float innerAngle = GLKMathRadiansToDegrees(atanf(distortion->distort(innerDistance / eyeToScreenDistance)));
    float bottomAngle = GLKMathRadiansToDegrees(atanf(distortion->distort(bottomDistance / eyeToScreenDistance)));
    float topAngle = GLKMathRadiansToDegrees(atanf(distortion->distort(topDistance / eyeToScreenDistance)));
    
    leftEyeFov->setLeft(MIN(outerAngle, cardboardDeviceParams->maximumLeftEyeFOV()->left()));
    leftEyeFov->setRight(MIN(innerAngle, cardboardDeviceParams->maximumLeftEyeFOV()->right()));
    leftEyeFov->setBottom(MIN(bottomAngle, cardboardDeviceParams->maximumLeftEyeFOV()->bottom()));
    leftEyeFov->setTop(MIN(topAngle, cardboardDeviceParams->maximumLeftEyeFOV()->top()));
    
    rightEyeFov->setLeft(leftEyeFov->right());
    rightEyeFov->setRight(leftEyeFov->left());
    rightEyeFov->setBottom(leftEyeFov->bottom());
    rightEyeFov->setTop(leftEyeFov->top());
}

- (void)updateUndistortedFOVAndViewport
{
    CardboardDeviceParams *cardboardDeviceParams = _headMountedDisplay->getCardboard();
    ScreenParams *screenParams = _headMountedDisplay->getScreen();

    float halfInterLensDistance = cardboardDeviceParams->interLensDistance() * 0.5f;
    float eyeToScreenDistance = [self virtualEyeToScreenDistance];
    
    float left = screenParams->widthInMeters() / 2.0f - halfInterLensDistance;
    float right = halfInterLensDistance;
    float bottom = cardboardDeviceParams->verticalDistanceToLensCenter() - screenParams->borderSizeInMeters();
    float top = screenParams->borderSizeInMeters() + screenParams->heightInMeters() - cardboardDeviceParams->verticalDistanceToLensCenter();
    
    FieldOfView *leftEyeFov = _leftEye->fov();
    leftEyeFov->setLeft(GLKMathRadiansToDegrees(atan2f(left, eyeToScreenDistance)));
    leftEyeFov->setRight(GLKMathRadiansToDegrees(atan2f(right, eyeToScreenDistance)));
    leftEyeFov->setBottom(GLKMathRadiansToDegrees(atan2f(bottom, eyeToScreenDistance)));
    leftEyeFov->setTop(GLKMathRadiansToDegrees(atan2f(top, eyeToScreenDistance)));
    
    FieldOfView *rightEyeFov = _rightEye->fov();
    rightEyeFov->setLeft(leftEyeFov->right());
    rightEyeFov->setRight(leftEyeFov->left());
    rightEyeFov->setBottom(leftEyeFov->bottom());
    rightEyeFov->setTop(leftEyeFov->top());
    
    _leftEye->viewport()->setViewport(0, 0, screenParams->width() / 2, screenParams->height());
    _rightEye->viewport()->setViewport(screenParams->width() / 2, 0, screenParams->width() / 2, screenParams->height());
}

- (float)virtualEyeToScreenDistance
{
    return _headMountedDisplay->getCardboard()->screenToLensDistance();
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.stereoRenderer updateRenderViewSize:self.view.bounds.size];
}

@end
