//
//  SecondViewController.m
//  NBTimerTaskDemo
//
//  Created by 刘彬 on 2017/7/7.
//  Copyright © 2017年 NB. All rights reserved.
//

#import "SecondViewController.h"
#import "NBTimerTask.h"

@interface SecondViewController ()

@property (nonatomic, strong) NBTimerTask *timerTask;
@property (nonatomic, strong) UIButton *msgSendBtn;

@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *dayLabel;
@property (nonatomic, strong) UILabel *hourLabel;
@property (nonatomic, strong) UILabel *minuteLabel;
@property (nonatomic, strong) UILabel *secondLabel;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view, typically from a nib.
    self.statusLabel = [self buildLabelWithOrigin:CGPointMake(10, 100)];
    self.dayLabel = [self buildLabelWithOrigin:CGPointMake(CGRectGetMaxX(self.statusLabel.frame)+10, 100)];
    self.hourLabel = [self buildLabelWithOrigin:CGPointMake(CGRectGetMaxX(self.dayLabel.frame)+10, 100)];
    self.minuteLabel = [self buildLabelWithOrigin:CGPointMake(CGRectGetMaxX(self.hourLabel.frame)+10, 100)];
    self.secondLabel = [self buildLabelWithOrigin:CGPointMake(CGRectGetMaxX(self.minuteLabel.frame)+10, 100)];
    
    
    [self.view addSubview:self.statusLabel];
    [self.view addSubview:self.dayLabel];
    [self.view addSubview:self.hourLabel];
    [self.view addSubview:self.minuteLabel];
    [self.view addSubview:self.secondLabel];
    
    __weak typeof(self) weakSelf = self;
    [NBTimerTask countDownTaskWithTarget:self startTime:1582835068 endTime:1583007868 serverTime:0 handler:^(NSTimeInterval currentTime, CountDownMode mode, long long days, long long hours, long long minutes, long long seconds, BOOL *stop) {
        
        switch (mode) {
            case CountDownModeFinished:{
                weakSelf.statusLabel.text = @"已结束";
                weakSelf.dayLabel.text = @"0";
                weakSelf.hourLabel.text = @"0";
                weakSelf.minuteLabel.text = @"0";
                weakSelf.secondLabel.text = @"0";
                *stop = YES;
                break;
            }
            case CountDownModeForStartTime:{
                weakSelf.statusLabel.text = @"距开始";
                weakSelf.dayLabel.text = [NSString stringWithFormat:@"%lld天",days];
                weakSelf.hourLabel.text = [NSString stringWithFormat:@"%lld：",hours];;
                weakSelf.minuteLabel.text = [NSString stringWithFormat:@"%lld：",minutes];;
                weakSelf.secondLabel.text = [NSString stringWithFormat:@"%lld",seconds];;
                break;
            }
            case CountDownModeForEndTime:{
                weakSelf.statusLabel.text = @"距结束";
                weakSelf.dayLabel.text = [NSString stringWithFormat:@"%lld天",days];;
                weakSelf.hourLabel.text = [NSString stringWithFormat:@"%lld：",hours];;
                weakSelf.minuteLabel.text = [NSString stringWithFormat:@"%lld：",minutes];;
                weakSelf.secondLabel.text = [NSString stringWithFormat:@"%lld",seconds];;
                break;
            }
                
            default:
                break;
        }
    }];
    
    UIButton *msgSendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    msgSendBtn.frame = CGRectMake(100, CGRectGetMaxY(weakSelf.secondLabel.frame)+100, 200, 50);
    [msgSendBtn setTitle:@"发送短信验证码" forState:UIControlStateNormal];
    [msgSendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [msgSendBtn setBackgroundColor:[UIColor blackColor]];
    [msgSendBtn addTarget:self action:@selector(msgSendAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:msgSendBtn];
    
    self.msgSendBtn = msgSendBtn;
}

- (void)msgSendAction{
    __block int count = 60;
    self.msgSendBtn.enabled = NO;
    __weak typeof(self) weakSelf = self;
    self.timerTask = [[NBTimerTask alloc] initTimerTaskWithTarget:self timeInterval:1.0f repeats:YES afterDelay:0 handler:^(long long repeatCount, BOOL *stop) {
        if (count <= 0) {
            [weakSelf.msgSendBtn setTitle:@"重新发送" forState:UIControlStateNormal];
            weakSelf.msgSendBtn.enabled = YES;
            weakSelf.timerTask = nil;
            *stop = YES;
        }else{
            [weakSelf.msgSendBtn setTitle:[NSString stringWithFormat:@"%d",count--] forState:UIControlStateNormal];
        }
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UILabel *)buildLabelWithOrigin:(CGPoint)origin{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(origin.x, origin.y, 60, 50)];
    label.backgroundColor = [UIColor blackColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.masksToBounds = YES;
    label.layer.cornerRadius = 5;
    return label;
}


- (void)dealloc{
    [self.timerTask stopTimerTask];
    NSLog(@"%@ dealloc",[self class]);
}

@end
