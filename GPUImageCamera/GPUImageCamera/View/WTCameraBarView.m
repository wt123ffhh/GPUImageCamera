
//  Created by 吴桐 on 16/2/24.
//  Copyright © 2016年 charmer. All rights reserved.
//

#import "WTCameraBarView.h"
#import "WTFilterName.h"

@interface WTCameraBarView ()

@property (nonatomic, weak) UIView *backView1;
@property (nonatomic, weak) UIView *backView2;

@property (nonatomic, weak) UIScrollView *filterScr;

@property (nonatomic, weak) UIImageView *selcBtn;

@end

@implementation WTCameraBarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        [self setupBarView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handeleTap:)];
        [self addGestureRecognizer:tap];
        
        UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handeleTap:)];
        [self addGestureRecognizer:tap2];
        [tap2 setNumberOfTapsRequired:2];
    }
    return self;
}

- (void)handeleTap:(UITapGestureRecognizer *)tap {
    
}

- (void)setupBarView {
    
    UIView *backView1 = [[UIView alloc] init];
    backView1.backgroundColor = [UIColor clearColor];
    backView1.frame = CGRectMake(0, 0, kSWidth, 100*kSScale);
    [self addSubview:backView1];
    self.backView1 = backView1;
    
    UIButton *blurBtn = [[UIButton alloc] init];
    blurBtn.frame = CGRectMake(0, 0, 31*kSScale, 31*kSScale);
    blurBtn.center = CGPointMake(29*kSScale, 29*kSScale);
    blurBtn.imageEdgeInsets = UIEdgeInsetsMake(6*kSScale, 4*kSScale, 0, 2*kSScale);
    blurBtn.backgroundColor = [UIColor clearColor];
    [blurBtn setImage:[UIImage imageNamed:@"SeleBlur"] forState:UIControlStateNormal];
    [blurBtn setImage:[UIImage imageNamed:@"SeleBlurSelc"] forState:UIControlStateSelected];
    [backView1 addSubview:blurBtn];
    blurBtn.selected = NO;
    [blurBtn addTarget:self action:@selector(blurBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    self.blurBtn = blurBtn;
    
    UIButton *vignetteBtn = [[UIButton alloc] init];
    vignetteBtn.frame = CGRectMake(0, 0, 31*kSScale, 31*kSScale);
    vignetteBtn.center = CGPointMake(29*kSScale, 70*kSScale);
    vignetteBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 4*kSScale, 6*kSScale, 2*kSScale);
    vignetteBtn.backgroundColor = [UIColor clearColor];
    [vignetteBtn setImage:[UIImage imageNamed:@"vignetteBtn"] forState:UIControlStateNormal];
    [vignetteBtn setImage:[UIImage imageNamed:@"vignetteBtnSelc"] forState:UIControlStateSelected];
    [backView1 addSubview:vignetteBtn];
    vignetteBtn.selected = YES;
    [vignetteBtn addTarget:self action:@selector(vignetteBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    self.vignetteBtn = vignetteBtn;
    
    UIScrollView *scrView = [[UIScrollView alloc] init];
    scrView.backgroundColor = [UIColor clearColor];
    scrView.frame = CGRectMake(60, 18*kSScale, kSWidth-60, 70*kSScale);
    scrView.centerY = backView1.height/2;
    [backView1 addSubview:scrView];
    scrView.showsVerticalScrollIndicator = NO;
    scrView.showsHorizontalScrollIndicator = NO;
    scrView.bounces = NO;
    self.filterScr = scrView;
    
    NSInteger filterNumber = 41;
    
    scrView.contentSize = CGSizeMake(16*kSScale+(50+15)*filterNumber*kSScale, 70*kSScale);
    for (int i=0; i<filterNumber; i++) {
        UIButton *filterBtn = [[UIButton alloc] init];
        filterBtn.frame = CGRectMake(16*kSScale+(50+15)*i*kSScale, 0, 50*kSScale, 50*kSScale);
        filterBtn.layer.cornerRadius = 25*kSScale;
        filterBtn.layer.masksToBounds = YES;
        filterBtn.backgroundColor = [UIColor greenColor];
        [scrView addSubview:filterBtn];
        filterBtn.tag = i;
        [filterBtn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"filtericon%02d", i]] forState:UIControlStateNormal];
        [filterBtn addTarget:self action:@selector(secondaryFilterBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [UIColor clearColor];
        label.frame = CGRectMake(16*kSScale+(50+15)*i*kSScale, 60*kSScale, 50*kSScale, 10*kSScale);
        [scrView addSubview:label];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:9*kSScale];
        //        label.text = [self labelTextWith:btn.tag*100+i];
        label.text = [WTFilterName filterNameWith:i];
        
    }
    
    UIImageView *selcBtn = [[UIImageView alloc] init];
    selcBtn.frame = CGRectMake(0, -50*kSScale, 50*kSScale, 50*kSScale);
    selcBtn.backgroundColor = [UIColor clearColor];
    [selcBtn setImage:[UIImage imageNamed:@"filterSelc"]];
    [scrView addSubview:selcBtn];
    self.selcBtn = selcBtn;
    
}

#pragma mark - 滑动关闭手势
- (void)handleTap:(UISwipeGestureRecognizer *)tap {
//    NSLog(@"==------=");
    if ([self.delegate respondsToSelector:@selector(cameraBarClose)]) {
        [self.delegate cameraBarClose];
    }
    
}

- (void)blurBtnClick:(UIButton *)btn {
    if (btn.selected) {
        btn.selected = NO;
        if ([self.delegate respondsToSelector:@selector(cameraBarBlurBtnClickWithSelc:)]) {
            [self.delegate cameraBarBlurBtnClickWithSelc:NO];
        }
    }else {
        btn.selected = YES;
        if ([self.delegate respondsToSelector:@selector(cameraBarBlurBtnClickWithSelc:)]) {
            [self.delegate cameraBarBlurBtnClickWithSelc:YES];
        }
    }
}
- (void)vignetteBtnClick:(UIButton *)btn {
    if (btn.selected) {
        btn.selected = NO;
        if ([self.delegate respondsToSelector:@selector(cameraBarVignetteBtnClickWithSelc:)]) {
            [self.delegate cameraBarVignetteBtnClickWithSelc:NO];
        }
    }else {
        btn.selected = YES;
        if ([self.delegate respondsToSelector:@selector(cameraBarVignetteBtnClickWithSelc:)]) {
            [self.delegate cameraBarVignetteBtnClickWithSelc:YES];
        }
    }
}
#pragma mark - 二级返回按钮点击事件
- (void)secondaryBackBtnClick {
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.backView1.alpha = 1.0;
        self.backView2.x = kSWidth;
    } completion:^(BOOL finished) {
        [self.backView2 removeFromSuperview];
    }];
    
}
#pragma mark - 滤镜点击
- (void)secondaryFilterBtnClick:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(cameraBarFliterClick:)]) {
        [self.delegate cameraBarFliterClick:btn.tag];
    }
    self.selcBtn.center = btn.center;
}
- (void)filterSelcWith:(NSInteger)number {
    if (number==0) {
        return;
    }
    UIButton *btn = (UIButton *)[self viewWithTag:number];
    if (btn!=nil) {
        self.selcBtn.center = btn.center;
        CGFloat offsetX = btn.center.x-self.filterScr.width/2;
        if (offsetX<0) {
            offsetX = 0;
        } else if (self.filterScr.contentSize.width<offsetX+self.filterScr.width) {
            offsetX = self.filterScr.contentSize.width-self.filterScr.width;
        }        [UIView animateWithDuration:0.3f animations:^{
            self.filterScr.contentOffset = CGPointMake(offsetX, 0);
        }];
    }else {
        self.selcBtn.centerX = -48;
    }
}

@end
