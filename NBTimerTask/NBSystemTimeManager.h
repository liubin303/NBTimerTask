//
//  NBSystemTimeManager.h
//  Pods
//
//  Created by 刘彬 on 2017/7/7.
//
//

#import <Foundation/Foundation.h>

typedef void(^NBKVOBlock)(id target, id observer, id value, NSDictionary *change);

/*!
 *  @brief 系统时间自我维护manager,会有一个全局的timer
 *         需要不定时与服务器时间同步
 *         如果业务方没有给出servertime，会读取手机本地时间
 */
@interface NBSystemTimeManager : NSObject

/*!
 *  @brief 系统时间
 */
@property (atomic, assign) NSTimeInterval systemTime;

+ (instancetype)sharedInstance;

/*!
 *  @brief 添加一个对系统时间的观察者
 *
 *  @param observer 观察者
 *  @param block    系统时间变化时的回调block
 */
- (void)addObserverForSystemTime:(__weak NSObject *)observer onChanged:(NBKVOBlock)block;

/*!
 *  @brief 移除一个对系统时间的观察者
 *
 *  @param observer 观察者
 */
- (void)removeObserverForSystemTime:(NSObject *)observer;

/*!
 *  @brief app进入前台,timer重启，并用进入后台时记录的时间与当前时间做差值更新一下系统时间
 */
- (void)applicationWillEnterForeground;

/*!
 *  @brief app进入后台,timer暂停，记录一下当前时间
 */
- (void)applicationDidEnterBackground;

@end
