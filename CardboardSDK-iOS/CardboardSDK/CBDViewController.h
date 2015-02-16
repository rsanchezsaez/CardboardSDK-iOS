//
//  CardboardViewController.h
//  CardboardSDK-iOS
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>


typedef NS_ENUM(NSInteger, CBDEyeType)
{
    CBDEyeTypeMonocular,
    CBDEyeTypeLeft,
    CBDEyeTypeRight,
};

@interface CBDEye : NSObject

@property (nonatomic) CBDEyeType type;

- (GLKMatrix4)eyeViewMatrix;
- (GLKMatrix4)perspectiveMatrixWithZNear:(float)zNear zFar:(float)zFar;

@end


@protocol CBDStereoRendererDelegate <NSObject>

- (void)setupRendererWithView:(GLKView *)glView;
- (void)shutdownRendererWithView:(GLKView *)glView;
- (void)renderViewDidChangeSize:(CGSize)size;

- (void)prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix;
- (void)drawEyeWithEye:(CBDEye *)eye;
- (void)finishFrameWithViewportRect:(CGRect)viewPort;

@optional

- (void)magneticTriggerPressed;

@end


@interface CBDViewController : GLKViewController

@property (nonatomic) GLKView *view;
@property (nonatomic, readonly) NSRecursiveLock *glLock;

@property (nonatomic, unsafe_unretained) id <CBDStereoRendererDelegate> stereoRendererDelegate;
@property (nonatomic) BOOL vrModeEnabled;
@property (nonatomic) BOOL distortionCorrectionEnabled;
@property (nonatomic) BOOL vignetteEnabled;
@property (nonatomic) BOOL chromaticAberrationCorrectionEnabled;
@property (nonatomic) BOOL restoreGLStateEnabled;
@property (nonatomic) BOOL neckModelEnabled;

- (void)getFrameParameters:(float *)frameParemeters zNear:(float)zNear zFar:(float)zFar;

@end
