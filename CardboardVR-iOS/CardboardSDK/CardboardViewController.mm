//
//  CardboardViewController.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-09-04.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
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
 
    // NSLog(@"%@", NSStringFromGLKMatrix4(leftEyeParams->getTransform()->getEyeView()));

    [self.stereoRendererDelegate prepareNewFrameWithHeadTransform:headTransform];
    
    checkGLError();
    
    glEnable(GL_SCISSOR_TEST);
    leftEyeParams->getViewport()->setGLViewport();
    leftEyeParams->getViewport()->setGLScissor();
    
    checkGLError();
    
    [self.stereoRendererDelegate drawEyeWithTransform:leftEyeParams->getTransform()
                                              eyeType:leftEyeParams->getEye()];

    checkGLError();

    if (rightEyeParams == nullptr) { return; }
    
    rightEyeParams->getViewport()->setGLViewport();
    rightEyeParams->getViewport()->setGLScissor();

    checkGLError();
    
    [self.stereoRendererDelegate drawEyeWithTransform:rightEyeParams->getTransform()
                                              eyeType:rightEyeParams->getEye()];

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
    
    _headTransform->setHeadView(_headTracker->getLastHeadView());
    float halfInterpupillaryDistance = cardboardDeviceParams->getInterpupillaryDistance() * 0.5f;
    
    // NSLog(@"%@", NSStringFromGLKMatrix4(_headTracker->getLastHeadView()));

    if (self.isVRModeEnabled)
    {
        GLKMatrix4 leftEyeTranslate = GLKMatrix4Identity;
        GLKMatrix4 rightEyeTranslate = GLKMatrix4Identity;
        
        GLKMatrix4Translate(leftEyeTranslate, halfInterpupillaryDistance, 0, 0);
        GLKMatrix4Translate(rightEyeTranslate, -halfInterpupillaryDistance, 0, 0);
        
        // NSLog(@"%@", NSStringFromGLKMatrix4(_headTransform->getHeadView()));

        _leftEyeParams->getTransform()->setEyeView( GLKMatrix4Multiply(leftEyeTranslate, _headTransform->getHeadView()));
        _rightEyeParams->getTransform()->setEyeView( GLKMatrix4Multiply(rightEyeTranslate, _headTransform->getHeadView()));
    }
    else
    {
        _monocularParams->getTransform()->setEyeView(_headTransform->getHeadView());
    }
    
    if (_projectionChanged)
    {
        ScreenParams *screenParams = _headMountedDisplay->getScreen();
        _monocularParams->getViewport()->setViewport(0, 0, screenParams->getWidth(), screenParams->getHeight());
        
        if (!self.isVRModeEnabled)
        {
            float aspectRatio = screenParams->getWidth() / screenParams->getHeight();
            _monocularParams->getTransform()->setPerspective(
            GLKMatrix4MakePerspective(GLKMathDegreesToRadians(_headMountedDisplay->getCardboard()->getFovY()),
                                      aspectRatio,
                                      _zNear,
                                      _zFar));
        }
        else if (_distortionCorrectionEnabled)
        {
            [self updateFovsWithLeftEyeFov:_leftEyeParams->getFov() rightEyeFov:_rightEyeParams->getFov()];
            _distortionRenderer->onProjectionChanged(_headMountedDisplay, _leftEyeParams, _rightEyeParams, _zNear, _zFar);
        }
        else
        {
            float eyeToScreenDistance = cardboardDeviceParams->getVisibleViewportSize() / 2.0f / tanf(GLKMathDegreesToRadians(cardboardDeviceParams->getFovY()) / 2.0f );
            
            float left = screenParams->getWidthMeters() / 2.0f - halfInterpupillaryDistance;
            float right = halfInterpupillaryDistance;
            float bottom = cardboardDeviceParams->getVerticalDistanceToLensCenter() - screenParams->getBorderSizeMeters();
            float top = screenParams->getBorderSizeMeters() + screenParams->getHeightMeters() - cardboardDeviceParams->getVerticalDistanceToLensCenter();
            
            FieldOfView *leftEyeFov = _leftEyeParams->getFov();
            leftEyeFov->setLeft(GLKMathRadiansToDegrees(atan2f(left, eyeToScreenDistance)));
            leftEyeFov->setRight(GLKMathRadiansToDegrees(atan2f(right, eyeToScreenDistance)));
            leftEyeFov->setBottom(GLKMathRadiansToDegrees(atan2f(bottom, eyeToScreenDistance)));
            leftEyeFov->setTop(GLKMathRadiansToDegrees(atan2f(top, eyeToScreenDistance)));

            FieldOfView *rightEyeFov = _rightEyeParams->getFov();
            rightEyeFov->setLeft(leftEyeFov->getRight());
            rightEyeFov->setRight(leftEyeFov->getLeft());
            rightEyeFov->setBottom(leftEyeFov->getBottom());
            rightEyeFov->setTop(leftEyeFov->getTop());
            
            _leftEyeParams->getTransform()->setPerspective( leftEyeFov->toPerspectiveMatrix(_zNear, _zFar));
            _rightEyeParams->getTransform()->setPerspective( rightEyeFov->toPerspectiveMatrix(_zNear, _zFar));
            
            _leftEyeParams->getViewport()->setViewport(0, 0, screenParams->getWidth() / 2, screenParams->getHeight());
            _rightEyeParams->getViewport()->setViewport(screenParams->getWidth() / 2, 0, screenParams->getWidth() / 2, screenParams->getHeight());
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
                int leftX = _leftEyeParams->getViewport()->x;
                int leftY = _leftEyeParams->getViewport()->y;
                int leftWidth = _leftEyeParams->getViewport()->width;
                int leftHeight = _leftEyeParams->getViewport()->height;
                int rightX = _rightEyeParams->getViewport()->x;
                int rightY = _rightEyeParams->getViewport()->y;
                int rightWidth = _rightEyeParams->getViewport()->width;
                int rightHeight = _rightEyeParams->getViewport()->height;
                
                _leftEyeParams->getViewport()->setViewport((int)(leftX * _distortionCorrectionScale),
                                                           (int)(leftY * _distortionCorrectionScale),
                                                           (int)(leftWidth * _distortionCorrectionScale),
                                                           (int)(leftHeight * _distortionCorrectionScale));
                
                _rightEyeParams->getViewport()->setViewport((int)(rightX * _distortionCorrectionScale),
                                                            (int)(rightY * _distortionCorrectionScale),
                                                            (int)(rightWidth * _distortionCorrectionScale),
                                                            (int)(rightHeight * _distortionCorrectionScale));
                
                [_stereoRenderer drawFrameWithHeadTransform:_headTransform
                                              leftEyeParams:_leftEyeParams
                                             rightEyeParams:_rightEyeParams];
                
                _leftEyeParams->getViewport()->setViewport(leftX, leftY, leftWidth, leftHeight);
                _rightEyeParams->getViewport()->setViewport(rightX, rightY, rightWidth, rightHeight);
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
    
    [_stereoRenderer finishFrameWithViewPort:_monocularParams->getViewport()];
    
    checkGLError();
}

- (void)updateFovsWithLeftEyeFov:(FieldOfView *)leftEyeFov rightEyeFov:(FieldOfView *)rightEyeFov
{
    CardboardDeviceParams *cardboardDeviceParams = _headMountedDisplay->getCardboard();
    ScreenParams *screenParams = _headMountedDisplay->getScreen();
    Distortion *distortion = cardboardDeviceParams->getDistortion();
    
    float idealFovAngle = GLKMathRadiansToDegrees(atan2f(cardboardDeviceParams->getLensDiameter() / 2.0f,
                                                        cardboardDeviceParams->getEyeToLensDistance()));
    float eyeToScreenDistance = cardboardDeviceParams->getEyeToLensDistance() + cardboardDeviceParams->getScreenToLensDistance();
    float outerDistance = ( screenParams->getWidthMeters() - cardboardDeviceParams->getInterpupillaryDistance() ) / 2.0f;
    float innerDistance = cardboardDeviceParams->getInterpupillaryDistance() / 2.0f;
    float bottomDistance = cardboardDeviceParams->getVerticalDistanceToLensCenter() - screenParams->getBorderSizeMeters();
    float topDistance = screenParams->getHeightMeters() + screenParams->getBorderSizeMeters() - cardboardDeviceParams->getVerticalDistanceToLensCenter();
 
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
