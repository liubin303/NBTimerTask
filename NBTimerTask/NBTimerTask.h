//
//  NBTimerTask.h
//  Pods
//
//  Created by 刘彬 on 2017/7/7.
//
//

#import <Foundation/Foundation.h>

/*!
 倒计时模式
 */
typedef enum CountDownMode : NSUInteger {
    /*!
     *  @brief 已停止
     */
    CountDownModeFinished,
    /*!
     *  @brief 开始倒计时
     */
    CountDownModeForStartTime,
    /*!
     *  @brief 结束倒计时
     */
    CountDownModeForEndTime,
} CountDownMode;

/*!
 *  @brief 倒计时回调
 *
 *  @param currentTime 当前系统时间
 *  @param mode        倒计时模式
 *  @param days        剩余天
 *  @param hours       剩余小时
 *  @param minutes     剩余分钟
 *  @param seconds     剩余秒
 *  @param stop        是否需要结束倒计时
 */
typedef void(^CountDownTaskHandler)(NSTimeInterval currentTime, CountDownMode mode, long long days,long long hours,long long minutes,long long seconds,BOOL *stop);

/*!
 *  @brief 定时任务回调
 *
 *  @param repeatCount 任务已执行次数
 *  @param stop        是否需要结束任务
 */
typedef void(^TimerTaskHandler)(long long repeatCount, BOOL *stop);

@interface NBTimerTask : NSObject

/*!
 *  @brief 创建一个任务，可用于做心跳、定时任务等，如短信验证码、启动页广告倒计时，需自己处理切到后台停止的问题
 *         会真实创建一个timer，如果生命周期与target不一致需要调用stop方法停止
 *  @param target  执行任务的对象
 *  @param ti      执行任务的时间间隔
 *  @param repeat  是否需要循环执行
 *  @param delay   第一次执行的延迟时间
 *  @param handler 任务block
 *
 *  @return FFTimerTask
 */
- (instancetype)initTimerTaskWithTarget:(id)target
                           timeInterval:(NSTimeInterval)ti
                                repeats:(BOOL)repeat
                             afterDelay:(NSTimeInterval)delay
                                handler:(TimerTaskHandler)handler;

/*!
 *  @brief 停止执行任务
 */
- (void)stopTimerTask;

/*!
 *  @brief 开启一个倒计时任务，一般用于秒杀，闪购等活动的倒计时，不需自己处理切到后台停止的问题，不需要管理生命周期
 *
 *  @param target     倒计时对象
 *  @param startTime  需要倒计时的活动开始时间，没有则传0
 *  @param endTime    需要倒计时的活动结束时间，没有则传0
 *  @param serverTime 服务器当前时间，没有则传0
 *  @param handler    回调
 */
+ (void)countDownTaskWithTarget:(id)target
                      startTime:(NSTimeInterval)startTime
                        endTime:(NSTimeInterval)endTime
                     serverTime:(NSTimeInterval)serverTime
                        handler:(CountDownTaskHandler)handler;


@end
