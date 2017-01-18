//
//  UIButton+Block.m
//  MyTest
//
//  Created by LY on 16/7/27.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "UIButton+Category.h"
#import <objc/runtime.h>

#pragma mark - button拓展-->事件通过block回调
@implementation UIButton (Block_Handle)

#pragma mark - public functions
- (void)handleControlEvents:(UIControlEvents)events withBlock:(ButtonActionBlock)block
{
    UIControlEvents clash = [self checkEventsClash:events];
    if (clash)
    {
        NSString *str = [NSString stringWithFormat:@"event block clash:%lu", (unsigned long)clash];
        NSAssert(false, str);
    }
    NSMutableDictionary *recordDic = [self blockDictionaryRecords];
    [recordDic setObject:block forKey:[NSNumber numberWithUnsignedInteger:events]];
}

- (void)removeHandleForControlEvents:(UIControlEvents)events
{
    NSMutableDictionary *recordDic = [self blockDictionaryRecords];
    NSNumber *key = [NSNumber numberWithUnsignedInteger:events];
    ButtonActionBlock block = recordDic[key];
    if (block != NULL)
    {
        [recordDic removeObjectForKey:key];
        return;
    }
    NSArray *keys = [recordDic allKeys];
    for (NSNumber *ok in keys)
    {
        UIControlEvents evt = [ok unsignedIntegerValue] & events;
        if (evt == 0)
        {
            continue;
        }
        ButtonActionBlock block = recordDic[ok];
        [recordDic removeObjectForKey:ok];
        
        UIControlEvents nkey = [ok unsignedIntegerValue] - evt;
        if (nkey == 0)
        {
            continue;
        }
        NSNumber *nk = [NSNumber numberWithUnsignedInteger:nkey];
        [recordDic setObject:block forKey:nk];
    }
}

#pragma mark - event response --> 回调block
- (void)callActionBlockWithEvent:(UIControlEvents)event
{
    NSMutableDictionary *recordDic = [self blockDictionaryRecords];
    NSArray *keys = [recordDic allKeys];
    NSNumber *thekey = nil;
    for (NSNumber *key in keys)
    {
        NSUInteger evt = [key unsignedIntegerValue];
        if (evt & event)
        {
            thekey = key;
            break;
        }
    }
    if (!thekey)
    {
        return;
    }
    ButtonActionBlock block = [recordDic objectForKey:thekey];
    if (block)
    {
        block(event);
    }
}

#pragma mark - event actions selector
- (void)touchDown:(UIButton *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchDown];
}

- (void)touchDownRepeat:(UIButton *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchDownRepeat];
}

- (void)touchDragInside:(UIButton *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchDragInside];
}

- (void)touchDragOutside:(UIButton *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchDragOutside];
}

- (void)touchDragEnter:(UIButton *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchDragEnter];
}

- (void)touchDragExit:(UIButton *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchDragExit];
}

- (void)touchUpInside:(UIButton *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchUpInside];
}

- (void)touchUpOutside:(UIButton *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchUpOutside];
}

- (void)touchCancel:(UIButton *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchCancel];
}

- (void)primaryActionTriggered:(UIButton *)sender
{
#ifdef __IPHONE_9_0
    [self callActionBlockWithEvent:UIControlEventPrimaryActionTriggered];
#endif
}

#pragma mark - 检测事件冲突
- (UIControlEvents)checkEventsClash:(UIControlEvents)events
{
    NSMutableDictionary *recordDic = [self blockDictionaryRecords];
    UIControlEvents clash = 0;
    NSArray *keys = [recordDic allKeys];
    
    for (NSInteger i = 0; i < 14; i ++)
    {
        NSUInteger bit = 1 << i;
        NSUInteger res = bit & events;
        if (res == 0)
        {
            continue;
        }
        for (NSNumber *key in keys)
        {
            NSUInteger evt = [key unsignedIntegerValue];
            NSUInteger value = evt & bit;
            if (value != 0)
            {
                clash = bit;
                break;
            }
        }
        if (clash)
        {
            break;
        }
    }
    return clash;
}

#pragma mark - runtime block记录容器:可变字典
- (NSMutableDictionary *)blockDictionaryRecords
{
    NSMutableDictionary *bdrd = (NSMutableDictionary *)objc_getAssociatedObject(self, @"block record");
    if (!bdrd)
    {
        NSMutableDictionary *mudic = [NSMutableDictionary dictionaryWithCapacity:1];
        objc_setAssociatedObject(self, @"block record", mudic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        bdrd = (NSMutableDictionary *)objc_getAssociatedObject(self, @"block record");
        [self addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchDownRepeat:) forControlEvents:UIControlEventTouchDownRepeat];
        [self addTarget:self action:@selector(touchDragInside:) forControlEvents:UIControlEventTouchDragInside];
        [self addTarget:self action:@selector(touchDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
        [self addTarget:self action:@selector(touchDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
        [self addTarget:self action:@selector(touchDragExit:) forControlEvents:UIControlEventTouchDragExit];
        [self addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(touchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        [self addTarget:self action:@selector(touchCancel:) forControlEvents:UIControlEventTouchCancel];
#ifdef __IPHONE_9_0
        [self addTarget:self action:@selector(primaryActionTriggered:) forControlEvents:UIControlEventPrimaryActionTriggered];
#endif
    }
    return bdrd;
}

@end






