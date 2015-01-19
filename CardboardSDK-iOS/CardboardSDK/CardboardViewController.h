//
//  CardboardViewController.h
//  CardboardSDK-iOS
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>


class Eye;
class HeadTransform;
class Viewport;


@protocol StereoRendererDelegate <NSObject>

- (void)setupRendererWithView:(GLKView *)GLView;
- (void)shutdownRendererWithView:(GLKView *)GLView;
- (void)renderViewDidChangeSize:(CGSize)size;

- (void)prepareNewFrameWithHeadTransform:(HeadTransform *)headTransform;
- (void)drawEye:(Eye *)eye;
- (void)finishFrameWithViewport:(Viewport *)viewPort;

@optional

- (void)magneticTriggerPressed;

@end


@interface CardboardViewController : GLKViewController

@property (nonatomic) id <StereoRendererDelegate> stereoRendererDelegate;
@property (nonatomic) BOOL isVRModeEnabled;

@end
