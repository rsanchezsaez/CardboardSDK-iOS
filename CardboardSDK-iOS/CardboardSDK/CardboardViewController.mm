//
//  CardboardViewController.mm
//  CardboardSDK-iOS
//

#import "CardboardViewController.h"

#include "CardboardDeviceParams.h"
#include "DistortionRenderer.h"
#include "EyeParams.h"
#include "HeadTracker.h"
#include "HeadTransform.h"
#include "HeadMountedDisplay.h"
#include "MagnetSensor.h"
#include "Viewport.h"

#import "DebugUtils.h"
#import "GLHelpers.h"

#import <OpenGLES/ES2/glext.h>


@interface StereoRenderer : NSObject

@property (nonatomic) id <StereoRendererDelegate> stereoRendererDelegate;
@property (nonatomic) BOOL isVRModeEnabled;

@end


@implementation StereoRenderer

- (void)setupRendererWithView:(GLKView *)GLView
{
    [self.stereoRendererDelegate setupRendererWithView:GLView];
}

- (void)shutdownRendererWithView:(GLKView *)GLView
{
    [self.stereoRendererDelegate shutdownRendererWithView:GLView];
}

- (void)updateRenderViewSize:(CGSize)size
{
    if (self.isVRModeEnabled)
    {
        [self.stereoRendererDelegate renderViewDidChangeSize:CGSizeMake(size.width / 2, size.height)];
    }
    else
    {
        [self.stereoRendererDelegate renderViewDidChangeSize:CGSizeMake(size.width, size.height)];
    }
}

- (void)drawFrameWithHeadTransform:(HeadTransform *)headTransform leftEyeParams:(EyeParams *)leftEyeParams rightEyeParams:(EyeParams *)rightEyeParams
{
    checkGLError();
 
    // NSLog(@"%@", NSStringFromGLKMatrix4(leftEyeParams->transform()->eyeView()));

    [self.stereoRendererDelegate prepareNewFrameWithHeadTransform:headTransform];
    
    checkGLError();
    
    glEnable(GL_SCISSOR_TEST);
    leftEyeParams->viewport()->setGLViewport();
    leftEyeParams->viewport()->setGLScissor();
    
    checkGLError();
    
    [self.stereoRendererDelegate drawEyeWithTransform:leftEyeParams->transform()
                                              eyeType:leftEyeParams->type()];

    checkGLError();

    if (rightEyeParams == nullptr) { return; }

    rightEyeParams->viewport()->setGLViewport();
    rightEyeParams->viewport()->setGLScissor();

    checkGLError();
    
    [self.stereoRendererDelegate drawEyeWithTransform:rightEyeParams->transform()
                                              eyeType:rightEyeParams->type()];

    checkGLError();
}

- (void)finishFrameWithViewPort:(Viewport *)viewport
{
    viewport->setGLViewport();
    viewport->setGLScissor();
    [self.stereoRendererDelegate finishFrameWithViewport:viewport];
}

@end




@interface CardboardViewController () <GLKViewControllerDelegate>

@property (nonatomic) GLKView *view;

@property (nonatomic, assign) MagnetSensor *magnetSensor;
@property (nonatomic, assign) HeadTracker *headTracker;
@property (nonatomic, assign) HeadTransform *headTransform;
@property (nonatomic, assign) HeadMountedDisplay *headMountedDisplay;

@property (nonatomic, assign) EyeParams *monocularParams;
@property (nonatomic, assign) EyeParams *leftEyeParams;
@property (nonatomic, assign) EyeParams *rightEyeParams;

@property (nonatomic, assign) DistortionRenderer *distortionRenderer;

@property (nonatomic, assign) BOOL distortionCorrectionEnabled;
@property (nonatomic, assign) float distortionCorrectionScale;

@property (nonatomic, assign) float zNear;
@property (nonatomic, assign) float zFar;

@property (nonatomic, assign) BOOL projectionChanged;

@property (nonatomic, strong) StereoRenderer *stereoRenderer;

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
    
    self.monocularParams = new EyeParams(EyeParamsTypeMonocular);
    self.leftEyeParams = new EyeParams(EyeParamsTypeLeft);
    self.rightEyeParams = new EyeParams(EyeParamsTypeRight);

    self.distortionRenderer = new DistortionRenderer();
    
    self.stereoRenderer = [StereoRenderer new];
    self.distortionCorrectionScale = 1.0f;

    self.isVRModeEnabled = YES;
    self.distortionCorrectionEnabled = YES;

    self.zNear = 0.1f;
    self.zFar = 100.0f;

    self.projectionChanged = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(magneticTriggerPressed)
                                                 name:CBTriggerPressedNotification
                                               object:nil];
    
    return self;
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

    if (self.magnetSensor != nullptr) { delete self.magnetSensor; }
    if (self.headTracker != nullptr) { delete self.headTracker; }
    if (self.headTransform != nullptr) { delete self.headTransform; }
    if (self.headMountedDisplay != nullptr) { delete self.headMountedDisplay; }
   
    if (self.monocularParams != nullptr) { delete self.monocularParams; }
    if (self.leftEyeParams != nullptr) { delete self.leftEyeParams; }
    if (self.rightEyeParams != nullptr) { delete self.rightEyeParams; }

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

- (BOOL)isVRModeEnabled
{
    return self.stereoRenderer.isVRModeEnabled;
}

- (void)setIsVRModeEnabled:(BOOL)isVRModeEnabled
{
    self.stereoRenderer.isVRModeEnabled = isVRModeEnabled;
}

- (void)magneticTriggerPressed
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

    checkGLError();

    CardboardDeviceParams *cardboardDeviceParams = _headMountedDisplay->getCardboard();
    
    _headTransform->setHeadView(_headTracker->lastHeadView());
    float halfInterpupillaryDistance = cardboardDeviceParams->interLensDistance() * 0.5f;
    
    // NSLog(@"%@", NSStringFromGLKMatrix4(_headTracker->lastHeadView()));

    if (self.isVRModeEnabled)
    {
        GLKMatrix4 leftEyeTranslate = GLKMatrix4Identity;
        GLKMatrix4 rightEyeTranslate = GLKMatrix4Identity;
        
        GLKMatrix4Translate(leftEyeTranslate, halfInterpupillaryDistance, 0, 0);
        GLKMatrix4Translate(rightEyeTranslate, -halfInterpupillaryDistance, 0, 0);
        
        // NSLog(@"%@", NSStringFromGLKMatrix4(_headTransform->getHeadView()));

        _leftEyeParams->transform()->setEyeView( GLKMatrix4Multiply(leftEyeTranslate, _headTransform->headView()));
        _rightEyeParams->transform()->setEyeView( GLKMatrix4Multiply(rightEyeTranslate, _headTransform->headView()));
    }
    else
    {
        _monocularParams->transform()->setEyeView(_headTransform->headView());
    }
    
    if (_projectionChanged)
    {
        ScreenParams *screenParams = _headMountedDisplay->getScreen();
        _monocularParams->viewport()->setViewport(0, 0, screenParams->width(), screenParams->height());
        
        if (!self.isVRModeEnabled)
        {
            float aspectRatio = screenParams->width() / screenParams->height();
            _monocularParams->transform()->setPerspective(
            GLKMatrix4MakePerspective(GLKMathDegreesToRadians(_headMountedDisplay->getCardboard()->fovY()),
                                      aspectRatio,
                                      _zNear,
                                      _zFar));
        }
        else if (_distortionCorrectionEnabled)
        {
            [self updateFovsWithLeftEyeFov:_leftEyeParams->fov() rightEyeFov:_rightEyeParams->fov()];
            _distortionRenderer->onProjectionChanged(_headMountedDisplay, _leftEyeParams, _rightEyeParams, _zNear, _zFar);
        }
        else
        {
            float eyeToScreenDistance = cardboardDeviceParams->visibleViewportSize() / 2.0f / tanf(GLKMathDegreesToRadians(cardboardDeviceParams->fovY()) / 2.0f );
            
            float left = screenParams->widthInMeters() / 2.0f - halfInterpupillaryDistance;
            float right = halfInterpupillaryDistance;
            float bottom = cardboardDeviceParams->verticalDistanceToLensCenter() - screenParams->borderSizeInMeters();
            float top = screenParams->borderSizeInMeters() + screenParams->heightInMeters() - cardboardDeviceParams->verticalDistanceToLensCenter();
            
            FieldOfView *leftEyeFov = _leftEyeParams->fov();
            leftEyeFov->setLeft(GLKMathRadiansToDegrees(atan2f(left, eyeToScreenDistance)));
            leftEyeFov->setRight(GLKMathRadiansToDegrees(atan2f(right, eyeToScreenDistance)));
            leftEyeFov->setBottom(GLKMathRadiansToDegrees(atan2f(bottom, eyeToScreenDistance)));
            leftEyeFov->setTop(GLKMathRadiansToDegrees(atan2f(top, eyeToScreenDistance)));

            FieldOfView *rightEyeFov = _rightEyeParams->fov();
            rightEyeFov->setLeft(leftEyeFov->right());
            rightEyeFov->setRight(leftEyeFov->left());
            rightEyeFov->setBottom(leftEyeFov->bottom());
            rightEyeFov->setTop(leftEyeFov->top());

            _leftEyeParams->transform()->setPerspective( leftEyeFov->toPerspectiveMatrix(_zNear, _zFar));
            _rightEyeParams->transform()->setPerspective( rightEyeFov->toPerspectiveMatrix(_zNear, _zFar));

            _leftEyeParams->viewport()->setViewport(0, 0, screenParams->width() / 2, screenParams->height());
            _rightEyeParams->viewport()->setViewport(screenParams->width() / 2, 0, screenParams->width() / 2, screenParams->height());
        }
        
        _projectionChanged = NO;
    }
    
    if (self.isVRModeEnabled)
    {
        if (_distortionCorrectionEnabled)
        {
            _distortionRenderer->beforeDrawFrame();
            
            if (_distortionCorrectionScale == 1.0f)
            {
                [_stereoRenderer drawFrameWithHeadTransform:_headTransform
                                              leftEyeParams:_leftEyeParams
                                             rightEyeParams:_rightEyeParams];
            }
            else
            {
                int leftX = _leftEyeParams->viewport()->x;
                int leftY = _leftEyeParams->viewport()->y;
                int leftWidth = _leftEyeParams->viewport()->width;
                int leftHeight = _leftEyeParams->viewport()->height;
                int rightX = _rightEyeParams->viewport()->x;
                int rightY = _rightEyeParams->viewport()->y;
                int rightWidth = _rightEyeParams->viewport()->width;
                int rightHeight = _rightEyeParams->viewport()->height;

                _leftEyeParams->viewport()->setViewport((int)(leftX * _distortionCorrectionScale),
                                                           (int)(leftY * _distortionCorrectionScale),
                                                           (int)(leftWidth * _distortionCorrectionScale),
                                                           (int)(leftHeight * _distortionCorrectionScale));

                _rightEyeParams->viewport()->setViewport((int)(rightX * _distortionCorrectionScale),
                                                            (int)(rightY * _distortionCorrectionScale),
                                                            (int)(rightWidth * _distortionCorrectionScale),
                                                            (int)(rightHeight * _distortionCorrectionScale));
                
                [_stereoRenderer drawFrameWithHeadTransform:_headTransform
                                              leftEyeParams:_leftEyeParams
                                             rightEyeParams:_rightEyeParams];

                _leftEyeParams->viewport()->setViewport(leftX, leftY, leftWidth, leftHeight);
                _rightEyeParams->viewport()->setViewport(rightX, rightY, rightWidth, rightHeight);
            }
            
            checkGLError();

            // Rebind original framebuffer
            [self.view bindDrawable];
            _distortionRenderer->afterDrawFrame();
            
            checkGLError();
        }
        else
        {
            [_stereoRenderer drawFrameWithHeadTransform:_headTransform
                                          leftEyeParams:_leftEyeParams
                                         rightEyeParams:_rightEyeParams];
        }
    }
    else
    {
        [_stereoRenderer drawFrameWithHeadTransform:_headTransform
                                      leftEyeParams:_monocularParams
                                     rightEyeParams:nullptr];
    }
    
    [_stereoRenderer finishFrameWithViewPort:_monocularParams->viewport()];
    
    checkGLError();
}

- (void)updateFovsWithLeftEyeFov:(FieldOfView *)leftEyeFov rightEyeFov:(FieldOfView *)rightEyeFov
{
    CardboardDeviceParams *cardboardDeviceParams = _headMountedDisplay->getCardboard();
    ScreenParams *screenParams = _headMountedDisplay->getScreen();
    Distortion *distortion = cardboardDeviceParams->getDistortion();
    
    float idealFovAngle = GLKMathRadiansToDegrees(atan2f(cardboardDeviceParams->lensDiameter() / 2.0f,
            cardboardDeviceParams->eyeToLensDistance()));
    float eyeToScreenDistance = cardboardDeviceParams->eyeToLensDistance() + cardboardDeviceParams->screenToLensDistance();
    float outerDistance = (screenParams->widthInMeters() - cardboardDeviceParams->interLensDistance() ) / 2.0f;
    float innerDistance = cardboardDeviceParams->interLensDistance() / 2.0f;
    float bottomDistance = cardboardDeviceParams->verticalDistanceToLensCenter() - screenParams->borderSizeInMeters();
    float topDistance = screenParams->heightInMeters() + screenParams->borderSizeInMeters() - cardboardDeviceParams->verticalDistanceToLensCenter();
 
    float outerAngle = GLKMathRadiansToDegrees(atan2f(distortion->distort(outerDistance), eyeToScreenDistance));
    float innerAngle = GLKMathRadiansToDegrees(atan2f(distortion->distort(innerDistance), eyeToScreenDistance));
    float bottomAngle = GLKMathRadiansToDegrees(atan2f(distortion->distort(bottomDistance), eyeToScreenDistance));
    float topAngle = GLKMathRadiansToDegrees(atan2f(distortion->distort(topDistance), eyeToScreenDistance));
    
    leftEyeFov->setLeft(MIN(outerAngle, idealFovAngle));
    leftEyeFov->setRight(MIN(innerAngle, idealFovAngle));
    leftEyeFov->setBottom(MIN(bottomAngle, idealFovAngle));
    leftEyeFov->setTop(MIN(topAngle, idealFovAngle));

    rightEyeFov->setLeft(MIN(innerAngle, idealFovAngle));
    rightEyeFov->setRight(MIN(outerAngle, idealFovAngle));
    rightEyeFov->setBottom(MIN(bottomAngle, idealFovAngle));
    rightEyeFov->setTop(MIN(topAngle, idealFovAngle));
}

@end
