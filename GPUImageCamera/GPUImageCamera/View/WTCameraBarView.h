
//  Created by 吴桐 on 16/2/24.
//  Copyright © 2016年 charmer. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WTCameraBarViewDelegate <NSObject>

- (void)cameraBarBlurBtnClickWithSelc:(BOOL)selc;
- (void)cameraBarVignetteBtnClickWithSelc:(BOOL)selc;
- (void)cameraBarClose;
- (void)cameraBarFliterClick:(NSInteger)number;


@end

@interface WTCameraBarView : UIView

@property (nonatomic, weak) id<WTCameraBarViewDelegate> delegate;

@property (nonatomic, assign) NSInteger selcNumber;

- (void)filterSelcWith:(NSInteger)number;


@property (nonatomic, weak) UIButton *blurBtn;
@property (nonatomic, weak) UIButton *vignetteBtn;

@end
