//
//  DistortionMesh.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EyeParams.h"
#import "Distortion.h"
#import <GLKit/GLKit.h>

@interface DistortionMesh : NSObject

@property (nonatomic, assign) GLuint arrayBufferId;
@property (nonatomic, assign) Float32 *vertexData;
@property (nonatomic, assign) GLuint elementBufferId;
@property (nonatomic, assign) int indices;
@property (nonatomic, assign) UInt32 *indexData;

- (id)initWithEyeParams:(EyeParams*)eye distortion:(Distortion*)distortion screenWidthM:(float)screenWidthM screenHeightM:(float)screenHeightM xEyeOffsetMScreen:(float)xEyeOffsetMScreen yEyeOffsetMScreen:(float)yEyeOffsetMScreen textureWidthM:(float)textureWidthM textureHeightM:(float)textureHeightM xEyeOffsetMTexture:(float)xEyeOffsetMTexture yEyeOffsetMTexture:(float)yEyeOffsetMTexture viewportXMTexture:(float)viewportXMTexture viewportYMTexture:(float)viewportYMTexture viewportWidthMTexture:(float)viewportWidthMTexture viewportHeightMTexture:(float)viewportHeightMTexture;

@end
