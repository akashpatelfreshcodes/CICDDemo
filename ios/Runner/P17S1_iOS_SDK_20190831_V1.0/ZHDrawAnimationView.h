//
//  ZHSendCmdTool.h
//
//  Created by Soar.
//  Copyright ©  zhouhai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PointContainer : NSObject

@property (nonatomic , readonly) NSInteger numberOfRefreshElements;
@property (nonatomic , readonly) NSInteger numberOfTranslationElements;
@property (nonatomic , readonly) CGPoint *refreshPointContainer;
@property (nonatomic , readonly) CGPoint *translationPointContainer;

@property (assign, nonatomic) NSInteger currentRefreshPointsCount;
@property (assign, nonatomic) NSInteger currentTranslationPointsCount;


+ (PointContainer *)sharedContainer;

/*
 调整ecg绘画的上下显示高度 （默认为：160）/ Adjust the height of the top and bottom display of the ecg painting (default: 160)
 */
@property (assign, nonatomic) float drawEcgHeight;
/*
 调整ppg绘画的上下显示高度 （默认为：160）/ Adjust the height of the upper and lower display of the ppg drawing (default: 160)
 */
@property (assign, nonatomic) float drawPpgHeight;

//刷新变换 / Refresh the transformation
- (void)addPointAsRefreshChangeform:(CGPoint)point;
//平移变换 / Translation transformation
- (void)addPointAsTranslationChangeform:(CGPoint)point drawType:(NSInteger)type;

@end

@interface ZHDrawAnimationView : UIView

/*
 绘画线条的宽度 （默认为：1）/ The width of the drawing line (default: 1)
 */
@property (assign, nonatomic) float drawWidth;

/*
 绘画线条的颜色 （默认为：[UIColor colorWithRed:88/255.0 green:175/255.0 blue:71/255.0 alpha:1]) / The color of the line of painting (default: [UIColor colorWithRed:88/255.0 green:175/255.0 blue:71/255.0 alpha:1])
 */
@property (strong, nonatomic) UIColor * drawColor;

/*
 绘画网格的颜色 （默认为：[UIColor lightGrayColor]） /The color of grid (default: [UIColor lightGrayColor])
 */
@property (strong, nonatomic) UIColor * gridColor;

- (void)fireDrawingWithPoints:(CGPoint *)points pointsCount:(NSInteger)count;


@end

