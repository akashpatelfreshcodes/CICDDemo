//
//  YCBleUtils.h
//  SmartHealth
//
//  Created by yc on 2019/3/6.
//  Copyright © 2019 yucheng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YCBleUtils : NSObject

+ (UInt16)crc16_compute:(NSData *)pData;

+ (NSString *)getPreferredLanguage;

+ (void)saveDevId:(NSString *)devName;
+ (NSString *)getDevId;

+ (void)saveBindedDevUUID:(NSString *)devUUID;
+ (NSString *)getBindedDevUUID;

+ (void)saveDevVersion:(NSString *)devVer;
+ (NSString *)getDevVersion;

+ (void)saveBatteryValue:(NSInteger)batteryNum;
+ (NSInteger)getBatteryValue;

+ (void)saveMainThemeValue:(NSInteger)themeIndex;
+ (NSInteger)getMainThemeIndexValue;

+ (void)saveMainThemeTotalValue:(NSInteger)totalCount;
+ (NSInteger)getMainThemeTotalValue;

+ (void)saveEcgLocationValue:(NSInteger)ecgLocation;
+ (NSInteger)getEcgLocationValue;


+ (void)saveUnitDistanceValue:(NSInteger)distanceValue;
+ (NSInteger)getUnitDistanceValue;

+ (void)saveUnitWeightValue:(NSInteger)weightValue;
+ (NSInteger)getUnitWeightValue;

+ (void)saveUnitTimeValue:(NSInteger)timeValue;
+ (NSInteger)getUnitTimeValue;


+ (void)saveUnitTemperatureValue:(NSInteger)timeValue;
+ (NSInteger)getUnitTemperatureValue;
@end

NS_ASSUME_NONNULL_END
