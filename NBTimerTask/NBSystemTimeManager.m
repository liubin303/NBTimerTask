//
//  NBSystemTimeManager.m
//  Pods
//
//  Created by 刘彬 on 2017/7/7.
//
//

#import "NBSystemTimeManager.h"
#import "NBTimerTask.h"

@interface FFKVOModel : NSObject
/*!
 *  @brief 观察者
 */
@property (nonatomic, weak) NSObject *observer;
/*!
 *  @brief 回调block
 */
@property (nonatomic, copy) NBKVOBlock callback;

@end

@implementation FFKVOModel

@end

@interface NBSystemTimeManager()
/*!
 *  @brief 观察者集合
 */
@property (nonatomic, strong) NSMutableArray *observerArray;
/*!
 *  @brief 计时器
 */
@property (nonatomic, strong) NBTimerTask *timerTask;
/*!
 *  @brief 切换后台的时间
 */
@property (nonatomic, assign) NSTimeInterval enterBackgroundTime;

@end

@implementation NBSystemTimeManager

@synthesize systemTime = _systemTime;

#pragma mark - life cycle
+ (instancetype)sharedInstance {
    static NBSystemTimeManager *_manager;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _manager = [[NBSystemTimeManager alloc] init];
    });
    
    return _manager;
}

- (void)dealloc{
    [self stopTimer];
}

#pragma mark - private
- (void)startTimer {
    __weak typeof(self) w_self = self;
    self.timerTask = [[NBTimerTask alloc] initTimerTaskWithTarget:self timeInterval:1.0 repeats:YES afterDelay:0 handler:^(long long repeatCount, BOOL *stop) {
        __strong typeof(w_self) self = w_self;
        self.systemTime += 1;
        [self excuteCallbackWithValue:@(self.systemTime) dictionary:@{NSKeyValueChangeNewKey:@(self.systemTime),NSKeyValueChangeOldKey:@(self.systemTime-1)}];
    }];
}

- (void)stopTimer{
    if (self.timerTask) {
        _systemTime = 0;
        [self.timerTask stopTimerTask];
        self.timerTask = nil;
    }
}

- (void)excuteCallbackWithValue:(id)value dictionary:(NSDictionary *)info{
    __weak typeof(self) w_self = self;
    void (^callback)() = ^{
        __strong typeof(w_self) self = w_self;
        [self.observerArray enumerateObjectsUsingBlock:^(FFKVOModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // 观察者已经被释放则移除
            if (obj.observer == nil) {
                [self.observerArray removeObject:obj];
            }else{
                // 执行回调
                if (obj.callback) {
                    obj.callback(self, obj.observer, value, info ? info : [NSDictionary new]);
                }
            }
        }];
    };
    
    if (![[NSThread currentThread] isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), callback);
    } else {
        callback();
    }
}

#pragma mark - public
- (void)addObserverForSystemTime:(__weak NSObject *)observer onChanged:(NBKVOBlock)block {
    if (observer && block) {
        __block BOOL isContains = NO;
        [self.observerArray enumerateObjectsUsingBlock:^(FFKVOModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.observer == observer) {
                isContains = YES;
                *stop = YES;
            }
        }];
        if (!isContains) {
            FFKVOModel *model = [[FFKVOModel alloc] init];
            model.observer = observer;
            model.callback = block;
            [self.observerArray addObject:model];
        }
        // 启动timer
        if (self.timerTask == nil) {
            [self startTimer];
        }
    }
}

- (void)removeObserverForSystemTime:(NSObject *)observer{
    [self.observerArray enumerateObjectsUsingBlock:^(FFKVOModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.observer == nil || obj.observer == observer || obj.callback == nil) {
            [self.observerArray removeObject:obj];
        }
    }];
}

- (void)applicationWillEnterForeground {
    NSTimeInterval currentTime = [[NSDate new] timeIntervalSince1970];
    if (self.enterBackgroundTime > 0 && self.systemTime > 0 && currentTime > self.enterBackgroundTime) {
        self.systemTime += (currentTime-self.enterBackgroundTime);
    }
    self.enterBackgroundTime = 0;
}

- (void)applicationDidEnterBackground {
    self.enterBackgroundTime = [[NSDate new] timeIntervalSince1970];
}

#pragma mark - getter & setter
- (NSMutableArray *)observerArray{
    if (_observerArray == nil) {
        _observerArray = [NSMutableArray array];
    }
    return _observerArray;
}

- (NSTimeInterval)systemTime {
    if (_systemTime <= 0) {
        return [[NSDate new] timeIntervalSince1970];
    } else {
        return _systemTime;
    }
}

- (void)setSystemTime:(NSTimeInterval)systemTime {
    if (systemTime < 0) {
        return;
    }
    if (systemTime <= _systemTime) {
        return;
    }
    // 加入一个时间校准策略，如果跟本地时间差别5秒以内则取本地时间，否则用服务器时间
    NSTimeInterval localTime = [[NSDate new] timeIntervalSince1970];
    NSTimeInterval diffValue = localTime - systemTime;
    if (diffValue > 0 && diffValue < 5) {
        _systemTime = localTime;
    }else{
        _systemTime = systemTime;
    }
}

@end
