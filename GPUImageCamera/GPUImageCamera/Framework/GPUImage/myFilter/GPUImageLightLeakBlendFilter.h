//
//  GPUImageLightLeakBlendFilter.h
//  Lidow
//
//  Created by wt on 15/5/30.
//  Copyright (c) 2015年 bw. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"

@interface GPUImageLightLeakBlendFilter : GPUImageTwoInputFilter{
    GLint mixUniform;
    GLint hueAdjustUniform;
    
    GLint transformMatrixUniform, transformMatrix2Uniform;
//    GPUMatrix4x4 orthographicMatrix;
}
// Mix ranges from 0.0 (only image 1) to 1.0 (only image 2), with 1.0 as the normal level
@property (readwrite, nonatomic) CGFloat mix;
@property (nonatomic, readwrite) CGFloat hue;

// You can either set the transform to apply to be a 2-D affine transform or a 3-D transform. The default is the identity transform (the output image is identical to the input).
@property(readwrite, nonatomic) CGAffineTransform affineTransform;

@property(readwrite, nonatomic) CATransform3D transform3D;
@property(readwrite, nonatomic) CATransform3D transform3D2;

@end
