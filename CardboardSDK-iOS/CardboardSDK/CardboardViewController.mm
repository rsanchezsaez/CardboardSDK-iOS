//
//  CardboardViewController.mm
//  CardboardSDK-iOS
//

#import "CardboardViewController.h"

#include "CardboardDeviceParams.h"
#include "DistortionRenderer.h"
#include "Eye.h"
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

- (void)drawFrameWithHeadTransform:(HeadTransform *)headTransform leftEye:(Eye *)leftEye rightEye:(Eye *)rightEye
{
    checkGLError();
 
    // NSLog(@"%@", NSStringFromGLKMatrix4(leftEyeParams->transform()->eyeView()));

    [self.stereoRendererDelegate prepareNewFrameWithHeadTransform:headTransform];
    
    checkGLError();
    
    glEnable(GL_SCISSOR_TEST);
    leftEye->viewport()->setGLViewport();
    leftEye->viewport()->setGLScissor();
    
    checkGLError();
    
    [self.stereoRendererDelegate drawEye:leftEye];

    checkGLError();

    if (rightEye == nullptr) { return; }

    rightEye->viewport()->setGLViewport();
    rightEye->viewport()->setGLScissor();

    checkGLError();
    
    [self.stereoRendererDelegate drawEye:rightEye];

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

@property (nonatomic, assign) Eye *monocularEye;
@property (nonatomic, assign) Eye *leftEye;
@property (nonatomic, assign) Eye *rightEye;

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
    
    self.monocularEye = new Eye(Eye::TypeMonocular);
    self.leftEye = new Eye(Eye::TypeLeft);
    self.rightEye = new Eye(Eye::TypeRight);

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

- (void)calculateFrameParametersWithHeadTransform:(HeadTransform *)headTransform
                                          leftEye:(Eye *)leftEye
                                         rightEye:(Eye *)rightEye
                                     monocularEye:(Eye *)monocularEye
{
    CardboardDeviceParams *cardboardDeviceParams = _headMountedDisplay->getCardboard();
    
    headTransform->setHeadView(_headTracker->lastHeadView());
    float halfInterpupillaryDistance = cardboardDeviceParams->interLensDistance() * 0.5f;
    
    // NSLog(@"%@", NSStringFromGLKMatrix4(_headTracker->lastHeadView()));
    
    if (self.isVRModeEnabled)
    {
        GLKMatrix4 leftEyeTranslate = GLKMatrix4Identity;
        GLKMatrix4 rightEyeTranslate = GLKMatrix4Identity;
        
        GLKMatrix4Translate(leftEyeTranslate, halfInterpupillaryDistance, 0, 0);
        GLKMatrix4Translate(rightEyeTranslate, -halfInterpupillaryDistance, 0, 0);
        
        // NSLog(@"%@", NSStringFromGLKMatrix4(headTransform->getHeadView()));
        
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
        
        if (!self.isVRModeEnabled)
        {
            //            float aspectRatio = screenParams->width() / screenParams->height();
            //            monocularEye->setPerspective(
            //            GLKMatrix4MakePerspective(GLKMathDegreesToRadians(_headMountedDisplay->getCardboard()->fovY()),
            //                                      aspectRatio,
            //                                      _zNear,
            //                                      _zFar));
        }
        else if (_distortionCorrectionEnabled)
        {
            [self updateFovsWithLeftEyeFov:leftEye->fov() rightEyeFov:rightEye->fov()];
            _distortionRenderer->onProjectionChanged(_headMountedDisplay, leftEye, rightEye, _zNear, _zFar);
        }
        else
        {
            float eyeToScreenDistance = cardboardDeviceParams->visibleViewportSize() / 2.0f / tanf(GLKMathDegreesToRadians(cardboardDeviceParams->fovY()) / 2.0f );
            
            float left = screenParams->widthInMeters() / 2.0f - halfInterpupillaryDistance;
            float right = halfInterpupillaryDistance;
            float bottom = cardboardDeviceParams->verticalDistanceToLensCenter() - screenParams->borderSizeInMeters();
            float top = screenParams->borderSizeInMeters() + screenParams->heightInMeters() - cardboardDeviceParams->verticalDistanceToLensCenter();
            
            FieldOfView *leftEyeFov = leftEye->fov();
            leftEyeFov->setLeft(GLKMathRadiansToDegrees(atan2f(left, eyeToScreenDistance)));
            leftEyeFov->setRight(GLKMathRadiansToDegrees(atan2f(right, eyeToScreenDistance)));
            leftEyeFov->setBottom(GLKMathRadiansToDegrees(atan2f(bottom, eyeToScreenDistance)));
            leftEyeFov->setTop(GLKMathRadiansToDegrees(atan2f(top, eyeToScreenDistance)));
            
            FieldOfView *rightEyeFov = rightEye->fov();
            rightEyeFov->setLeft(leftEyeFov->right());
            rightEyeFov->setRight(leftEyeFov->left());
            rightEyeFov->setBottom(leftEyeFov->bottom());
            rightEyeFov->setTop(leftEyeFov->top());
            
            //            leftEye->setPerspective( leftEyeFov->toPerspectiveMatrix(_zNear, _zFar));
            //            rightEye->setPerspective( rightEyeFov->toPerspectiveMatrix(_zNear, _zFar));
            
            leftEye->viewport()->setViewport(0, 0, screenParams->width() / 2, screenParams->height());
            rightEye->viewport()->setViewport(screenParams->width() / 2, 0, screenParams->width() / 2, screenParams->height());
        }
        leftEye->setProjectionChanged();
        rightEye->setProjectionChanged();
        monocularEye->setProjectionChanged();
        _projectionChanged = NO;
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // glInsertEventMarkerEXT(0, "com.apple.GPUTools.event.debug-frame");

    checkGLError();
    
    [self calculateFrameParametersWithHeadTransform:_headTransform leftEye:_leftEye rightEye:_rightEye monocularEye:_monocularEye];
    
    if (self.isVRModeEnabled)
    {
        if (_distortionCorrectionEnabled)
        {
            _distortionRenderer->beforeDrawFrame();
            
            if (_distortionCorrectionScale == 1.0f)
            {
                [_stereoRenderer drawFrameWithHeadTransform:_headTransform
                                                    leftEye:_leftEye
                                                   rightEye:_rightEye];
            }
            else
            {
                int leftX = _leftEye->viewport()->x;
                int leftY = _leftEye->viewport()->y;
                int leftWidth = _leftEye->viewport()->width;
                int leftHeight = _leftEye->viewport()->height;
                int rightX = _rightEye->viewport()->x;
                int rightY = _rightEye->viewport()->y;
                int rightWidth = _rightEye->viewport()->width;
                int rightHeight = _rightEye->viewport()->height;

                _leftEye->viewport()->setViewport((int)(leftX * _distortionCorrectionScale),
                                                           (int)(leftY * _distortionCorrectionScale),
                                                           (int)(leftWidth * _distortionCorrectionScale),
                                                           (int)(leftHeight * _distortionCorrectionScale));

                _rightEye->viewport()->setViewport((int)(rightX * _distortionCorrectionScale),
                                                            (int)(rightY * _distortionCorrectionScale),
                                                            (int)(rightWidth * _distortionCorrectionScale),
                                                            (int)(rightHeight * _distortionCorrectionScale));
                
                [_stereoRenderer drawFrameWithHeadTransform:_headTransform
                                                    leftEye:_leftEye
                                                   rightEye:_rightEye];

                _leftEye->viewport()->setViewport(leftX, leftY, leftWidth, leftHeight);
                _rightEye->viewport()->setViewport(rightX, rightY, rightWidth, rightHeight);
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
