//
//  GPUImageCamera-Prefix.h
//  GPUImageCamera
//
//  Created by 吴桐 on 2017/6/9.
//  Copyright © 2017年 wtWork. All rights reserved.
//

#ifndef GPUImageCamera_Prefix_h
#define GPUImageCamera_Prefix_h


#define kSWidth     ([UIScreen mainScreen].bounds.size.width)
#define kSHeight    ([UIScreen mainScreen].bounds.size.height)


#define kSScale    ([UIScreen mainScreen].bounds.size.width/320.0)


#ifdef __OBJC__
#include "UIView+Extension.h"
#import "UIColor+Tools.h"
#endif

#endif /* GPUImageCamera_Prefix_h */
