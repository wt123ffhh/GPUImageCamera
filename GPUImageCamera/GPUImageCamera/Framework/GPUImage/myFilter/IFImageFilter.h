//
//  IFImageFilter.h
//  InstaFilters
//
//  Created by Di Wu on 2/28/12.
//  Copyright (c) 2012 twitter:@diwup. All rights reserved.
//

#import "GPUImageFilter.h"

extern NSString *const kGPUImageTwoInputTextureVertexShaderString;

@interface IFImageFilter : GPUImageFilter {
    GLuint filterSourceTexture2,filterSourceTexture3, filterSourceTexture4, filterSourceTexture5, filterSourceTexture6;
    
    GPUImageFramebuffer *InputFramebuffer2,*InputFramebuffer3,*InputFramebuffer4,
          *InputFramebuffer5,*InputFramebuffer6;

    GLint filterInputTextureUniform2,filterInputTextureUniform3, filterInputTextureUniform4, filterInputTextureUniform5, filterInputTextureUniform6;
    
    GPUImageRotationMode inputRotation2;
    CMTime firstFrameTime, FrameTime2, FrameTime3, FrameTime4, FrameTime5, FrameTime6;
    
    BOOL hasSetFirstTexture,hasSetTexture2,hasSetTexture3,hasSetTexture4,hasSetTexture5;
    BOOL hasReceivedFirstFrame,hasReceivedFrame2,hasReceivedFrame3,hasReceivedFrame4,hasReceivedFrame5,hasReceivedFrame6;
    BOOL firstFrameWasVideo, secondFrameWasVideo;
}

@property(readwrite, nonatomic) GLfloat mix;
@property(readwrite, nonatomic) int sourceCount;

- (void)setMix:(GLfloat)mixValue;

@end
