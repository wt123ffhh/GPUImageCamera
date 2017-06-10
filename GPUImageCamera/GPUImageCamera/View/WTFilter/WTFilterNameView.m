//
//  WTFilterNameView.m
//  MagicPhoto
//
//  Created by 吴桐 on 16/2/29.
//  Copyright © 2016年 charmer. All rights reserved.
//

#import "WTFilterNameView.h"
#import "WTFilterName.h"
#import "WTLabel.h"

@interface WTFilterNameView ()
@property (nonatomic, weak) UILabel *filterLabel;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation WTFilterNameView


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        self.backgroundColor = [UIColor clearColor];
        [self setupFilterLabel];
    }
    return self;
}

- (void)setupFilterLabel {
    WTLabel *filterLabel = [[WTLabel alloc] init];
    filterLabel.frame = self.bounds;
    filterLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:filterLabel];
    self.filterLabel = filterLabel;
    
    filterLabel.textColor = [UIColor whiteColor];
    filterLabel.textAlignment = NSTextAlignmentCenter;
    filterLabel.font = [UIFont systemFontOfSize:60];
    
}

- (void)showFilterLabel:(NSInteger)filterType {
    self.filterLabel.text = [WTFilterName filterNameWith:filterType];
    self.filterLabel.alpha = 1.0;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(filterLabelGone) userInfo:nil repeats:NO];
}

- (void)filterLabelGone {
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        
        self.filterLabel.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
}

@end
