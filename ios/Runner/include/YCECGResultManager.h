//
//  YCECGResultManager.h
//  YCBleDemo
//
//  Created by liuhuiyang on 2021/1/14.
//  Copyright © 2021 qiaoliwei. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface YCECGResultManager : NSObject



/// 获取ECG报告
/// @param date 测量时间
/// @param ecgDatas ecg的数据
/// @param deviceName 手环名称
/// @param macAddress 手环的mac地址
/// @param finished 获取结果
+ (void)getECGFinalResult:(NSDate *)date
                 ecgDatas:(NSArray *)ecgDatas
               deviceName:(NSString *)deviceName
               macAddress:(NSString *)macAddress
                 finished:(void (^)(id res, NSError* error))finished;

@end

NS_ASSUME_NONNULL_END
