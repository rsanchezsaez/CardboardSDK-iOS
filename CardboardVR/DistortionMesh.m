//
//  DistortionMesh.m
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import "DistortionMesh.h"
#import "DistortionRenderer.h"

@implementation DistortionMesh

- (id)initWithEyeParams:(EyeParams*)eye distortion:(Distortion*)distortion screenWidthM:(float)screenWidthM screenHeightM:(float)screenHeightM xEyeOffsetMScreen:(float)xEyeOffsetMScreen yEyeOffsetMScreen:(float)yEyeOffsetMScreen textureWidthM:(float)textureWidthM textureHeightM:(float)textureHeightM xEyeOffsetMTexture:(float)xEyeOffsetMTexture yEyeOffsetMTexture:(float)yEyeOffsetMTexture viewportXMTexture:(float)viewportXMTexture viewportYMTexture:(float)viewportYMTexture viewportWidthMTexture:(float)viewportWidthMTexture viewportHeightMTexture:(float)viewportHeightMTexture
{
    self = [super init];
    if (self)
    {
        
        float mPerUScreen = screenWidthM;
        float mPerVScreen = screenHeightM;
        float mPerUTexture = textureWidthM;
        float mPerVTexture = textureHeightM;
        
        self.vertexData = malloc(sizeof(float)*8000);
        int vertexOffset = 0;
        
        for (int row = 0; row < 40; row++)
        {
            for (int col = 0; col < 40; col++)
            {
                float uTexture = col / 39.0F * (viewportWidthMTexture / textureWidthM) + viewportXMTexture / textureWidthM;
                
                float vTexture = row / 39.0F * (viewportHeightMTexture / textureHeightM) + viewportYMTexture / textureHeightM;
                
                float xTexture = uTexture * mPerUTexture;
                float yTexture = vTexture * mPerVTexture;
                float xTextureEye = xTexture - xEyeOffsetMTexture;
                float yTextureEye = yTexture - yEyeOffsetMTexture;
                float rTexture = sqrtf(xTextureEye * xTextureEye + yTextureEye * yTextureEye);
                
                
                float textureToScreen = rTexture > 0.0f ? [distortion distortInverse:rTexture] / rTexture : 1.0F;
                
                float xScreen = xTextureEye * textureToScreen + xEyeOffsetMScreen;
                float yScreen = yTextureEye * textureToScreen + yEyeOffsetMScreen;
                float uScreen = xScreen / mPerUScreen;
                float vScreen = yScreen / mPerVScreen;
                float vignetteSizeMTexture = 0.002F / textureToScreen;
                
                float dxTexture = xTexture - [DistortionRenderer clamp:xTexture min:viewportXMTexture + vignetteSizeMTexture max:viewportXMTexture + viewportWidthMTexture - vignetteSizeMTexture];
                
                float dyTexture = yTexture - [DistortionRenderer clamp:yTexture min:viewportYMTexture + vignetteSizeMTexture max:viewportYMTexture + viewportHeightMTexture - vignetteSizeMTexture];
                
                float drTexture = sqrtf(dxTexture * dxTexture + dyTexture * dyTexture);
                
                float vignette = 1.0F - [DistortionRenderer clamp:drTexture / vignetteSizeMTexture min:0.0F max:1.0F];
                
                self.vertexData[(vertexOffset + 0)] = (2.0F * uScreen - 1.0F);
                self.vertexData[(vertexOffset + 1)] = (2.0F * vScreen - 1.0F);
                self.vertexData[(vertexOffset + 2)] = vignette;
                self.vertexData[(vertexOffset + 3)] = uTexture;
                self.vertexData[(vertexOffset + 4)] = vTexture;
                
                vertexOffset += 5;
            }
        }
        
        self.indices = 3158;
        self.indexData = malloc(sizeof(UInt32) * self.indices);
        int indexOffset = 0;
        vertexOffset = 0;
        for (int row = 0; row < 39; row++)
        {
            if (row > 0)
            {
                self.indexData[indexOffset] = self.indexData[(indexOffset - 1)];
                indexOffset++;
            }
            for (int col = 0; col < 40; col++) {
                if (col > 0) {
                    if (row % 2 == 0)
                    {
                        vertexOffset++;
                    }
                    else {
                        vertexOffset--;
                    }
                }
                self.indexData[(indexOffset++)] = vertexOffset;
                self.indexData[(indexOffset++)] = (vertexOffset + 40);
            }
            vertexOffset += 40;
        }
        
        GLuint bufferIds[2] = { 0, 0 };
        glGenBuffers(2, bufferIds);
        self.arrayBufferId = bufferIds[0];
        self.elementBufferId = bufferIds[1];
        
        glBindBuffer(34962, self.arrayBufferId);
        glBufferData(34962, 8000 * sizeof(Float32), self.vertexData, 35044);
        
        glBindBuffer(34963, self.elementBufferId);
        glBufferData(34963, self.indices * sizeof(UInt32), self.indexData, 35044);
        
        glBindBuffer(34962, 0);
        glBindBuffer(34963, 0);
    }
    return self;
}

- (void)dealloc
{
    free(self.vertexData);
    free(self.indexData);
}

@end
