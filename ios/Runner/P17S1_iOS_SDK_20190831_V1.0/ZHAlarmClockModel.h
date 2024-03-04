//
//  ZHAlarmClockModel.h
//  WearHeartFunction
//
//  Created by 王腾飞 on 2017/10/18.
//  Copyright © 2017年 王腾飞. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZHAlarmClockModel : NSObject

/**
 *  闹钟时刻 格式：HH:mm / Alarm clock format: HH:mm
 */
@property (nonatomic, copy) NSString *time;

/**
 *  闹钟id (0,1,2,3,4)-最多添加五个闹钟 / Alarm clock id (0,1,2,3,4) - add up to five alarm clocks
 */
@property (assign, nonatomic) int alarmID;

/**
 *  闹钟星期选中标记 (星期一，星期二...星期日，必须设置固定七个数据数组，传0(未选中)或1(选中)) / Alarm clock week check mark (Monday, Tuesday...Sunday, you must set a fixed seven data array, pass 0 (unchecked) or 1 (checked))
 */
@property (nonatomic, copy) NSArray * dayflags;

/**
 * 是否重复 (重复赋YSE  单次NO)
 */
@property (nonatomic, assign) BOOL repeat;

/**
 * 闹钟开关标记 / Alarm switch mark
 */
@property (nonatomic, assign) int slider;

@end
