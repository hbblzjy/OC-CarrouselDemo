//
//  LYSlider.h
//  FBLedControl
//
//  Created by lxy on 15/10/12.
//  Copyright © 2015年 lxy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class LYSlider;

typedef void(^LYSliderActionBlock)(LYSlider *slider, UIControlEvents event);

@interface LYSlider : UIControl

@property (nonatomic, assign) CGPoint myCenter; //视图中心点
@property (nonatomic, assign) BOOL horizontal;  //是否横向
@property (nonatomic, assign) CGFloat length;   //长度
@property (nonatomic, readonly) CGFloat sliderHeight;//宽度 [水平时-height 竖直时-width]

@property (nonatomic, assign) BOOL showValue;   //是否显示当前值
@property (nonatomic, assign) CGFloat value;    //当前值

@property (nonatomic, strong) UIImage *backimage;   //背景图
@property (nonatomic, strong) UIColor *backcolor;   //背景图颜色
// 以下三属性互斥
@property (nonatomic, strong) UIImage *thumbimage;  //滑动按钮图
@property (nonatomic, strong) UIColor *thumbcolor;  //滑动按钮颜色

@property (nonatomic, strong) NSDictionary *gradientBackInfo; // 渐变色

@property (nonatomic, readonly, getter=isDragging) BOOL isDragging;
@property (nonatomic, readonly, getter=isJustEndDragging) BOOL isJustEndDragging;


/** 事件handle
 *  支持的事件：
 *  UIControlEventTouchDown
 *  UIControlEventValueChanged
 *  UIControlEventTouchUpInside
 *  UIControlEventTouchCancel
 */
- (void)handleSliderAction:(UIControlEvents)events callback:(LYSliderActionBlock)block;
- (void)removeHandleSliderAction:(UIControlEvents)events;
- (void)removeAllHandleSliderAction;

// 初始化
- (LYSlider *)initWithWidth:(CGFloat)length center:(CGPoint)center horizontal:(BOOL)horizon;
- (LYSlider *)initWithWidth:(CGFloat)length center:(CGPoint)center horizontal:(BOOL)horizon showValue:(BOOL)show;

@end













