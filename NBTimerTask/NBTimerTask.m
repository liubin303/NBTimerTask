//
//  NBTimerTask.m
//  Pods
//
//  Created by 刘彬 on 2017/7/7.
//
//

#import "NBTimerTask.h"
#import "NBSystemTimeManager.h"

#define daySeconds  (24*60*60)
#define hourSeconds  (60*60)
#define minuteSeconds  (60)

@interface NBTimerTask ()

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, weak  ) id                target;

@end

@implementation NBTimerTask

#pragma mark - 定时任务
- (instancetype)initTimerTaskWithTarget:(id)target
                           timeInterval:(NSTimeInterval)ti
                                repeats:(BOOL)repeat
                             afterDelay:(NSTimeInterval)delay
                                handler:(TimerTaskHandler)handler{
    self = [super init];
    if (self) {
        if(ti <= 0 || !target){
            return self;
        }
        _target = target;
        __block long long repeatCount = 1;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        // 间隔时间
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
        // 创建timer
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
        // 设置timer的触发时间，执行时间间隔
        if(delay > 0){
            dispatch_source_set_timer(_timer,delayTime,ti*NSEC_PER_SEC, 0);
        }
        else{
            dispatch_source_set_timer(_timer,DISPATCH_TIME_NOW,ti*NSEC_PER_SEC, 0);
        }
        
        dispatch_source_set_event_handler(_timer, ^{
            @try {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @try {
                        //timer依赖的对象不存在则停止timer
                        if (!self.target) {
                            [self stopTimerTask];
                            return;
                        }
                        BOOL stop = NO;
                        if (handler) {
                            handler(repeatCount,&stop);
                            //是否立即停止
                            if (stop) {
                                [self stopTimerTask];
                            } else if (!repeat){
                                //是否需要轮询
                                [self stopTimerTask];
                            }
                        }
                    }
                    @catch (NSException *exception) {
#ifdef DEBUG
                        @throw [NSException exceptionWithName:@"FFTimerTask" reason:exception.reason userInfo:exception.userInfo];
#endif
                    }
                });
                repeatCount++;
            }
            @catch (NSException *exception) {
#ifdef DEBUG
                @throw [NSException exceptionWithName:@"FFTimerTask" reason:exception.reason userInfo:exception.userInfo];
#endif
            }
        });
        //取消时的handler
        dispatch_source_set_cancel_handler(_timer, ^{
            
        });
        //启动timer
        dispatch_resume(_timer);
    }
    return self;
}

- (void)stopTimerTask{
    if (self.timer) {
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
}

#pragma mark - 倒计时
+ (void)countDownTaskWithTarget:(id)target
                      startTime:(NSTimeInterval)startTime
                        endTime:(NSTimeInterval)endTime
                     serverTime:(NSTimeInterval)serverTime
                        handler:(CountDownTaskHandler)handler {
    [NBSystemTimeManager sharedInstance].systemTime = serverTime;
    [[NBSystemTimeManager sharedInstance] addObserverForSystemTime:target onChanged:^(id target, id observer, id value, NSDictionary *change) {
        NSNumber *systemValue = value;
        NSTimeInterval currentSystemTime = systemValue.longLongValue;
        CountDownMode mode = CountDownModeFinished; // 倒计时模式
        long long remainSecond = 0;    // 剩余时间
        long long days = 0;
        long long hours = 0;
        long long minutes = 0;
        long long seconds = 0;
        BOOL stop = NO;
        if (startTime > currentSystemTime && endTime > currentSystemTime) { // 未开始
            mode = CountDownModeForStartTime;
            remainSecond = startTime - currentSystemTime;
        } else if (startTime <= currentSystemTime && endTime > currentSystemTime){ // 已开始
            mode = CountDownModeForEndTime;
            remainSecond = endTime - currentSystemTime;
        } else if (startTime < currentSystemTime && endTime <= currentSystemTime){ // 已结束
            mode = CountDownModeFinished;
        }
        // 根据剩余时间计算单位时间
        if (remainSecond > 0 && mode != CountDownModeFinished) {
            days = remainSecond/daySeconds;
            hours = (remainSecond - days*daySeconds)/hourSeconds;
            minutes = (remainSecond - days*daySeconds - hours*hourSeconds)/minuteSeconds;
            seconds = remainSecond%minuteSeconds;
        }else{
            // 倒计时结束，移除kvo
            [[NBSystemTimeManager sharedInstance] removeObserverForSystemTime:observer];
        }
        if (handler) {
            handler(currentSystemTime, mode, days, hours, minutes, seconds, &stop);
            if (stop) {
                // 外部要求停止倒计时，移除kvo
                [[NBSystemTimeManager sharedInstance] removeObserverForSystemTime:observer];
            }
        }
    }];
}

- (void)dealloc{
    NSLog(@"%@ dealloc",[self class]);
}

@end
