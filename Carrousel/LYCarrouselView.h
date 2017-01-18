//
//  LYCarrouselView.h
//  TestProject
//
//  Created by LY on 2016/11/7.
//  Copyright © 2016年 LY. All rights reserved.
//

#import <UIKit/UIKit.h>


// index: view/image tag;   event:(1 tap, 2 long press)
typedef void(^CarrouselBlock)(NSInteger index, NSInteger event);

// 旋转木马
@interface LYCarrouselView : UIView

@property (nonatomic, assign) BOOL canAutoRotate;// 自动动画开关
@property (nonatomic, assign) CGFloat sensitivity;// 滑动灵敏度 默认为1 越大越灵敏 0无效 正负影响方向
@property (nonatomic, assign) NSTimeInterval minimumPressTime;// 长按最短时间 超过则视为长按 默认为0.4
@property (nonatomic, assign) CGFloat animationSpeed;//默认为3.0 转过一张图时间

@property (nonatomic, assign) BOOL showReflectLayer;//是否显示倒影层

- (LYCarrouselView *)initWithFrame:(CGRect)frame images:(NSArray *)images callback:(CarrouselBlock)block;

- (void)addImage:(UIImage *)image;

- (void)startRotateRight:(BOOL)right; // 开始动画 (right:是否向右) canAutoRotate=YES
- (void)stopRotate; //停止动画 canAutoRotate=NO

@end



