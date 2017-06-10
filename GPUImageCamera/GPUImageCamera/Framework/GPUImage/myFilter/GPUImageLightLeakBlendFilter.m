//
//  GPUImageLightLeakBlendFilter.m
//  Lidow
//
//  Created by wt on 15/5/30.
//  Copyright (c) 2015年 bw. All rights reserved.
//

#import "GPUImageLightLeakBlendFilter.h"

NSString *const kGPUImageLightLeakBlendVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 attribute vec4 inputTextureCoordinate2;

 uniform mat4 transformMatrix;
 uniform mat4 transformMatrix2;

 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 void main()
 {
     gl_Position = transformMatrix * vec4(position.xyz, 1.0);
     textureCoordinate = inputTextureCoordinate.xy;
     vec4 pos2 = transformMatrix2 * vec4(inputTextureCoordinate2.xy,1.0,1.0);
     textureCoordinate2 = pos2.xy;
 }
);

NSString *const kGPUImageLightLeakBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform lowp float mixturePercent;
 
 precision highp float;

 uniform mediump float hueAdjust;
 const highp vec4 kRGBToYPrime = vec4 (0.299, 0.587, 0.114, 0.0);
 const highp vec4 kRGBToI = vec4 (0.595716, -0.274453, -0.321263, 0.0);
 const highp vec4 kRGBToQ = vec4 (0.211456, -0.522591, 0.31135, 0.0);
 
 const highp vec4 kYIQToR = vec4 (1.0, 0.9563, 0.6210, 0.0);
 const highp vec4 kYIQToG = vec4 (1.0, -0.2721, -0.6474, 0.0);
 const highp vec4 kYIQToB = vec4 (1.0, -1.1070, 1.7046, 0.0);
 void main()
 {
     // Sample the input pixel
     mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     
     // Convert to YIQ
     highp float YPrime = dot (textureColor2, kRGBToYPrime);
     highp float I = dot (textureColor2, kRGBToI);
     highp float Q = dot (textureColor2, kRGBToQ);
     
     // Calculate the hue and chroma
     highp float hue = atan (Q, I);
     highp float chroma = sqrt (I * I + Q * Q);
     
     // Make the user's adjustments
     hue += (-hueAdjust); //why negative rotation?
     
     // Convert back to YIQ
     Q = chroma * sin (hue);
     I = chroma * cos (hue);
     
     
     if(textureColor2.r==0.0&&textureColor2.g==0.0&&textureColor2.b==0.0){
         textureColor2.r = 1.0;
         textureColor2.g = 1.0;
         textureColor2.b = 1.0;
     }
     else {
         highp vec4 yIQ = vec4 (YPrime, I, Q, 0.0);
         textureColor2.r = dot (yIQ, kYIQToR);
         textureColor2.g = dot (yIQ, kYIQToG);
         textureColor2.b = dot (yIQ, kYIQToB);
     }
     mediump vec4 whiteColor = vec4(1.0);
     lowp vec4 textureColor3 = whiteColor - ((whiteColor - textureColor2) * (whiteColor - textureColor));
     if(textureColor2.r==1.0&&textureColor2.g==1.0&&textureColor2.b==1.0){
        gl_FragColor=textureColor;
     }else{
        gl_FragColor =vec4(mix(textureColor.rgb, textureColor3.rgb, textureColor3.a*mixturePercent), textureColor.a);
     }

 }
 );
@implementation GPUImageLightLeakBlendFilter
@synthesize hue;
@synthesize transform3D = _transform3D;
@synthesize transform3D2 = _transform3D2;
@synthesize affineTransform;
- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageLightLeakBlendVertexShaderString fragmentShaderFromString:kGPUImageLightLeakBlendFragmentShaderString]))
    {
        return nil;
    }
    
    transformMatrixUniform = [filterProgram uniformIndex:@"transformMatrix"];
    transformMatrix2Uniform = [filterProgram uniformIndex:@"transformMatrix2"];
    
    self.transform3D = CATransform3DIdentity;
    self.transform3D2 = CATransform3DIdentity;
    
    mixUniform = [filterProgram uniformIndex:@"mixturePercent"];
    self.mix = 1.0;
    
    hueAdjustUniform = [filterProgram uniformIndex:@"hueAdjust"];
    self.hue = 0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setMix:(CGFloat)newValue;
{
    _mix = newValue;
    
    [self setFloat:_mix forUniform:mixUniform program:filterProgram];
}

- (void)setHue:(CGFloat)newHue
{
    // Convert degrees to radians for hue rotation
    hue = fmodf(newHue, 360.0) * M_PI/180;
    [self setFloat:hue forUniform:hueAdjustUniform program:filterProgram];
}


- (void)convert3DTransform:(CATransform3D *)transform3D toMatrix:(GPUMatrix4x4 *)matrix;
{
    
    GLfloat *mappedMatrix = (GLfloat *)matrix;
    
    mappedMatrix[0] = (GLfloat)transform3D->m11;
    mappedMatrix[1] = (GLfloat)transform3D->m12;
    mappedMatrix[2] = (GLfloat)transform3D->m13;
    mappedMatrix[3] = (GLfloat)transform3D->m14;
    mappedMatrix[4] = (GLfloat)transform3D->m21;
    mappedMatrix[5] = (GLfloat)transform3D->m22;
    mappedMatrix[6] = (GLfloat)transform3D->m23;
    mappedMatrix[7] = (GLfloat)transform3D->m24;
    mappedMatrix[8] = (GLfloat)transform3D->m31;
    mappedMatrix[9] = (GLfloat)transform3D->m32;
    mappedMatrix[10] = (GLfloat)transform3D->m33;
    mappedMatrix[11] = (GLfloat)transform3D->m34;
    mappedMatrix[12] = (GLfloat)transform3D->m41;
    mappedMatrix[13] = (GLfloat)transform3D->m42;
    mappedMatrix[14] = (GLfloat)transform3D->m43;
    mappedMatrix[15] = (GLfloat)transform3D->m44;
}
#pragma mark -
#pragma mark Accessors

- (void)setAffineTransform:(CGAffineTransform)newValue;
{
    self.transform3D = CATransform3DMakeAffineTransform(newValue);
}
- (CGAffineTransform)affineTransform;
{
    return CATransform3DGetAffineTransform(self.transform3D);
}
- (void)setTransform3D:(CATransform3D)newValue;
{
    _transform3D = CATransform3DIdentity;
    _transform3D2 = newValue;
    
    GPUMatrix4x4 temporaryMatrix;
    GPUMatrix4x4 temporaryMatrix2;
    
    [self convert3DTransform:&_transform3D2 toMatrix:&temporaryMatrix2];
    [self convert3DTransform:&_transform3D toMatrix:&temporaryMatrix];
    [self setMatrix4f:temporaryMatrix2 forUniform:transformMatrix2Uniform program:filterProgram];
    [self setMatrix4f:temporaryMatrix forUniform:transformMatrixUniform program:filterProgram];
}


@end
