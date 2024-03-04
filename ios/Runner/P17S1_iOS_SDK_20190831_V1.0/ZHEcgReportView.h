//
//  ZHEcgReportView.h
//
//  Created by Soar.
//  Copyright ©  zhouhai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZHEcgReportView : UIView

/*
 一次测量的所有ecg数据 / All ecg data measured at one time
 */
@property (strong, nonatomic) NSArray * arrEcgData;

/*
 绘画线条的宽度 （默认为：1） / The width of the drawing line (default: 1)
 */
@property (assign, nonatomic) float drawWidth;

/*
 绘画线条的颜色 （默认为：[UIColor colorWithRed:88/255.0 green:175/255.0 blue:71/255.0 alpha:1]） /The color of the line of painting (default: [UIColor colorWithRed:88/255.0 green:175/255.0 blue:71/255.0 alpha:1])
 */
@property (strong, nonatomic) UIColor * drawColor;

/*
 绘画网格的颜色 （默认为：[UIColor redColor]） /The color of grid (default: [UIColor redColor])
 */
@property (strong, nonatomic) UIColor * gridColor;

@end
