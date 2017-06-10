//
//  GPUImageMirrorFilter.m
//  MagicPhoto
//
//  Created by 吴桐 on 16/2/26.
//  Copyright © 2016年 charmer. All rights reserved.
//

#import "GPUImageMirrorFilter.h"

NSString *const kGPUImageMirrorFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform lowp float mirrorType;
 uniform lowp float mixturePercent;
 void main()
 {
     highp vec2 textureCoordinateM = textureCoordinate;
     if(textureCoordinate.x>0.5){textureCoordinateM.x = 1.0- textureCoordinate.x;}
     
     highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinateM);
     gl_FragColor = textureColor;
 }
 );

@implementation GPUImageMirrorFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageMirrorFragmentShaderString]))
    {
        return nil;
    }
    
    return self;
}

@end
