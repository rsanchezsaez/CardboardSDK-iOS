//
//  ProgramHolder.h
//  CardboardVR
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProgramHolder : NSObject

@property (nonatomic, assign) int program;
@property (nonatomic, assign) int aPosition;
@property (nonatomic, assign) int aVignette;
@property (nonatomic, assign) int aTextureCoord;
@property (nonatomic, assign) int uTextureCoordScale;
@property (nonatomic, assign) int uTextureSampler;

@end
