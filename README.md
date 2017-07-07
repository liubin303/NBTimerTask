# 控制了时间，就控制了一切
##简介
TimerTask是一个面向业务工程师的高效、简单、低风险的定时任务统一解决方案，能应对项目中各种倒计时、心跳、定时任务等需求。

##现状
业务开发过程中，我们常常需要在某个时间后执行某个方法，或者是按照某个周期一直执行某个方法。在这个时候，我们就需要用到定时器。

* (\\[NSTimer )(.*)(TimerWithTimeInterval\\:)
> 78 results in 66 files 

* (\\[)(.* )(addTimer\:)(.* )(forMode\\:) 
> 44 results in 38 files
> NSRunLoopCommonModes/NSDefaultRunLoopMode/UITrackingRunLoopMode

* 不必要的性能损耗
* 定制复杂，代码冗余度高
* 有风险
* 方案多元，不统一

##方案及实现

### 为什么选择dispatch source
|   | 执行环境 | 执行方式 | 是否可取消 | 精度
| --- | --- | --- | --- | :-- |
| sleep | 任意线程 | 阻塞执行 | N | 高
| CADisplayLink | 主线程，依赖RunLoop | 非阻塞执行 | Y | 非常高
| NSDelayedPerforming | 主线程，依赖RunLoop | 非阻塞执行 | Y | 一般
| dispatch_after | 任意线程 | 非阻塞执行 | N | 高
| NSTimer  | 任意线程，依赖RunLoop | 非阻塞执行 | Y | 一般
| dispatch source | 任意线程 | 非阻塞执行 | Y | 高


`NSTimer`是对`CFRunLoopTimer`的上层封装，是基于时间的调用。CFRunLoopTimerRef包含一个时间长度和一个回调（函数指针）。当其加入到 RunLoop 时，RunLoop会注册对应的时间点，当时间点到时，RunLoop会被唤醒以执行那个回调。不管是一次性的还是周期性的timer的实际触发事件的时间，都会与所加入的RunLoop和RunLoop Mode有关，如果此时RunLoop正在执行一个连续性的运算，timer就会被延时触发。重复性的timer遇到这种情况，如果延迟超过了一个周期，则会在延时结束后立刻执行，并按照之前指定的周期继续执行。

`dispatch source`是系统级别处理相关事件的方案，当你配置一个dispatch source时，你指定要监测的事件、dispatch queue、以及处理事件的代码(block或函数)。当事件发生时，dispatch source会提交你的block或函数到指定的queue去执行。

和手工提交到queue的任务不同，dispatch source为应用提供连续的事件源。除非你显式地取消，dispatch source会一直保留与dispatch queue的关联。只要相应的事件发生，就会提交关联的代码到dispatch queue去执行。

为了防止事件积压到dispatch queue，dispatch source实现了事件合并机制。如果新事件在上一个事件处理器出列并执行之前到达，dispatch source会将新旧事件的数据合并。根据事件类型的不同，合并操作可能会替换旧事件，或者更新旧事件的信息。

### 统一管理系统（服务器）时间
将原来哪里有倒计时哪里就有Timer的方式改成使用一个Timer来自动管理系统时间，以模拟KVO的方式来将需要监听系统时间的对象注册进来，当系统时间变化时通知监听方，Timer的运行条件是至少有一个监听者。

> 如果业务方提供了准确的服务器时间会优先使用服务器时间，否则使用本地时间。

### 解决程序挂起时定时器暂停的问题
倒计时业务不再需要关心程序挂起时倒计时暂停的问题，由`FFSystemTimeManager`来管理。

定时任务业务需要自己fix这个问题。

##引用
*  将 NBTimerTask 这个「文件夹」以及NBTimerTask.podspec拖拽到项目平级目录中,然后修改Podfile文件。

```
pod 'NBTimerTask', :path => '../'
```
*  直接将 NBTimerTask 这个「文件夹」add到项目中

##使用

AppDelegate.m中需要注入生命周期方法

``` objc
#import "NBSystemTimeManager.h"

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[NBSystemTimeManager sharedInstance] applicationDidEnterBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NBSystemTimeManager sharedInstance] applicationWillEnterForeground];
}
```

必要时需要重新更新一下systemTime(比如每次api请求返回结果中都带一个服务器时间同步到客户端，保证时间准确性)


```objc
[NBSystemTimeManager sharedInstance].systemTime = 1582835068;
```

* 倒计时

``` objc
#import "NBTimerTask.h"

__weak typeof(self) weakSelf = self;
[NBTimerTask countDownTaskWithTarget:self startTime:1582835068 endTime:1583007868 serverTime:0 handler:^(NSTimeInterval currentTime, CountDownMode mode, long long days, long long hours, long long minutes, long long seconds, BOOL *stop) {
        switch (mode) {
            // 倒计时结束
            case CountDownModeFinished:{
                weakSelf.statusLabel.text = @"已结束";
                weakSelf.dayLabel.text = @"0";
                weakSelf.hourLabel.text = @"0";
                weakSelf.minuteLabel.text = @"0";
                weakSelf.secondLabel.text = @"0";
                *stop = YES;
                break;
            }
            // 开始时间倒计时
            case CountDownModeForStartTime:{
                weakSelf.statusLabel.text = @"距开始";
                weakSelf.dayLabel.text = [NSString stringWithFormat:@"%lld天",days];
                weakSelf.hourLabel.text = [NSString stringWithFormat:@"%lld：",hours];;
                weakSelf.minuteLabel.text = [NSString stringWithFormat:@"%lld：",minutes];;
                weakSelf.secondLabel.text = [NSString stringWithFormat:@"%lld",seconds];;
                break;
            }
            // 结束时间倒计时
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
```


* 定时任务

``` objc
#import "NBTimerTask.h"

    __weak typeof(self) weakSelf = self;
    self.timerTask = [[NBTimerTask alloc] initTimerTaskWithTarget:self timeInterval:1 repeats:YES afterDelay:0 handler:^(long long repeatCount, BOOL *stop) {
        // 执行5次后停止
        if (repeatCount >= 5) {
            *stop = YES;
        }
    }];

```
``` objc
[self.timerTask stopTimerTask];
```


                                










