//
//  IFCharmesFilter.m
//  Lidow
//
//  Created by 吴桐 on 14/11/23.
//  Copyright (c) 2014年 bw. All rights reserved.
//

#import "IFCharmesFilter.h"

NSString *const kIFCharmesShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 //uniform sampler2D inputImageTexture3;
 
 
 // const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 
 uniform lowp float mixturePercent;
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     //     lowp float luminance = dot(textureColor.rgb, luminanceWeighting);
     //     lowp vec3 greyScaleColor = vec3(luminance);
     //     lowp vec4 saturationColor  = vec4(mix(greyScaleColor, textureColor.rgb, 0.0), textureColor.w);
     
     lowp float redCurveValue = texture2D(inputImageTexture2, vec2(textureColor.r, 0.0)).r;
     lowp float greenCurveValue = texture2D(inputImageTexture2, vec2(textureColor.g, 0.5)).g;
     lowp float blueCurveValue = texture2D(inputImageTexture2, vec2(textureColor.b, 1.0)).b;
     lowp vec4 curveColor = vec4(redCurveValue,greenCurveValue,blueCurveValue, textureColor.a);
     
     gl_FragColor =vec4(mix(textureColor.rgb, curveColor.rgb, mixturePercent), textureColor.a);
 }
 );

@implementation IFCharmesFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kIFCharmesShaderString]))
    {
        return nil;
    }
    
    return self;
}
@end
