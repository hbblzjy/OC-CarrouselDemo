//
//  LYSlider.m
//  FBLedControl
//
//  Created by lxy on 15/10/12.
//  Copyright © 2015年 lxy. All rights reserved.
//

#import "LYSlider.h"

#define sliderWidth     4 * (1 / [UIScreen mainScreen].scale)
#define refelectWidth   36
#define thumbWidth      28
#define leftMerging     14

#define kBackImage(color)  [[LYSlider imageWithColor:(color) size:CGSizeMake(200, 4)] stretchableImageWithLeftCapWidth:100 topCapHeight:2]
#define kThumbImage(color) [LYSlider imageWithColor:(color) size:CGSizeMake(80, 80) radius:40]

@interface LYSlider ()

@property (nonatomic, assign) BOOL dragging;
@property (nonatomic, assign) BOOL justEndDragging;
@property (nonatomic, strong) UIImageView *backImageView;
@property (nonatomic, strong) UIImageView *thumbImageView;

@property (nonatomic, strong) UILabel *popLabel;
@property (nonatomic, assign) BOOL showPopLabel;

@property (nonatomic, strong) NSMutableDictionary *recordDictionary;

@end

@implementation LYSlider

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    return [self imageWithColor:color size:size radius:0];
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size radius:(CGFloat)radius
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    view.backgroundColor = color;
    view.layer.borderWidth = 1 / [[UIScreen mainScreen] scale];
    view.layer.borderColor = color.CGColor;
    view.layer.cornerRadius = radius;
    view.layer.masksToBounds = YES;
    
    return [self screenShot:view.layer];
}

- (LYSlider *)initWithWidth:(CGFloat)length center:(CGPoint)center horizontal:(BOOL)horizon showValue:(BOOL)show
{
    self = [super init];
    if (self)
    {
        self.showPopLabel = show;
        self = [self initWithWidth:length center:center horizontal:horizon];
    }
    return self;
}

- (LYSlider *)initWithWidth:(CGFloat)length center:(CGPoint)center horizontal:(BOOL)horizon
{
    self.myCenter = center;
    self.center = center;
    _horizontal = horizon;
    _length = length;
    CGRect frame = [self calculateFrame];
    self = [super initWithFrame:frame];
    if (self)
    {
        self.dragging = NO;
        self.justEndDragging = NO;
        self.value = 0;
        
        CGRect backFrame = [self calculateBackimageFrame];
        CGPoint thumbCenter = [self calculateThumberCenter];
        self.backImageView = [[UIImageView alloc] initWithFrame:backFrame];
        self.thumbImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, thumbWidth, thumbWidth)];
        self.thumbImageView.center = thumbCenter;
        [self addSubview:self.backImageView];
        [self.backImageView addSubview:self.thumbImageView];
        [self resetInterface];
        [self removeAllHandleSliderAction];
        [self.backImageView setImage:kBackImage([UIColor magentaColor])];
        [self.thumbImageView setImage:kThumbImage([UIColor whiteColor])];
        /*
        if (self.showPopLabel)
        {
            self.popLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, thumbWidth, thumbWidth)];
            self.popLabel.center = CGPointMake(self.thumbImageView.center.x, self.thumbImageView.center.y - thumbWidth / 2 - 15);
            self.popLabel.backgroundColor = [UIColor greenColor];
            [self.popLabel setTextAlignment: NSTextAlignmentCenter];
            [self.popLabel setTextColor:[UIColor whiteColor]];
            [self.popLabel setText:@"0"];
            self.popLabel.layer.borderWidth = 1;
            self.popLabel.layer.borderColor = [UIColor greenColor].CGColor;
            self.popLabel.layer.cornerRadius = thumbWidth / 2;
            self.popLabel.layer.masksToBounds = YES;
            self.popLabel.hidden = YES;
            [self addSubview:self.popLabel];
            [self sendSubviewToBack:self.popLabel];
        }*/
    }
    return self;
}

- (void)handleSliderAction:(UIControlEvents)events callback:(LYSliderActionBlock)block
{
    UIControlEvents clash = [self checkEventsClash:events];
    if (clash)
    {
        NSLog(@"事件监听冲突:%ld", (unsigned long)clash);
        return;
    }
    [self.recordDictionary setObject:block forKey:[NSNumber numberWithUnsignedInteger:events]];
}

- (void)removeHandleSliderAction:(UIControlEvents)events
{
    NSNumber *key = [NSNumber numberWithUnsignedInteger:events];
    LYSliderActionBlock block = self.recordDictionary[key];
    if (block != NULL)
    {
        [self.recordDictionary removeObjectForKey:key];
        return;
    }
    NSArray *keys = [self.recordDictionary allKeys];
    for (NSNumber *ok in keys)
    {
        UIControlEvents evt = [ok unsignedIntegerValue] & events;
        if (evt == 0) continue;
        LYSliderActionBlock block = self.recordDictionary[ok];
        [self.recordDictionary removeObjectForKey:ok];
        UIControlEvents nkey = [ok unsignedIntegerValue] - evt;
        if (nkey == 0) continue;
        NSNumber *nk = [NSNumber numberWithUnsignedInteger:nkey];
        [self.recordDictionary setObject:block forKey:nk];
    }
}

- (void)removeAllHandleSliderAction
{
    [self.recordDictionary removeAllObjects];
}

- (void)showThePopLabel
{
    if (self.popLabel.hidden)
    {
        [self.popLabel setHidden:NO];
    }
    CGPoint center = CGPointMake(self.thumbImageView.center.x, self.thumbImageView.center.y - thumbWidth / 2 - 15);
    [self.popLabel setCenter:center];
}

- (void)hideThePopLabel
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.popLabel setHidden:YES];
    });
}

#pragma mark - action methods
- (void) mapPointToValue:(CGPoint)point
{
    CGFloat val = self.horizontal ? (point.x / self.backImageView.frame.size.width) : (point.y / self.backImageView.frame.size.height);
    val = MAX(MIN(val, 1.0), 0.0);
    self.value = val;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    self.dragging = YES;
    self.justEndDragging = NO;
    [self sendActionsForControlEvents:UIControlEventTouchDown];
    [self mapPointToValue:[touch locationInView:self]];
    [self showThePopLabel];
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self mapPointToValue:[touch locationInView:self]];
    [self showThePopLabel];
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    //    NSLog(@"end dragging..........");
    [self continueTrackingWithTouch:touch withEvent:event];
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
    self.dragging = NO;
    self.justEndDragging = YES;
    [self hideThePopLabel];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    [self sendActionsForControlEvents:UIControlEventTouchCancel];
    self.dragging = NO;
    self.justEndDragging = YES;
    [self hideThePopLabel];
}

#pragma mark - private methods
- (void)resetInterface
{
    self.frame = [self calculateFrame];
    [self.backImageView setFrame:[self calculateBackimageFrame]];
    [self.thumbImageView setCenter:[self calculateThumberCenter]];
}

-(void) didAddSubview:(UIView *)subview
{
    [self bringSubviewToFront:self.thumbImageView];
}

- (void)callActionBlockWithEvent:(UIControlEvents)event
{
    NSArray *keys = [self.recordDictionary allKeys];
    NSNumber *thekey = nil;
    for (NSNumber *key in keys)
    {
        NSUInteger evt = [key unsignedIntegerValue];
        if (evt & event) { thekey = key; break; }
    }
    if (!thekey) return;
    
    LYSliderActionBlock block = [self.recordDictionary objectForKey:thekey];
    if (block)
    {
        block(self, event);
    }
}

- (UIControlEvents)checkEventsClash:(UIControlEvents)events
{
    NSArray *keys = [self.recordDictionary allKeys];
    if (keys.count == 0)
    {
        return 0;
    }
    UIControlEvents clash = 0;
    for (NSInteger i = 0; i < 14; i ++)
    {
        NSUInteger bit = 1 << i;
        NSUInteger res = bit & events;
        if (res == 0) continue;
        for (NSNumber *key in keys)
        {
            NSUInteger evt = [key unsignedIntegerValue];
            NSUInteger evres = evt & bit;
            if (evres != 0)
            {
                clash = +bit;break;
            }
        }
        if (clash) break;
    }
    return clash;
}

- (void)addEventTarget
{
    [self addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(touchDownRepeat:) forControlEvents:UIControlEventTouchDownRepeat];
    [self addTarget:self action:@selector(touchDragInside:) forControlEvents:UIControlEventTouchDragInside];
    [self addTarget:self action:@selector(touchDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
    [self addTarget:self action:@selector(touchDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
    [self addTarget:self action:@selector(touchDragExit:) forControlEvents:UIControlEventTouchDragExit];
    [self addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(touchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    [self addTarget:self action:@selector(touchCancel:) forControlEvents:UIControlEventTouchCancel];
    [self addTarget:self action:@selector(touchValueChanged:) forControlEvents:UIControlEventValueChanged];
#ifdef __IPHONE_9_0
    [self addTarget:self action:@selector(primaryActionTriggered:) forControlEvents:UIControlEventPrimaryActionTriggered];
#endif
}

- (void)removeEventTarget
{
    [self removeTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [self removeTarget:self action:@selector(touchDownRepeat:) forControlEvents:UIControlEventTouchDownRepeat];
    [self removeTarget:self action:@selector(touchDragInside:) forControlEvents:UIControlEventTouchDragInside];
    [self removeTarget:self action:@selector(touchDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
    [self removeTarget:self action:@selector(touchDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
    [self removeTarget:self action:@selector(touchDragExit:) forControlEvents:UIControlEventTouchDragExit];
    [self removeTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self removeTarget:self action:@selector(touchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    [self removeTarget:self action:@selector(touchCancel:) forControlEvents:UIControlEventTouchCancel];
    [self removeTarget:self action:@selector(touchValueChanged:) forControlEvents:UIControlEventValueChanged];
#ifdef __IPHONE_9_0
    [self removeTarget:self action:@selector(primaryActionTriggered:) forControlEvents:UIControlEventPrimaryActionTriggered];
#endif
}

#pragma mark - event targets
- (void)touchDown:(LYSlider *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchDown];
}

- (void)touchDownRepeat:(LYSlider *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchDownRepeat];
}

- (void)touchDragInside:(LYSlider *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchDragInside];
}

- (void)touchDragOutside:(LYSlider *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchDragOutside];
}

- (void)touchDragEnter:(LYSlider *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchDragEnter];
}

- (void)touchDragExit:(LYSlider *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchDragExit];
}

- (void)touchUpInside:(LYSlider *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchUpInside];
}

- (void)touchUpOutside:(LYSlider *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchUpOutside];
}

- (void)touchCancel:(LYSlider *)sender
{
    [self callActionBlockWithEvent:UIControlEventTouchCancel];
}

- (void)touchValueChanged:(LYSlider *)sender
{
    [self callActionBlockWithEvent:UIControlEventValueChanged];
}

- (void)primaryActionTriggered:(UIButton *)sender
{
#ifdef __IPHONE_9_0
    [self callActionBlockWithEvent:UIControlEventPrimaryActionTriggered];
#endif
}

#pragma mark - getters setters
// 重设center 要刷新interface
- (void)setMyCenter:(CGPoint)myCenter
{
    _myCenter = myCenter;
    self.center = myCenter;
    [self resetInterface];
}

// 重设是否横向 要刷新interface
- (void)setHorizontal:(BOOL)horizontal
{
    _horizontal = horizontal;
    [self resetInterface];
}

- (void)setLength:(CGFloat)length
{
    _length = length;
    [self resetInterface];
}

- (CGFloat)sliderHeight
{
    return refelectWidth;
}

// 重设背景图片
- (void)setBackimage:(UIImage *)backimage
{
    if (backimage)
    {
        _backimage = backimage;
        [self.backImageView setImage:backimage];
    }
}

// 重设背景图颜色
- (void)setBackcolor:(UIColor *)backcolor
{
    if (backcolor)
    {
        _backcolor = backcolor;
        [self setBackimage:kBackImage(backcolor)];
    }
}

// 重设滑动按钮图片
- (void)setThumbimage:(UIImage *)thumbimage
{
    if (thumbimage)
    {
        _thumbimage = thumbimage;
        [self.thumbImageView setImage:thumbimage];
        self.thumbImageView.layer.borderColor = [UIColor clearColor].CGColor;
        self.thumbImageView.layer.borderWidth = 1 / [[UIScreen mainScreen] scale];
        self.thumbImageView.layer.cornerRadius = 14;
        self.thumbImageView.layer.masksToBounds = YES;
    }
}

// 重设滑动按钮颜色
- (void)setThumbcolor:(UIColor *)thumbcolor
{
    if (thumbcolor)
    {
        _thumbcolor = thumbcolor;
        [self setThumbimage:kThumbImage(thumbcolor)];
    }
}

- (void)setGradientBackInfo:(NSDictionary *)gradientBackInfo
{
    NSArray *locations = gradientBackInfo[@"locations"];
    if (locations.count < 2)
    {
        NSLog(@"number of locations should >= 2");
        return;
    }
    NSArray *colors = gradientBackInfo[@"colors"];
    if (colors.count < 2)
    {
        NSLog(@"number of colors should >= 2");
        return;
    }
    CGPoint start = CGPointMake(self.horizontal ? 0 : 0.5, self.horizontal ? 0.5 : 0);
    CGPoint end = CGPointMake(self.horizontal ? 1 : 0.5, self.horizontal ? 0.5 : 1);
    
    CGRect bounds = [self calculateBackimageFrame];
    bounds.origin = CGPointZero;
    CALayer *layer = [LYSlider drawGradientLayerInRect:bounds colors:colors locations:locations startPoint:start endPoint:end];
    _gradientBackInfo = gradientBackInfo;
    [self setBackimage:[LYSlider screenShot:layer]];
}

- (BOOL)isDragging
{
    return self.dragging;
}

- (BOOL)isJustEndDragging
{
    return self.justEndDragging;
}

- (void)setValue:(CGFloat)value
{
    _value = MAX(MIN(value, 1.0), 0.0);
    CGPoint thumbCenter;
    CGRect frame = [self calculateBackimageFrame];
    if (self.horizontal)
    {
        thumbCenter = CGPointMake(_value * frame.size.width, sliderWidth / 2);
    }
    else
    {
        thumbCenter = CGPointMake(sliderWidth / 2, _value * frame.size.height);
    }
    [self.thumbImageView setCenter:thumbCenter];
    [self setNeedsDisplay];
}


// 重新计算自身frame
- (CGRect)calculateFrame
{
    CGRect frame = CGRectZero;
    if (self.horizontal)
    {
        frame.origin.x = self.myCenter.x - self.length / 2;
        frame.origin.y = self.myCenter.y - refelectWidth / 2;
        frame.size.width = self.length;
        frame.size.height = refelectWidth;
    }
    else
    {
        frame.origin.x = self.myCenter.x - refelectWidth / 2;
        frame.origin.y = self.myCenter.y - self.length / 2;
        frame.size.width = refelectWidth;
        frame.size.height = self.length;
    }
    return frame;
}

// 重新计算背景图frame
- (CGRect)calculateBackimageFrame
{
    CGRect backFrame = CGRectZero;
    if (self.horizontal)
    {
        backFrame.origin.x = leftMerging;
        backFrame.origin.y = (refelectWidth - sliderWidth) / 2;
        backFrame.size.width = self.length - 2 * leftMerging;
        backFrame.size.height = sliderWidth;
    }
    else
    {
        backFrame.origin.x = (refelectWidth - sliderWidth) / 2;
        backFrame.origin.y = leftMerging;
        backFrame.size.width = sliderWidth;
        backFrame.size.height = self.length - 2 * leftMerging;
    }
    return backFrame;
}

// 重新计算按钮center
- (CGPoint)calculateThumberCenter
{
    CGPoint center = CGPointZero;
    CGRect frame = [self calculateBackimageFrame];
    if (self.horizontal)
    {
        center = CGPointMake(self.value * frame.size.width, sliderWidth / 2);
    }
    else
    {
        center = CGPointMake(sliderWidth / 2, self.value * frame.size.height);
    }
    return center;
}

- (NSMutableDictionary *)recordDictionary
{
    if (_recordDictionary == nil)
    {
        _recordDictionary = [NSMutableDictionary dictionary];
        [self addEventTarget];
    }
    return _recordDictionary;
}

- (UIImage *)thumbimageForType
{
    UIImage *image = nil;
    image = kThumbImage([UIColor whiteColor]);
    return image;
}

CG_INLINE CGRect CGRectGetBounds(CGRect rect)
{
    CGRect frame = rect; frame.origin = CGPointZero; return frame;
}
#define CenterForRect(r)    CGPointMake((r).origin.x + (r).size.width / 2, (r).origin.y + (r).size.height / 2)

+ (CALayer *)drawGradientLayerInRect:(CGRect)rect colors:(NSArray <UIColor *>*)colors locations:(NSArray *)locations startPoint:(CGPoint)start endPoint:(CGPoint)end
{
    NSMutableArray *cgcolors = [NSMutableArray array];
    for (UIColor *color in colors)
    {
        [cgcolors addObject:(id)color.CGColor];
    }
    CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
    gradientLayer.bounds = CGRectGetBounds(rect);
    gradientLayer.position = CenterForRect(rect);
    gradientLayer.startPoint = start;
    gradientLayer.endPoint = end;
    [gradientLayer setColors:cgcolors];
    [gradientLayer setLocations:locations];
    
    CALayer *layer = [[CALayer alloc] init];
    layer.bounds = CGRectGetBounds(rect);
    [layer addSublayer:gradientLayer];
    return layer;
}

+ (UIImage *)screenShot:(CALayer *)layer
{
    UIImage *image;
    UIGraphicsBeginImageContext(layer.bounds.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx == NULL) {UIGraphicsEndImageContext(); return nil;}
    [layer renderInContext:ctx];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end








