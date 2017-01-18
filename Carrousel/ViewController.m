//
//  ViewController.m
//  Carrousel
//
//  Created by LY on 2017/1/3.
//  Copyright © 2017年 LY. All rights reserved.
//

#import "ViewController.h"
#import "LYCarrouselView.h"
#import "LYSlider.h"
#import "UIButton+Category.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self testCarrouselView];
}

- (void)testCarrouselView
{
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0; i < 8; i ++)
    {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"mm%ld.jpeg", (long)i]];
        [array addObject:image];
    }
    LYCarrouselView *carr = [[LYCarrouselView alloc] initWithFrame:CGRectMake(20, 80, 280, 160) images:array callback:^(NSInteger index, NSInteger event) {
        
        NSLog(@"%ld %@", index, event == 1 ? @"点击" : @"长按");
    }];
    [carr addImage:[UIImage imageNamed:@"mm8.jpeg"]];
    carr.backgroundColor = [UIColor blackColor];
    carr.animationSpeed = 2;
    carr.showReflectLayer = YES;
    [self.view addSubview:carr];
    
    UIButton *start = [UIButton buttonWithType:UIButtonTypeCustom];
    [start setFrame:CGRectMake(40, 260, 100, 48)];
    [start setTitle:@"开始" forState:UIControlStateNormal];
    [start setBackgroundColor:[UIColor blueColor]];
    [start handleControlEvents:UIControlEventTouchUpInside withBlock:^(UIControlEvents events) {
        
        //默认为向左，如果暂停了，修改方向，开始向右
        [carr startRotateRight:YES];
    }];
    [self.view addSubview:start];
    
    
    UIButton *stop = [UIButton buttonWithType:UIButtonTypeCustom];
    [stop setFrame:CGRectMake(180, 260, 100, 48)];
    [stop setTitle:@"停止" forState:UIControlStateNormal];
    [stop setBackgroundColor:[UIColor blueColor]];
    [stop handleControlEvents:UIControlEventTouchUpInside withBlock:^(UIControlEvents events) {
        
        [carr stopRotate];
    }];
    [self.view addSubview:stop];
    
    LYSlider *slopex = [[LYSlider alloc] initWithWidth:280 center:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height - 120) horizontal:YES];
    [self.view addSubview:slopex];
    slopex.thumbcolor = [UIColor magentaColor];
    slopex.gradientBackInfo = [self sliderBackGraidentInfo];
    slopex.value = 2 / 6.0;
    [slopex handleSliderAction:UIControlEventValueChanged callback:^(LYSlider *slider, UIControlEvents event) {
        
        carr.animationSpeed = slider.value * 6;
    }];
}

- (NSDictionary *)sliderBackGraidentInfo
{
    return @{@"locations" : @[@(0),
                              @(60 / 360.),
                              @(120 / 360.),
                              @(180 / 360.),
                              @(240 / 360.),
                              @(300 / 360.),
                              @(1)],
             @"colors" : @[[UIColor redColor],
                           [UIColor yellowColor],
                           [UIColor greenColor],
                           [UIColor cyanColor],
                           [UIColor blueColor],
                           [UIColor magentaColor],
                           [UIColor redColor]]};
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
