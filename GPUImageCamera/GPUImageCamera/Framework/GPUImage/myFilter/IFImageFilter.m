//
//  IFImageFilter.m
//  InstaFilters
//
//  Created by Di Wu on 2/28/12.
//  Copyright (c) 2012 twitter:@diwup. All rights reserved.
//

#import "IFImageFilter.h"

@implementation IFImageFilter

@synthesize mix = _mix;
@synthesize sourceCount;

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageVertexShaderString fragmentShaderFromString:fragmentShaderString]))
    {
		return nil;
    }
    
    inputRotation2 = kGPUImageNoRotation;
    
    hasSetFirstTexture = NO;
    hasSetTexture2 = NO;
    hasSetTexture3 = NO;
    hasSetTexture4 = NO;
    hasSetTexture5 = NO;
    
    hasReceivedFirstFrame = NO;
    hasReceivedFrame2 = NO;
    hasReceivedFrame3 = NO;
    hasReceivedFrame4 = NO;
    hasReceivedFrame5 = NO;
    hasReceivedFrame6 = NO;
    
    firstFrameWasVideo = NO;
    secondFrameWasVideo = NO;
    
    firstFrameTime = kCMTimeInvalid;
    FrameTime2 = kCMTimeInvalid;
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
//        filterTextureCoordinateAttribute2 = [filterProgram attributeIndex:@"inputTextureCoordinate2"];

        filterInputTextureUniform2 = [filterProgram uniformIndex:@"inputImageTexture2"]; // This does assume a name of "inputImageTexture2" for second input texture in the fragment shader
        filterInputTextureUniform3 = [filterProgram uniformIndex:@"inputImageTexture3"]; // This does assume a name of "inputImageTexture3" for second input texture in the fragment shader
        filterInputTextureUniform4 = [filterProgram uniformIndex:@"inputImageTexture4"]; // This does assume a name of "inputImageTexture4" for second input texture in the fragment shader
        filterInputTextureUniform5 = [filterProgram uniformIndex:@"inputImageTexture5"]; // This does assume a name of "inputImageTexture5" for second input texture in the fragment shader
        filterInputTextureUniform6 = [filterProgram uniformIndex:@"inputImageTexture6"]; // This does assume a name of "inputImageTexture6" for second input texture in the fragment shader
        //glEnableVertexAttribArray(filterTextureCoordinateAttribute2);
                self.mix = 1.0;
    });

    return self;
}

#pragma mark -
#pragma mark Rendering

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        [InputFramebuffer2 unlock];
        [InputFramebuffer3 unlock];
        [InputFramebuffer4 unlock];
        [InputFramebuffer5 unlock];
        [InputFramebuffer6 unlock];
        return;
    }
    
    [GPUImageContext setActiveShaderProgram:filterProgram];
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    [self setUniformsForProgramAtIndex:0];
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
	glUniform1i(filterInputTextureUniform, 2);
    
    if (InputFramebuffer2 != nil)
    {
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, [InputFramebuffer2 texture]);
        glUniform1i(filterInputTextureUniform2, 3);
    }
    if (InputFramebuffer3 != nil)
    {
        glActiveTexture(GL_TEXTURE4);
        glBindTexture(GL_TEXTURE_2D, [InputFramebuffer3 texture]);
        glUniform1i(filterInputTextureUniform3, 4);
    }
    if (InputFramebuffer4 != nil)
    {
        glActiveTexture(GL_TEXTURE5);
        glBindTexture(GL_TEXTURE_2D, [InputFramebuffer4 texture]);
        glUniform1i(filterInputTextureUniform4, 5);
    }
    if (InputFramebuffer5 != nil)
    {
        glActiveTexture(GL_TEXTURE6);
        glBindTexture(GL_TEXTURE_2D, [InputFramebuffer5 texture]);
        glUniform1i(filterInputTextureUniform5, 6);
    }
    if (InputFramebuffer6 != nil)
    {
        glActiveTexture(GL_TEXTURE7);
        glBindTexture(GL_TEXTURE_2D, [InputFramebuffer6 texture]);
        glUniform1i(filterInputTextureUniform6, 7);
    }

    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
	glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [firstInputFramebuffer unlock];
    [InputFramebuffer2 unlock];
    [InputFramebuffer3 unlock];
    [InputFramebuffer4 unlock];
    [InputFramebuffer5 unlock];
    [InputFramebuffer6 unlock];
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

#pragma mark -
#pragma mark GPUImageInput

- (NSInteger)nextAvailableTextureIndex;
{
    if (hasSetTexture5)
    {
        return 5;
    }
    else if (hasSetTexture4)
    {
        return 4;
    }
    else if (hasSetTexture3)
    {
        return 3;
    }
    else if (hasSetTexture2)
    {
        return 2;
    }
    else if (hasSetFirstTexture)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    if (textureIndex == 0)
    {
        firstInputFramebuffer = newInputFramebuffer;
        hasSetFirstTexture = YES;
        [firstInputFramebuffer lock];
    }
    else if (textureIndex == 1)
    {
        InputFramebuffer2 = newInputFramebuffer;
        hasSetTexture2 = YES;
        [InputFramebuffer2 lock];
    }
    else if (textureIndex == 2)
    {
        InputFramebuffer3 = newInputFramebuffer;
        hasSetTexture3 = YES;
        [InputFramebuffer3 lock];
    }
    else if (textureIndex == 3)
    {
        InputFramebuffer4 = newInputFramebuffer;
        hasSetTexture4 = YES;
        [InputFramebuffer4 lock];
    }
    else if (textureIndex == 4)
    {
        InputFramebuffer5 = newInputFramebuffer;
        hasSetTexture5 = YES;
        [InputFramebuffer5 lock];
    }
    else if (textureIndex == 5)
    {
        InputFramebuffer6 = newInputFramebuffer;
        [InputFramebuffer6 lock];
    }
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    if (textureIndex == 0)
    {
        [super setInputSize:newSize atIndex:textureIndex];
        
        if (CGSizeEqualToSize(newSize, CGSizeZero))
        {
            hasSetFirstTexture = NO;
            hasSetTexture2 = NO;
            hasSetTexture3 = NO;
            hasSetTexture4 = NO;
            hasSetTexture5 = NO;
        }
    }
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    if (textureIndex == 0)
    {
        inputRotation = newInputRotation;
    }
    else
    {
        inputRotation2 = newInputRotation;
    }
}

- (CGSize)rotatedSize:(CGSize)sizeToRotate forIndex:(NSInteger)textureIndex;
{
    CGSize rotatedSize = sizeToRotate;
    
    GPUImageRotationMode rotationToCheck;
    if (textureIndex == 0)
    {
        rotationToCheck = inputRotation;
    }
    else
    {
        rotationToCheck = inputRotation2;
    }
    
    if (GPUImageRotationSwapsWidthAndHeight(rotationToCheck))
    {
        rotatedSize.width = sizeToRotate.height;
        rotatedSize.height = sizeToRotate.width;
    }
    
    return rotatedSize;
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    // You can set up infinite update loops, so this helps to short circuit them
    if (hasReceivedFirstFrame && hasReceivedFrame2&& hasReceivedFrame3&& hasReceivedFrame4&& hasReceivedFrame5&& hasReceivedFrame6)
    {
        return;
    }
    
    BOOL updatedMovieFrameOppositeStillImage = YES;
    BOOL hasAllReceived = YES;


    
    // || (hasReceivedFirstFrame && secondFrameCheckDisabled) || (hasReceivedSecondFrame && firstFrameCheckDisabled)
    if (hasAllReceived && updatedMovieFrameOppositeStillImage)
    {
        CMTime passOnFrameTime = (!CMTIME_IS_INDEFINITE(firstFrameTime)) ? firstFrameTime : FrameTime2;
        [super newFrameReadyAtTime:passOnFrameTime atIndex:0]; // Bugfix when trying to record: always use time from first input (unless indefinite, in which case use the second input)
        hasReceivedFirstFrame = NO;
        hasReceivedFrame2 = NO;
        hasReceivedFrame3 = NO;
        hasReceivedFrame4 = NO;
        hasReceivedFrame5 = NO;
        hasReceivedFrame6 = NO;
    }
}


- (void)setMix:(GLfloat)newValue{
    _mix = newValue;
    
    [self setFloat:_mix forUniformName:@"mixturePercent"];
}

@end
