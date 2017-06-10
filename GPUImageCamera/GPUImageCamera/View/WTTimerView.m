
//  Created by 吴桐 on 16/2/26.
//  Copyright © 2016年 charmer. All rights reserved.
//

#import "WTTimerView.h"
#import "WTLabel.h"

@interface WTTimerView ()
@property (nonatomic, weak) UILabel *timeLabel;
@end

@implementation WTTimerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        self.backgroundColor = [UIColor clearColor];
        [self setupTimeLabel];
    }
    return self;
}

- (void)setupTimeLabel {
    WTLabel *timerLabel = [[WTLabel alloc] init];
    timerLabel.frame = CGRectMake(0, 0, 100, 100);
    timerLabel.backgroundColor = [UIColor clearColor];
    timerLabel.center = self.center;
    [self addSubview:timerLabel];
    
    timerLabel.textColor = [UIColor whiteColor];
    timerLabel.font = [UIFont systemFontOfSize:80];
    timerLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel = timerLabel;
}
- (void)setTimeLabelText:(NSInteger )time {
    self.timeLabel.alpha = 1.0;
    NSString *timeStr = [NSString stringWithFormat:@"%d", (int)time];
    self.timeLabel.text = timeStr;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.8];
    self.timeLabel.alpha = 0.0;
    [UIView commitAnimations];
}

@end
