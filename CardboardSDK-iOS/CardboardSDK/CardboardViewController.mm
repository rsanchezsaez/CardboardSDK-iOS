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

- (EyeType)type
{
    EyeType type = EyeTypeMonocular;
    if (_eye->type() == Eye::TypeLeft)
    {
        type = EyeTypeLeft;
    }
    else if (_eye->type() == Eye::TypeRight)
    {
        type = EyeTypeRight;
    }
    return type;
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


@interface CardboardViewController () <GLKViewControllerDelegate>
{
    MagnetSensor *_magnetSensor;
    HeadTracker *_headTracker;
    HeadTransform *_headTransform;
    HeadMountedDisplay *_headMountedDisplay;
    
    Eye *_monocularEye;
    Eye *_leftEye;
    Eye *_rightEye;
    
    DistortionRenderer *_distortionRenderer;
    
    float _distortionCorrectionScale;
    
    float _zNear;
    float _zFar;
    
    BOOL _projectionChanged;
    
    BOOL _frameParamentersReady;
}

@property (nonatomic) NSLock *glLock;

@property (nonatomic) EyeWrapper *leftEyeWrapper;
@property (nonatomic) EyeWrapper *rightEyeWrapper;

@end


@implementation CardboardViewController

- (id)init
{
    self = [super init];
    if (!self) { return nil; }
    
    // Do not allow the display to go into sleep
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    self.delegate = self;

    _magnetSensor = new MagnetSensor();
    _headTracker = new HeadTracker();
    _headTransform = new HeadTransform();
    _headMountedDisplay = new HeadMountedDisplay([UIScreen mainScreen]);
    
    _monocularEye = new Eye(Eye::TypeMonocular);
    _leftEye = new Eye(Eye::TypeLeft);
    _rightEye = new Eye(Eye::TypeRight);

    _distortionRenderer = new DistortionRenderer();
    
    _distortionCorrectionScale = 1.0f;

    _vrModeEnabled = YES;
    _distortionCorrectionEnabled = YES;

    _zNear = 0.1f;
    _zFar = 100.0f;

    _projectionChanged = YES;

    _frameParamentersReady = NO;

    self.leftEyeWrapper = [EyeWrapper new];
    self.rightEyeWrapper = [EyeWrapper new];

    self.glLock = [NSLock new];
    
    _headTracker->startTracking([UIApplication sharedApplication].statusBarOrientation);
    _magnetSensor->start();

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(magneticTriggerPressed:)
                                                 name:CBTriggerPressedNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];

    return self;
}

- (void)orientationDidChange:(NSNotification *)notification
{
    _headTracker->updateDeviceOrientation([UIApplication sharedApplication].statusBarOrientation);
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
    
    [self.stereoRendererDelegate setupRendererWithView:self.view];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.stereoRendererDelegate shutdownRendererWithView:self.view];

    if (_magnetSensor != nullptr) { delete _magnetSensor; }
    if (_headTracker != nullptr) { delete _headTracker; }
    if (_headTransform != nullptr) { delete _headTransform; }
    if (_headMountedDisplay != nullptr) { delete _headMountedDisplay; }
   
    if (_monocularEye != nullptr) { delete _monocularEye; }
    if (_leftEye != nullptr) { delete _leftEye; }
    if (_rightEye != nullptr) { delete _rightEye; }

    if (_distortionRenderer != nullptr) { delete _distortionRenderer; }
}

- (BOOL)vignetteEnabled
{
    return _distortionRenderer->vignetteEnabled();
}

- (void)setVignetteEnabled:(BOOL)vignetteEnabled
{
    _distortionRenderer->setVignetteEnabled(vignetteEnabled);
}

- (BOOL)chromaticAberrationCorrectionEnabled
{
    return _distortionRenderer->chromaticAberrationEnabled();
}

- (void)setChromaticAberrationCorrectionEnabled:(BOOL)chromaticAberrationCorrectionEnabled
{
    _distortionRenderer->setChromaticAberrationEnabled(chromaticAberrationCorrectionEnabled);
}

- (BOOL)restoreGLStateEnabled
{
    return _distortionRenderer->restoreGLStateEnabled();
}

- (void)setRestoreGLStateEnabled:(BOOL)restoreGLStateEnabled
{
    _distortionRenderer->setRestoreGLStateEnabled(restoreGLStateEnabled);
}

- (BOOL)neckModelEnabled
{
    return _headTracker->neckModelEnabled();
}

- (void)setNeckModelEnabled:(BOOL)neckModelEnabled
{
    _headTracker->setNeckModelEnabled(neckModelEnabled);
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
        _headTracker->stopTracking();
        _magnetSensor->stop();
    }
    else
    {
        _headTracker->startTracking([UIApplication sharedApplication].statusBarOrientation);
        _magnetSensor->start();
    }
}

- (void)glkViewControllerUpdate:(GLKViewController *)controller
{
    if (self.paused || !_headTracker->isReady()) { return; }

    [self calculateFrameParametersWithHeadTransform:_headTransform
                                            leftEye:_leftEye
                                           rightEye:_rightEye
                                       monocularEye:_monocularEye];
    _frameParamentersReady = YES;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    if (self.paused || !_headTracker->isReady() || !_frameParamentersReady) { return; }
    
    // glInsertEventMarkerEXT(0, "com.apple.GPUTools.event.debug-frame");

    GLCheckForError();

    BOOL lockAcquired = [_glLock tryLock];
    if (!lockAcquired) { return; }
    
    if (self.vrModeEnabled)
    {
        if (_distortionCorrectionEnabled)
        {
            _distortionRenderer->beforeDrawFrame();

            [self drawFrameWithHeadTransform:_headTransform
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
            [self drawFrameWithHeadTransform:_headTransform
                                     leftEye:_leftEye
                                    rightEye:_rightEye];
        }
    }
    else
    {
        [self drawFrameWithHeadTransform:_headTransform
                                 leftEye:_monocularEye
                                rightEye:nullptr];
    }
    
    [self finishFrameWithViewPort:_monocularEye->viewport()];

    GLCheckForError();

    [_glLock unlock];
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
    
    if (self.vrModeEnabled)
    {
        GLKMatrix4 leftEyeTranslate = GLKMatrix4MakeTranslation(halfInterLensDistance, 0, 0);
        GLKMatrix4 rightEyeTranslate = GLKMatrix4MakeTranslation(-halfInterLensDistance, 0, 0);
        
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
        
        if (!self.vrModeEnabled)
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
    [self updateRenderViewSize:self.view.bounds.size];
}

#pragma mark Stereo renderer methods

- (void)updateRenderViewSize:(CGSize)size
{
    if (self.vrModeEnabled)
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

- (void)getFrameParameters:(float *)frameParemeters
{
    [self calculateFrameParametersWithHeadTransform:_headTransform
                                            leftEye:_leftEye
                                           rightEye:_rightEye
                                       monocularEye:_monocularEye];

    GLKMatrix4 headView = _headTransform->headView();
    GLKMatrix4 leftEyeView = _leftEye->eyeView();
    GLKMatrix4 leftEyePerspective = _leftEye->perspective(_zNear, _zFar);
    GLKMatrix4 rightEyeView = _rightEye->eyeView();
    GLKMatrix4 rightEyePerspective = _rightEye->perspective(_zNear, _zFar);

    std::copy(headView.m, headView.m + 16, frameParemeters);
    std::copy(leftEyeView.m, leftEyeView.m + 16, frameParemeters + 16);
    std::copy(leftEyePerspective.m, leftEyePerspective.m + 16, frameParemeters + 32);
    std::copy(rightEyeView.m, rightEyeView.m + 16, frameParemeters + 48);
    std::copy(rightEyePerspective.m, rightEyePerspective.m + 16, frameParemeters + 64);
}

@end
