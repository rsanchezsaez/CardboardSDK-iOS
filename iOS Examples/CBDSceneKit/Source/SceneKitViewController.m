//
//  SceneKitViewController.m
//  CardboardSDK-iOS
//
//

#import "SceneKitViewController.h"
#include "CardboardSDK.h"

#import <SceneKit/SceneKit.h>
#import <SpriteKit/SpriteKit.h>

@interface SceneKitViewController() <CBDStereoRendererDelegate>
{
    SCNScene *_scene;
    
    SCNNode *_cameraNode;
    SCNNode *_cameraControlNode;
    
    SCNRenderer *_renderer;
}

@end

@implementation SceneKitViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
    {
        return nil;
    }
    
    self.stereoRendererDelegate = self;
    
    return self;
}

- (void)setupRendererWithView:(GLKView *)glView
{
    [EAGLContext setCurrentContext:glView.context];
    
    glClearColor(0.25f, 0.25f, 0.25f, 1.0f);
    
    _scene = [SCNScene sceneNamed:@"scene.scnassets/scene.dae"];
    
    // _cameraControlNode is the parent of _cameraNode
    // it can be used to translate/rotate the camera without affecting the head tracking
    _cameraControlNode = [_scene.rootNode childNodeWithName:@"CameraControl" recursively:YES];
    // _cameraNode is where the head tracking transform is applied
    _cameraNode = [_scene.rootNode childNodeWithName:@"Camera" recursively:YES];
    
    // spriteKitCube is a cube which has a SKScene applied as a texture (the texture is empty but that's irrelevant)
    SCNNode *spriteKitCube = [_scene.rootNode childNodeWithName:@"SpriteKitCube" recursively:YES];
    spriteKitCube.geometry.firstMaterial.diffuse.contents = [[SKScene alloc] initWithSize:CGSizeMake(100.0f, 100.0f)];
    
    _renderer = [SCNRenderer rendererWithContext:glView.context options:nil];
    _renderer.scene = _scene;
    _renderer.pointOfView = _cameraNode;
    
    // Example of moving _cameraControlNode without affecting the head tracking
    // The position and rotation of _cameraControlNode determines where the camera is looking when the user head is looking forward
    // The head tracking transform is applied to _cameraNode independently of _cameraControlNode, so you get the combined transform
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        SCNAction *cameraMoveAction = [SCNAction moveTo:SCNVector3Make(-4.5f, -4.5f, 0.0f) duration:10.0f];
        cameraMoveAction.timingMode = SCNActionTimingModeEaseInEaseOut;
        [_cameraControlNode runAction:cameraMoveAction];
    });
}

- (void)shutdownRendererWithView:(GLKView *)glView
{
}

- (void)renderViewDidChangeSize:(CGSize)size
{
}

- (void)prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix
{
    // Disable GL_SCISSOR_TEST here due to an issue that causes parts of the screen not to be cleared on some devices
    // GL_SCISSOR_TEST is enabled again after returning from this function so no need to re-enable here.
    glDisable(GL_SCISSOR_TEST);
    // Perform glClear() because using SpriteKit's SKScene as a texture in SceneKit interferes with GL_SCISSOR_TEST
    // If you move glClear() to the start of -drawEyeWithEye:, the left side of the screen is cleared when the right eye is drawn
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)drawEyeWithEye:(CBDEye *)eye
{
    // Use Z-Up/Y-Forward because we are using a scene exported from Blender
    GLKMatrix4 lookAt = GLKMatrix4MakeLookAt(0.0f, 0.0f, 0.0f,
                                             0.0f, 1.0f, 0.0f,
                                             0.0f, 0.0f, 1.0f);    
    _cameraNode.transform = SCNMatrix4Invert(SCNMatrix4FromGLKMatrix4(GLKMatrix4Multiply([eye eyeViewMatrix], lookAt)));
    [_cameraNode.camera setProjectionTransform:SCNMatrix4FromGLKMatrix4([eye perspectiveMatrixWithZNear:0.1f zFar:100.0f])];
    
    [_renderer renderAtTime:0];
}

- (void)finishFrameWithViewportRect:(CGRect)viewPort
{
}

@end
