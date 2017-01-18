//
//  BlockTimer.m
//  TestProject
//
//  Created by LY on 16/8/18.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "BlockTimer.h"

@interface BlockTimer ()

@property (nonatomic, copy) BlockTimerCallback block;
@property (nonatomic, assign) NSInteger repeatCount;
@property (nonatomic, strong) NSTimer *myTimer;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) BOOL isNSTimer;

@end

@implementation BlockTimer

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.block = NULL;
        self.repeatCount = 0;
        self.myTimer = nil;
        self.link = nil;
        self.isNSTimer = NO;
    }
    return self;
}

- (void)dealloc
{
    if (self.myTimer)
    {
        [self.myTimer invalidate];
        self.myTimer = nil;
    }
    if (self.link)
    {
        [self.link invalidate];
        self.link = nil;
    }
    self.block = NULL;
}

+ (BlockTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti userInfo:(id)userInfo keepon:(BlockTimerCallback)block
{
    if (block == NULL || ti <= 0)
    {
        return nil;
    }
    BlockTimer *bt = [[BlockTimer alloc] init];
    bt.isNSTimer = YES;
    bt.block = block;
//    NSLog(@"alloc:%@", [NSDate date]);
    bt.myTimer = [NSTimer scheduledTimerWithTimeInterval:ti target:bt selector:@selector(timerEvent) userInfo:userInfo repeats:YES];// scheduled ti秒后启动
    return bt;
}

+ (BlockTimer *)timerWithTimeInterval:(NSTimeInterval)ti userInfo:(id)userInfo runloopMode:(NSRunLoopMode)mode keepon:(BlockTimerCallback)block
{
    if (block == NULL || ti <= 0)
    {
        return nil;
    }
    BlockTimer *bt = [[BlockTimer alloc] init];
    bt.isNSTimer = YES;
    bt.block = block;
//    NSLog(@"alloc:%@", [NSDate date]);
    bt.myTimer = [NSTimer timerWithTimeInterval:ti target:bt selector:@selector(timerEvent) userInfo:userInfo repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:bt.myTimer forMode:mode];
    [bt.myTimer fire];// 用fire立刻开启定时器
    
    return bt;
}

- (void)timerEvent
{
//    NSLog(@"catch:%@", [NSDate date]);
    @synchronized (self) {
        self.repeatCount += 1;
        BOOL res = self.block(self.repeatCount, self.timer, self.isNSTimer);
        if (!res)
        {
            [self.myTimer invalidate];
            self.repeatCount = 0;
            self.myTimer = nil;
            self.block = NULL;
        }
    }
}

+ (BlockTimer *)displayLinkWithFrameInterval:(NSInteger)interval runloopMode:(NSRunLoopMode)mode keepon:(BlockTimerCallback)block
{
    if (block == NULL || interval <= 0)
    {
        return nil;
    }
    BlockTimer *bt = [[BlockTimer alloc] init];
    bt.isNSTimer = NO;
    bt.block = block;
//    NSLog(@"alloc:%@", [NSDate date]);
    bt.link = [CADisplayLink displayLinkWithTarget:bt selector:@selector(displaylinkEvent)];
    [bt.link addToRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
    bt.link.frameInterval = interval;
    return bt;
}

- (void)displaylinkEvent
{
//    NSLog(@"catch:%@", [NSDate date]);
    @synchronized (self) {
        self.repeatCount += 1;
        BOOL res = self.block(self.repeatCount, self.link, self.isNSTimer);
        if (!res)
        {
            [self.link invalidate];
            self.repeatCount = 0;
            self.link = nil;
            self.block = NULL;
        }
    }
}

- (void)invalidate
{
    if (self.isNSTimer)
    {
        [self.myTimer invalidate];
        self.myTimer = nil;
    }
    else
    {
        [self.link invalidate];
        self.link = nil;
    }
}

- (NSTimer *)timer
{
    return self.myTimer;
}

- (BOOL)istimer
{
    return self.isNSTimer;
}

@end



