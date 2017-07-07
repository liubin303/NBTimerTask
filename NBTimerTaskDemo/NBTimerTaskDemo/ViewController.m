//
//  ViewController.m
//  NBTimerTaskDemo
//
//  Created by 刘彬 on 2017/7/7.
//  Copyright © 2017年 NB. All rights reserved.
//

#import "ViewController.h"
#import "NBTimerTask.h"
#import "FFUIFactory.h"
#import "SecondViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *timerBtn;
@property (nonatomic, strong) NBTimerTask *timerTask;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.timerBtn];
}

- (void)skipAction{
    self.timerBtn.enabled = NO;
    __weak typeof(self) weakSelf = self;
    self.timerTask = [[NBTimerTask alloc] initTimerTaskWithTarget:self timeInterval:1 repeats:YES afterDelay:0 handler:^(long long repeatCount, BOOL *stop) {
        NSInteger flag = 6-repeatCount;
        weakSelf.timerBtn.ff_disabledTitle = [NSString stringWithFormat:@"%zd",flag];
        if (flag <= 0) {
            *stop = YES;
            weakSelf.timerBtn.ff_normalTitle = @"点击前往";
            weakSelf.timerBtn.enabled = YES;
            weakSelf.timerTask = nil;
            SecondViewController *timerVC = [[SecondViewController alloc] init];
            [weakSelf.navigationController pushViewController:timerVC animated:YES];
        }
    }];
}

- (UIButton *)timerBtn{
    if (_timerBtn == nil) {
        _timerBtn = [UIButton ff_buttonWithSize:CGSizeMake(200, 50) cornerRadius:25 font:[UIFont systemFontOfSize:15] normalColor:[UIColor whiteColor] selectedColor:[UIColor blackColor] disabledColor:[UIColor whiteColor] normalBgColor:[UIColor blackColor] selectedBgColor:[UIColor whiteColor] disabledBgColor:[UIColor blackColor]];
        _timerBtn.ff_center = self.view.ff_center;
        _timerBtn.ff_normalTitle = @"点击前往";
        [_timerBtn ff_addTarget:self touchAction:@selector(skipAction)];
    }
    return _timerBtn;
}


@end
