//
//  LYCarrouselView.m
//  TestProject
//
//  Created by LY on 2016/11/7.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "LYCarrouselView.h"
#import "BlockTimer.h"

#define DebugLog(fmt, ...)  NSLog((@"[DEBUG]%s " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__);

#define kRadainWithNum(n)   (M_PI * 2 / (n))
#define kBaseWidth          0.3
#define kAngelToRad(a)      ((a) * M_PI / 180.0)
#define kRadToAngel(r)      ((r) * 180.0 / M_PI)

@class CarrouselImageView;
@protocol CarrouselImageViewProtocal <NSObject>

- (void)animationDidStartInView:(CarrouselImageView *)view;
- (void)animationDidStopInView:(CarrouselImageView *)view finished:(BOOL)flag;

@end

@interface CarrouselImageView : UIImageView<CAAnimationDelegate>
@property (nonatomic, weak) id <CarrouselImageViewProtocal>delegate;
@property (nonatomic, assign) BOOL animationCompleted;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, assign) BOOL showReflect;
@property (nonatomic, strong) CALayer *reflectLayer;
@end

@implementation CarrouselImageView

#pragma mark - CAAnimationDelegate
- (void)animationDidStart:(CAAnimation *)anim
{
    self.animationCompleted = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(animationDidStartInView:)])
    {
        [self.delegate animationDidStartInView:self];
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    self.animationCompleted = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(animationDidStopInView:finished:)])
    {
        [self.delegate animationDidStopInView:self finished:flag];
    }
}

- (void)setIndex:(NSInteger)index
{
    _index = index;
    self.tag = index;
    [self.label setText:[NSString stringWithFormat:@"%ld", (long)index]];
}

- (UILabel *)label
{
    if (_label == nil)
    {
        _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 18, 18)];
        _label.textColor = [UIColor greenColor];
        _label.backgroundColor = [UIColor clearColor];
        _label.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
        [self addSubview:_label];
    }
    return _label;
}

- (void)setShowReflect:(BOOL)showReflect
{
    if (_showReflect == showReflect)
    {
        return;
    }
    _showReflect = showReflect;
    if (showReflect)
    {
        [self.layer addSublayer:self.reflectLayer];
    }
    else
    {
        [self.reflectLayer removeFromSuperlayer];
    }
}

- (CALayer *)reflectLayer
{
    // Reflection Layer 倒影层
    if (_reflectLayer == nil)
    {
        CGFloat h = self.bounds.size.height / 2;
        CGFloat w = self.bounds.size.width / 2;
        CALayer *layer = [CALayer layer];
        layer.contents = (id)self.image.CGImage;
        layer.bounds = self.bounds;
        layer.position = CGPointMake(w, h);
        layer.opacity = 0.5;
        
        CATransform3D transfrom = CATransform3DIdentity;
//        transfrom = CATransform3DTranslate(transfrom, 0, h * (2.5 - sqrt(3) / 2) , 0);
        transfrom = CATransform3DTranslate(transfrom, 0, h + 10, 0);
        transfrom = CATransform3DRotate(transfrom, kAngelToRad(210), 1, 0, 0);
        transfrom = CATransform3DScale(transfrom, 1, 0.3, 1);
        layer.transform = transfrom;
        
        self.layer.masksToBounds = NO;
        
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.bounds = layer.bounds;
        gradientLayer.position = CGPointMake(w, h);
        gradientLayer.colors = @[(id)[[UIColor clearColor] CGColor],(id)[[UIColor whiteColor] CGColor]];
        gradientLayer.startPoint = CGPointMake(0.5, 0.0);
        gradientLayer.endPoint = CGPointMake(0.5, 0.2);
        layer.mask = gradientLayer;
        _reflectLayer = layer;
    }
    return _reflectLayer;
}

@end


@interface LYCarrouselView ()<CarrouselImageViewProtocal>

@property (nonatomic, copy) CarrouselBlock block;

@property (nonatomic, strong) NSMutableArray *datasource;//views

@property (nonatomic, assign) BOOL touchesMoved;
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGPoint movedPoint;

@property (nonatomic, assign) CGFloat currentOffset;
@property (nonatomic, assign) CGFloat lastOffset;

@property (nonatomic, readonly) CGFloat lastAutoOffset;

@property (nonatomic, assign) BOOL swipeToRight;//滑动方向

@property (nonatomic, strong) BlockTimer *timer;  // 自动旋转定时器

@end

@implementation LYCarrouselView
{
    NSDate *startDate;
    NSDate *stopDate;
}

#pragma mark - public methods
- (LYCarrouselView *)initWithFrame:(CGRect)frame images:(NSArray *)images callback:(CarrouselBlock)block
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.showReflectLayer = NO;
        self.touchesMoved = NO;
        self.startPoint = CGPointZero;
        self.movedPoint = CGPointZero;
        self.currentOffset = 0;
        self.lastOffset = 0;
        self.sensitivity = 1;
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.borderWidth = 1 / [[UIScreen mainScreen] scale];
        self.layer.masksToBounds = YES;
        self.minimumPressTime = 0.4;
        self.animationSpeed = 3.0;
        NSArray *subviews = [self viewsForImages:images];
        for (UIView *view in subviews)
        {
            [self addSubview:view];
        }
        [self.datasource addObjectsFromArray:subviews];
        self.block = block;
        [self resetSubViewTransform3D];
        [self startRotateRight:NO];
    }
    return self;
}

- (void)addImage:(UIImage *)image
{
    CarrouselImageView *view = [self viewWithImage:image];
    view.index = self.datasource.count;
    [self.datasource addObject:view];
    [self addSubview:view];
    [self resetSubViewTransform3D];
}

- (void)startRotateRight:(BOOL)right
{
    self.swipeToRight = right;
    self.canAutoRotate = YES;
}

- (void)stopRotate
{
    self.canAutoRotate = NO;
}

#pragma mark - touches
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    startDate = [NSDate date];
    [self endTimerRemoveAnimation:YES];
    self.lastOffset = self.currentOffset;
    self.touchesMoved = NO;
    self.startPoint = [[touches anyObject] locationInView:self];
    self.movedPoint = self.startPoint;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.touchesMoved = YES;
    CGPoint point = [[touches anyObject] locationInView:self];
    CGFloat offset = point.x - self.startPoint.x;
    CGFloat angel = kAngelToRad(offset * self.sensitivity / 3);
    
    BOOL isright = (point.x - self.movedPoint.x) > 0;//向右滑动
    if (isright != self.swipeToRight)//转向
    {
        self.swipeToRight = isright;
        self.startPoint = self.movedPoint;
    }
    self.movedPoint = point;
    [self processCarrouselWithOffset:angel];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.touchesMoved = YES;
    [self touchesEnded:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.touchesMoved)
    {
        CGPoint point = [[touches anyObject] locationInView:self];
        CGFloat offset = point.x - self.startPoint.x;
        CGFloat angel = kAngelToRad(offset * self.sensitivity / 3);
        self.swipeToRight = angel > 0;
        
        [self processCarrouselWithOffset:angel];
        self.lastOffset = self.currentOffset;
        self.touchesMoved = NO;
    }
    else
    {
        CarrouselImageView *view = [self itemViewAtPoint:self.startPoint];
        stopDate = [NSDate date];
        NSTimeInterval time = [stopDate timeIntervalSinceDate:startDate];
        [self processCarrouselActioinForViewIndex:view.index InTimeInterval:time];
    }
    [self resetSubViewTransform3D];
    [LYCarrouselView cancelAndRestartPerformSelector:@selector(restartAutoRotateTimer) target:self object:nil delay:4];
}

+ (void)cancelAndRestartPerformSelector:(SEL)fun target:(id)target object:(id)object delay:(NSTimeInterval)delay
{
    if (target == nil) return;
    [NSObject cancelPreviousPerformRequestsWithTarget:target selector:fun object:nil];
    [target performSelector:fun withObject:object afterDelay:delay];
}

#pragma mark - touches affect methods
- (void)restartAutoRotateTimer
{
    if (self.canAutoRotate)
    {
        [self startTimer];
    }
}

// 旋转
- (void)processCarrouselWithOffset:(CGFloat)angel
{
    for (NSInteger i = 0; i < self.datasource.count; i ++)
    {
        [self rotateViewAtIndex:i keyframeAnimation:NO];
    }
    self.currentOffset = angel + self.lastOffset;
}

// 点击
- (void)processCarrouselActioinForViewIndex:(NSInteger)index InTimeInterval:(NSTimeInterval)timeinterval
{
    if (self.block)
    {
        NSInteger action = timeinterval > self.minimumPressTime ? 2 : 1;
        self.block(index, action);
    }
//    NSLog(@"%f %f index:%ld", count, touchx, index);
}

#pragma mark - timer
- (void)startTimer
{
    [self endTimerRemoveAnimation:NO];
    [self resetSubViewTransform3D];
    __weak typeof(self) weakself = self;
    self.timer = [BlockTimer displayLinkWithFrameInterval:60 runloopMode:NSRunLoopCommonModes keepon:^BOOL(NSInteger repeatCount, id timer, BOOL istimer) {
        
        [weakself autoRotateOnce];
        return YES;// 手势较快时 因为定时特性可能延迟导致错误而未关闭上次定时器 故手动关闭
    }];
}

- (void)endTimerRemoveAnimation:(BOOL)remove
{
    if (self.timer)
    {
        [self.timer invalidate];
        self.timer = nil;
    }
    if (!remove) return;
    // 以下代码立即停止动画 突变至结果位置
    for (NSInteger i = 0; i < self.datasource.count; i ++)
    {
        UIView *view = self.datasource[i];
        [view.layer removeAllAnimations];
    }
}

#pragma mark - layout subviews in 3d circle
- (void)resetSubViewTransform3D
{
    for (NSInteger i = 0; i < self.datasource.count; i ++)
    {
        CATransform3D t3d = [self transform3DForViewIndex:i frame:0];
        CarrouselImageView *view = self.datasource[i];
        view.layer.transform = t3d;
        view.showReflect = self.showReflectLayer;
    }
}
#pragma mark - CarrouselImageViewProtocal
- (void)animationDidStartInView:(CarrouselImageView *)view
{
    NSInteger index = [self.datasource indexOfObject:view];
    CATransform3D t3d = [self transform3DForViewIndex:index frame:0];
    view.layer.transform = t3d;
}

- (void)animationDidStopInView:(CarrouselImageView *)view finished:(BOOL)flag
{
    // 在结束这里设置属性值 会导致动画启动最开始有一次卡顿, 放在开始方法里面解决问题
}

- (void)autoRotateOnce
{
    for (NSInteger i = 0; i < self.datasource.count; i ++)
    {
        [self rotateViewAtIndex:i keyframeAnimation:YES];//self.datasource.count - 1 -
    }
    self.currentOffset += self.lastAutoOffset;
}

- (void)rotateViewAtIndex:(NSInteger)index keyframeAnimation:(BOOL)animation
{
    CarrouselImageView *view = self.datasource[index];
    if (animation)
    {
        CAKeyframeAnimation *t = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        t.duration = 1.f;
        t.repeatCount = 0;
        t.values = [self keyframeValuesForViewIndex:index];
        t.keyTimes = [self keyframeTimesForViewIndex:index];
        t.delegate = view;
        [view.layer addAnimation:t forKey:@"animation"];
    }
    else
    {
        CGFloat offset = self.currentOffset;//
        CATransform3D t3d = [self transform3DForViewIndex:index offset:offset];
        view.layer.transform = t3d;
    }
}

- (NSArray *)keyframeValuesForViewIndex:(NSInteger)index
{
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0; i < self.datasource.count + 1; i ++)
    {
        [array addObject:[NSValue valueWithCATransform3D:[self transform3DForViewIndex:index frame:i]]];
    }
    return array;
}

- (CATransform3D)transform3DForViewIndex:(NSInteger)index frame:(NSInteger)frame
{
    CGFloat steper = self.lastAutoOffset / self.datasource.count;
    CGFloat offset = steper * frame + self.currentOffset;
    CATransform3D t3d = [self transform3DForViewIndex:index offset:offset];
    return t3d;
}

- (CATransform3D)transform3DForViewIndex:(NSInteger)index offset:(CGFloat)offset
{
    CGFloat w = self.bounds.size.width * kBaseWidth;
    CGFloat r = w / 2 / tan(kRadainWithNum(self.datasource.count) / 2) + 20;
    
    CGFloat rad_inx = kRadainWithNum(self.datasource.count) * index;
    CGFloat radian = rad_inx + offset;
    
    CATransform3D t3d = CATransform3DIdentity;
    t3d.m34 = - 1 / 600.;
    t3d = CATransform3DRotate(t3d, radian, 0, 1, 0);
    t3d = CATransform3DTranslate(t3d, 0, 0, r);
    
    return t3d;
}

- (NSArray *)keyframeTimesForViewIndex:(NSInteger)index
{
    static NSMutableArray *array = nil;
    if (array == nil || array.count != self.datasource.count + 1)
    {
        array = [NSMutableArray array];
        CGFloat depper = 1.0 / self.datasource.count;
        for (NSInteger i = 0; i < self.datasource.count + 1; i ++)
        {
            [array addObject:@(depper * i)];
        }
    }
    return array;
}

#pragma mark - setters getters
- (NSMutableArray *)datasource
{
    if (_datasource == nil)
    {
        _datasource = [NSMutableArray array];
    }
    return _datasource;
}

- (NSArray *)viewsForImages:(NSArray *)images
{
    NSMutableArray *array = [NSMutableArray array];
    NSInteger index = 0;
    for (UIImage *image in images)
    {
        CarrouselImageView *view = [self viewWithImage:image];
        view.index = index;
        index ++;
        [array addObject:view];
    }
    return array;
}

- (CarrouselImageView *)viewWithImage:(UIImage *)image
{
    CGFloat imgw = image.size.width;
    CGFloat imgh = image.size.height;
    
    // 宽度一定 高度按照原图片宽高比设定
    CGRect frame = self.bounds;
    CGFloat w = frame.size.width * kBaseWidth;
    CGFloat h = MIN(w * imgh / imgw, frame.size.height - 10);
    CGFloat x = frame.size.width * (1 - kBaseWidth) / 2;
    CGFloat y = (frame.size.height - h) / 2;
    CarrouselImageView *imv = [[CarrouselImageView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    imv.showReflect = self.showReflectLayer;
    imv.delegate = self;
    imv.backgroundColor = [UIColor magentaColor];
    imv.image = image;
    imv.contentMode = UIViewContentModeScaleToFill;// 铺满
    return imv;
}

- (CGFloat)lastAutoOffset
{
    // 每3秒转过一张图片
    return kAngelToRad(360 / self.datasource.count / self.animationSpeed) * (self.swipeToRight ? 1 : -1);
}

- (void)setCanAutoRotate:(BOOL)canAutoRotate
{
    if (_canAutoRotate == canAutoRotate || self.touchesMoved)// 手动操作
    {
        return;
    }
    _canAutoRotate = canAutoRotate;
    if (_canAutoRotate)
    {
        [self startTimer];
    }
    else
    {
        [self endTimerRemoveAnimation:NO];
    }
}

- (void)setAnimationSpeed:(CGFloat)animationSpeed
{
    if (_animationSpeed == animationSpeed)
    {
        return;
    }
    // 限制在0.2~6s
    animationSpeed = MIN(MAX(0.2, animationSpeed), 6);
    _animationSpeed = animationSpeed;
}

- (void)setShowReflectLayer:(BOOL)showReflectLayer
{
    if (_showReflectLayer == showReflectLayer)
    {
        return;
    }
    _showReflectLayer = showReflectLayer;
    [self resetSubViewTransform3D];
}

- (void)dealloc
{
    if (self.timer)
    {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - 获取点击 或 长按视图
- (CarrouselImageView *)itemViewAtPoint:(CGPoint)point
{
    NSArray *array = [self.datasource sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))compareViewDepth context:(__bridge void *)self];
//    for (NSInteger i = 0; i < array.count; i ++)
//    {
//        CarrouselImageView *v = array[i];
//        NSLog(@"index:%d", v.index);
//    }
    for (CarrouselImageView *view in [array reverseObjectEnumerator])
    {
        if ([view.layer hitTest:point])
        {
            return view;
        }
    }
    return nil;
}

NSComparisonResult compareViewDepth(UIView *view1, UIView *view2, LYCarrouselView *self)
{
    //compare depths
    CATransform3D t1 = view1.layer.transform;
    CATransform3D t2 = view2.layer.transform;
    CGFloat z1 = t1.m13 + t1.m23 + t1.m33 + t1.m43;
    CGFloat z2 = t2.m13 + t2.m23 + t2.m33 + t2.m43;
    CGFloat difference = z1 - z2;
    
    //if depths are equal, compare distance from current view
    if (difference == 0.0)
    {
        CATransform3D t3 = [self currentItemView].layer.transform;
        CGFloat x1 = t1.m11 + t1.m21 + t1.m31 + t1.m41;
        CGFloat x2 = t2.m11 + t2.m21 + t2.m31 + t2.m41;
        CGFloat x3 = t3.m11 + t3.m21 + t3.m31 + t3.m41;
        difference = fabs(x2 - x3) - fabs(x1 - x3);
    }
    return (difference < 0.0)? NSOrderedAscending: NSOrderedDescending;
}

- (CarrouselImageView *)currentItemView
{
    CGFloat offnum = [self excessFloat:self.currentOffset base:2 * M_PI] / kAngelToRad(360 / self.datasource.count);//转过的个数 0~count
    NSInteger index = (NSInteger)offnum;
    index = self.datasource.count - 1 - index;
//    NSLog(@"offnum:%f index:%d", offnum, index);
    CarrouselImageView *view = self.datasource[index];
    return view;
}

- (CGFloat)excessFloat:(CGFloat)d base:(CGFloat)b
{
    b = fabs(b);
    NSInteger n = fabs(d / b);
    CGFloat excess = d - n * b;
    if (d < 0)
    {
        n = n + 1;
        excess = d + n * b;
    }
    return excess;
}


/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */


@end





