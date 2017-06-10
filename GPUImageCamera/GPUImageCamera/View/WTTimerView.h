//
//  WTTimerView.h
//  MagicPhoto
//
//  Created by 吴桐 on 16/2/26.
//  Copyright © 2016年 charmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WTTimerView : UIView
@property (nonatomic, assign) NSInteger curTimer;

- (void)setTimeLabelText:(NSInteger )time;
@end
