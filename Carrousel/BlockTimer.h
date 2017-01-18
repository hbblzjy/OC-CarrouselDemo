//
//  BlockTimer.h
//  TestProject
//
//  Created by LY on 16/8/18.
//  Copyright © 2016年 LY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

/** return:NO停止 repeatCount:block执行过的次数, timer:定时器对象 istimer:是否NSTimer */
typedef BOOL(^BlockTimerCallback)(NSInteger repeatCount, id timer, BOOL istimer);


@interface BlockTimer : NSObject

@property (nonatomic, readonly) id timer;/* 定时器对象 (NSTimer 或者 CADisplayLink) */
@property (nonatomic, readonly) BOOL istimer;/* 是否是NSTimer */

- (void)invalidate; // 手动关闭定时器

+ (BlockTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti userInfo:(id)userInfo keepon:(BlockTimerCallback)block;

+ (BlockTimer *)timerWithTimeInterval:(NSTimeInterval)ti userInfo:(id)userInfo runloopMode:(NSRunLoopMode)mode keepon:(BlockTimerCallback)block;

+ (BlockTimer *)displayLinkWithFrameInterval:(NSInteger)interval runloopMode:(NSRunLoopMode)mode keepon:(BlockTimerCallback)block;

@end
