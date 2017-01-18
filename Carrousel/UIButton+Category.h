//
//  UIButton+Block.h
//  MyTest
//
//  Created by LY on 16/7/27.
//  Copyright © 2016年 LY. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ButtonActionBlock)(UIControlEvents events);

@interface UIButton (Block_Handle)

/** block处理事件 */
- (void)handleControlEvents:(UIControlEvents)events withBlock:(ButtonActionBlock)block;

/** 移除不需要的 handle block */
- (void)removeHandleForControlEvents:(UIControlEvents)events;

/** 检测events与原有事件集是否有冲突, 有则返回对应冲突事件, 否则返回0 */
- (UIControlEvents)checkEventsClash:(UIControlEvents)events;

@end





