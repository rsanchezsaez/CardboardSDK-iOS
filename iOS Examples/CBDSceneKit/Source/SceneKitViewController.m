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
    
    // cameraControlNode is the parent of the Camera node, we can use this to position/rotate the camera without affecting the head tracking
    _cameraControlNode = [_scene.rootNode childNodeWithName:@"CameraControl" recursively:YES];
    // cameraNode is the node that actually controls the head tracking applied to the camera
    _cameraNode = [_scene.rootNode childNodeWithName:@"Camera" recursively:YES];
    
    // SpriteKitCube is a cube in the scene which we will apply the SKScene as a texture (nothing in the scene but that's irrelevant)
    SCNNode *spriteKitCube = [_scene.rootNode childNodeWithName:@"SpriteKitCube" recursively:YES];
    spriteKitCube.geometry.firstMaterial.diffuse.contents = [[SKScene alloc] initWithSize:CGSizeMake(100.0f, 100.0f)];
    
    _renderer = [SCNRenderer rendererWithContext:glView.context options:nil];
    _renderer.scene = _scene;
    _renderer.pointOfView = _cameraNode;
    
    // Example of moving the CameraControlNode while not affecting the head tracking
    // The position and rotation of this node is where the camera would be looking if it was straight ahead
    // The head tracking rotation appleid to the cameraNode is applied after this so you get both effects
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
    // NOTE: We do the glClear here because of SpriteKit being used as a texture
    // If you move this to the start of drawEyeWithEye you will see the broken scissor
    // that will clear the left side of the screen when the right eye is drawn
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)drawEyeWithEye:(CBDEye *)eye
{
    // Because we are using a Blender Exported Scene, we have to use Z-Up (and hence Y-Forward)
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
