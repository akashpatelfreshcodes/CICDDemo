//
//  YCBTProduct.h
//  SmartHealth
//
//  Created by yc on 2019/3/18.
//  Copyright © 2019 yucheng. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "YCBTConstants.h"
#import "YCBleUtils.h"
#import "CBPeripheral+RSSI.h"


NS_ASSUME_NONNULL_BEGIN

#define kNtfConnectStateChange @"kNtfConnectStateChange"  //连接状态改变
#define kNtfConnectStateKey @"BleState"

#define kNtfRecvRealStepData @"kRecvRealStepData"  //实时运动计步数据
#define kNtfRecvRealHeartData @"kRecvRealHeartData"  //实时心率数据
#define kNtfRecvRealBloodData @"kRecvRealBloodData"  //实时血压数据
#define kNtfRecvRealEcgData @"kRecvRealEcgData"  //实时心电数据
#define kNtfRecvRealPpgData @"kRecvRealPpgData"  //实时PPG数据

#define kNtfRecvHistroyData @"kRecvHistoryData"  //历史数据
#define kNtfRecvHistoryEcgData @"kRecvHistoryEcgData"  //历史心电数据
#define kNtfRecvHistoryPPgData @"kRecvHistoryPPgData"  //历史PPG数据

#define kNtfStopHistoryData @"kNtfStopHistoryData"  //停止历史完成通知

//心电,光电电极状态 设备实时状态上报
//keyEcgStatus 0x00:心电电极接触良好 0x01:心电电极脱落
//keyPpgStatus 0x00:已佩戴  0x01:未佩戴
#define kNtfEcgPpgStatusData @"kNtfEcgPpgStatusData"  //心电,光电电极状态 设备实时状态上报

#define kNtfRecvSupportFunctionData @"kNtfRecvSupportFunctionData"  //手表功能列表接收到

#define kNtfRecvFindPhone @"kNtfRecvFindPhone" // 找手机
#define kNtfRecvLossPreventionReminder @"kNtfRecvLossPreventionReminder" // 防丢提醒
#define kNtfRecvTakePhoto @"kNtfRecvTakePhoto" // 拍照
#define kNtfRecvOneTouchCall @"kNtfRecvOneTouchCall"  // 一键呼救
#define kNtfRecvDrinkingMode @"kNtfRecvDrinkingMode" // 饮酒模式
#define kNtfRecvConnectionAllowed @"kNtfRecvConnectionAllowed" // 允许连接
#define kNtfRecvSportModeControl @"kNtfRecvSportModeControl" // 运动模式控制

/// 收到手环恢复出厂设置的通知
#define kNtfRecvDevieRestoreFactorySettings (@"kNtfRecvDevieRestoreFactorySettings")

/// 收到手环结束实时测试的通知
#define kNtfRecvDevieFinishedRealTimeTest (@"kNtfRecvDevieFinishedRealTimeTest")

#define kNtfRecvScheudle @"kNtfRecvScheudle" // 日程信息
#define kNtfRecvEventInfo @"kNtfRecvEventInfo" // 事件信息
 
/// 自定义Log，可配置开关（用于替换NSLog）
#define DBG(format,...) YCSDKCustomLog(format,##__VA_ARGS__)

/// 自定义打印Log
void YCSDKCustomLog(NSString * _Nullable format, ...);

@interface YCBTProduct : NSObject

@property (nonatomic, strong, nullable) NSString *yc_dev_id;
@property (nonatomic, strong) NSMutableDictionary *supportFunctionDic;

@property (nonatomic, strong) CBCharacteristic *testChar1;

/// 历史ECG与PPG采样率 16 / 24
@property (nonatomic, assign) NSInteger historyPPGSampleBits;

/// 设置开启SDK的打印日志
/// @param flag YES - 开启 NO - 不开启
+ (void)setDebugLogEnable:(BOOL)flag;

+ (YCBTProduct *)shared;

- (CBCentralManager *) cbCM;
- (CBPeripheral *)cbPeripheral;

- (void)setCBCentralManager:(CBCentralManager *)cbCM;

- (void)resetCBCentralManager;

//搜索设备相关
- (void)startScanDevice:(void (^)(Error_Code code, NSMutableArray *result))callBack;
- (void)stopScan;
- (void)connectDevice:(CBPeripheral *)cbPer callBack:(void (^)(Error_Code code))callBack;
- (void)unBindDevice;
- (void)forceDisconnectDevice;

/// 主动连接，如果已经连接返回YES,需要重新连接返回NO
- (BOOL)reConnectBindDevice;

// MARK: - 历史采集数据同步


/**
 同步ECG历史数据 概要列表

 @param callBack 回调
 */
- (void)syncECGCollectList:(void (^)(Error_Code code, NSDictionary *result))callBack;


/// 查询历史采集数据的数量
/// @param collectType
///     0x00: 心电图数据（ECG）
///     0x01: PPG数据
///     0x02: 三轴加速度数据
///     0x03: 六轴传感器数据（3轴加速度+3轴陀螺仪）
///     0x04: 九轴传感器数据（3轴加速度+3轴陀螺仪+3轴磁力计）
///     0x05: 三轴磁力计数据
///     0x06：手环佩戴脱落数据
/// @param callBack 回调
- (void)syncHistoryCollectList:(NSInteger)collectType
                      callback:(void (^)(Error_Code code, NSDictionary *result))callBack;



/**
 通过索引号同步ECG历史数据

 @param index 第几条索引
 @param progressCallback 进度
 @param callBack 数据结果回调
 */
- (void)syncECGCollectData:(NSInteger)index
                  progress:(void (^)(float ratio))progressCallback
                  callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


/// 通过时间戳
/// @param timestamp 时间戳
/// @param progressCallback 进度条
/// @param callBack 结果返回
- (void)syncECGCollectDataWithTimestamp:(NSInteger)timestamp
                  progress:(void (^)(float ratio))progressCallback
                  callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


/**
 同步PPG历史数据 概要列表
 
 @param callBack 回调
 */
- (void)syncPPGCollectList:(void (^)(Error_Code code, NSDictionary *result))callBack;

/**
 同步PPG历史数据
 
 @param timestamp 时间戳
 @param progressCallback 进度
 @param callBack 数据结果回调
 */
- (void)syncPPGCollectData:(NSInteger)timestamp
                  progress:(void (^)(float ratio))progressCallback
                  callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 3.5.8.6 通过索引号删除历史采集数据


/// 通过索引号删除历史采集数据
/// @param collectType 数据类型
/// @param collectIndex 记录编号 0~65534, 0xFFFF 代表全删除
/// @param callBack 执行结果
- (void)deleteCollectData:(NSInteger)collectType
             collectIndex:(NSInteger)collectIndex
                 callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 3.5.8.7 通过时间戳删除历史采集数据

/**
 根据时间戳同时删除ECG与PPG数据

 @param timestamp 测试数据概要里的开始时间戳 since 1970 (0xFFFFFFFF 代表全删除)
 @param callBack 数据结果回调
 */
- (void)deleteECGPPGCollectData:(NSInteger)timestamp
                    callback:(void (^)(Error_Code code, NSDictionary *result))callBack;




/// 根据时间戳删除对应的类型数据
/// @param collectType 采集类型
/// @param timestamp 时间秒数 since 1970 (0xFFFFFFFF 代表全删除)
/// @param callBack 执行结果
- (void)deleteCollectData:(NSInteger)collectType
                timestamp:(NSInteger)timestamp
                 callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


/**
 停止历史数据同步
 */
- (void)stopCollectData;


// MARK: - 同步数据

/**
 同步所有历史数据(步数,睡眠,心电,血压等）,同步的具体数据通过 通知 抛出 【取消使用】

 @param callBack 同步完成Block
 */
//- (void)syncAllHistory:(void (^)(Error_Code code, NSDictionary *result))callBack;


///// 同步综合历史数据 (取消使用)
///// @param callBack 同步完成
//- (void)syncMutableDataHistory:(void (^)(Error_Code code, NSDictionary *result))callBack;

/**
 同步历史数据, 单项同步

 @param historyType 0x02 sport, 0x04 sleep, 0x06 HR, 0x08 BP, 0x09 tem. spo2.
 @param callBack finished
 */
- (void)syncDataHistory:(NSInteger)historyType
               callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

/**
 delete history data

 @param historyType
 0x40 - delete sport data,
 0x41 - delete sleep data,
 0x42 - delete HR,
 0x43 - delete BP,
 0x44 - delete mutable data
 
 0x45 - delete spo2
 0x46 - delete temperature and humidity
 0x47 - delete body temperature
 0x48 - delete ambient light
 0x49 - delete wear status
 0x4A - delete all history data
@param callBack callback
 */
- (void)deleteHistoryData:(NSInteger)historyType
                 callback:(void (^)(Error_Code code, NSDictionary *result))callBack;



 
 

// MARK: - 设备上报回应

// MARK: - 查找手机 3.5.5.1

/// 响应是否找到手机 Devcie不再响应
- (void)findPhone:(NSInteger)data;


// MARK: 拍照的回应 3.5.5.3

/// 拍照的回应
- (void)takePhotoResponse:(BOOL)success;


// MARK: - 一键呼救 3.5.5.6

/// 呼救响应
/// @param status 0x00:呼救中，0x01: 呼救失败， 0x02：呼救结束
- (void)oneTouchCallResponse:(NSInteger)status;

// MARK: - 饮酒模式 3.5.5.7

- (void)drinkingModeRespose:(NSInteger)status;


// MARK: - 手环蓝牙连接/拒绝 3.5.5.8

- (void)connectionAllowedRespose;

// MARK: - 手环运动模式控制 3.5.5.9

/// 运动模式回应
- (void)sportModeControlRespose;


// MARK: - 手机恢复出厂设置 3.5.5.11

/// 恢复出厂设置回应
- (void)restoreFactorySettingsRespose;

// MARK: - 手机结束测试

/// 手环结束测试响应
- (void)deviceFinishedRealTimeTestRespose;


// MARK: - App控制相关 App Control

// MARK: - 寻找手环 3.5.4.1

/**
 寻找手环

 @param callBack 回调
 */
- (void)findAntiLost:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 心率测试开关控制 3.5.4.2

/// 打开心率测试开关
/// @param isOpen 开或关
- (void)openHeartTest:(BOOL)isOpen;


// MARK: - 血压测试开关控制 3.5.4.3
- (void)openBloodTest:(BOOL)isOpen;


// MARK: - 血压校准命令 3.5.4.4

/// 3.5.4.11
/// @param systolicPressure 收缩压
/// @param diastolicPressure 舒张压
/// @param callBack 回调
- (void)bloodPressureCalibrationSystolicPressure:(NSInteger)systolicPressure
                               diastolicPressure:(NSInteger)diastolicPressure
                                        callBack:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 实时数据上传控制 3.5.4.10

/// 开启实时步数、里程、卡路里数据同步开关
/// @param isOpen 是否开启
/// @param callBack 完成回调
- (void)settingRealDataOpen:(BOOL)isOpen
                   callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 查询采样率 3.5.4.11


/// 查询采样率
/// @param type
/// 0x00: 光电波形
/// 0x01: 心电波形
/// 0x02: 多轴传感器波形（3轴、6轴、9轴）
/// @param callBack 返回数据
- (void)getSampleRate:(NSInteger)type
             callBack:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 波形上传控制 3.5.4.12


/// 波形上传控制
/// @param status 状态控制
/// @param type 类型选择
/// @param callBack 回调
- (void)WaveformUploadControl:(NSInteger)status
                         type:(NSInteger)type
                     callBack:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 运动模式启动/停止 3.5.4.13

// 0x00: 预留   0x04: 健身  0x08: 健走
// 0x01: 跑步   0x05: 预留  0x09: 羽毛球
// 0x02: 游泳   0x06: 跳绳  0x0A: 足球
// 0x03: 骑行   0x07: 篮球  0x0B: 登山
// 0x0C: 乒乓球 0x0D：自定义
- (void)beginRunMode:(BOOL)isBegin runType:(NSInteger)runtype;

// MARK: - 拍照 3.5.4.15

- (void)openTakePhoto:(BOOL)isOpen callBack:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 今日天气信息数据传送  3.5.4.19

///  同步天气
/// @param weatherData 天气数据二进制
- (void)sendTodayWeather:(NSData *)weatherData;


/**
 同步天气信息

 @param lowTemp 最低温（摄氏度）
 @param highTemp 最高温（摄氏度）
 @param curTemp 当前温（摄氏度）
 @param weahterType 天气类型 sunny 1 cloudy  2 wind  3 rain  4 Snow  5 foggy 6 unknown 0
 @param callBack 回调结果
 */
- (void)sendTodayWeather:(NSString *)lowTemp
                highTemp:(NSString *)highTemp
                 curTemp:(NSString *)curTemp
                    type:(NSInteger)weahterType
                callback:(void (^)(Error_Code code, NSDictionary *result))callBack;




/// 同步今天天气信息
/// @param lowTemp 最低温（摄氏度）
/// @param highTemp 最高温（摄氏度）
/// @param curTemp 当前温度（摄氏度）
/// @param weahterType 天气类型 sunny 1 cloudy  2 wind  3 rain  4 Snow  5 foggy 6 unknown 0
/// @param windDirection 风向
/// @param windPower 风力
/// @param location 城市名称
/// @param moonType 月相类型
/// @param callBack 结果
- (void)sendTodayWeather:(NSString *)lowTemp
                highTemp:(NSString *)highTemp
                 curTemp:(NSString *)curTemp
                    type:(NSInteger)weahterType
           windDirection:(NSString *)windDirection
               windPower:(NSString *)windPower
                location:(NSString *)location
                moonType:(NSInteger)moonType
                callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

/// 发送天气
/// @param isTodayOrTomorrow 今天还是明天
/// @param lowTemp 最低温度
/// @param highTemp 最高温度
/// @param curTemp 当前温度
/// @param weahterType 天气类型
/// @param callBack 回调
- (void)sendWeatherData:(BOOL)isTodayOrTomorrow
                lowTemp:(NSString *)lowTemp
               highTemp:(NSString *)highTemp
                curTemp:(NSString *)curTemp
                   type:(NSInteger)weahterType
               callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 健康参数、预警信息发送 3.5.4.22

/// 健康参数、预警信息发送
/// @param warnStatus 预警状态 0x00: 无预警 0x01: 预警生效中
/// @param healthState 健康状态 0x00:未知 0x01:优秀 0x02:良好 0x03:一般 0x04:较差 0x05:生病
/// @param healthIndex 健康指数 0~120
/// @param warnFriend 亲友预警 0x00:无预警 0x01:预警生效 中
/// @param callBack 结果返回
- (void)setttingHealthInfo:(NSInteger)warnStatus
               healthState:(NSInteger)healthState
               healthIndex:(NSInteger)healthIndex
                warnFriend:(NSInteger)warnFriend
                  callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 关机、复位、进入运输模式控制 3.5.4.23

/// 设置关机
- (void)turnOnDevice:(NSInteger)power
            callBack:(void (^)(Error_Code code,
                               NSDictionary *result))callBack;


// MARK: - 温度校准与测量  3.5.4.24/3.5.4.25


/// 温度校准
/// @param temperatueInteger 温度整数部分 -127 – 127 如果采用内部传感器温度校准，此字段置 0
/// @param temperatureDecimal 温度小数部分 0 - 99 如果采用内部传感器温度校准，此字段置 0
/// @param callBack 回调
- (void)openTemperatureCalibration:(NSInteger)temperatueInteger
                TemperatureDecimal:(NSInteger)temperatureDecimal
                          callBack:(void (^)(Error_Code code,
                                             NSDictionary *result))callBack;


/// 温度测量控制
/// @param mode 0x00: 关闭 0x01: 单次测试(一般用于腋测模式) 0x02: 监测模式
/// @param callBack 回调
- (void)openTemperatureMeasurementControl:(NSInteger)mode
                                 callBack:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 亲友消息显示  3.5.4.26
 

- (void)openFriendMessageShow:(NSInteger)data
                         hour:(NSInteger)hour
                       minute:(NSInteger)minute
                   friendName:(NSString *)friendName
                     callBack:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 健康值回写到手环 3.5.4.27

 
/// APP健康值回写
/// @param data 健康值
/// @param status 状态描述
/// @param callBack 回调
- (void)writeHealthDataToDevice:(NSInteger)data
                         status:(NSString *)status
                       callBack:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - APP端睡眠数据同步 3.5.4.28

- (void)sendAppSleepData:(NSInteger)deepSleepHour
            deepSleepMin:(NSInteger)deepSleepMin
          lightSleepHour:(NSInteger)lightSleepHour
           lightSleepMin:(NSInteger)lightSleepMin
          totalSleepHour:(NSInteger)totalSleepHour
           totalSleepMin:(NSInteger)totalSleepMin
       callBack:(void (^)(Error_Code code,
                 NSDictionary *result))callBack;


// MARK: - APP用户个人信息回写到手环 3.5.4.29

- (void)writePersonMessageToDevice:(NSInteger)type
                           message:(NSString *)message
                          callBack:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 升级提醒 3.5.4.30


/// 升级提醒
/// @param isOpen YES - 打开提醒 NO - 关闭提醒
/// @param process 0 ~ 100
/// @param callBack 回调
- (void)upgradeReminder:(BOOL)isOpen process:(NSInteger)process
               callBack:(void (^)(Error_Code code,
                                  NSDictionary *result))callBack;

// MARK: -  环境光测量控制 3.5.4.31

- (void)controlAmbientLightMeasurement:(NSInteger)type
                              callBack:(void (^)(Error_Code code,
                                                 NSDictionary *result))callBack;

// MARK: -  体温红绿码设置 3.5.4.32

/// 修改体温二维码颜色
/// @param color 0x00: 绿色,  0x01: 红色, 0x02: 橙色
/// @param callBack 回调
- (void)changeTemperaturQRCodeColor:(NSInteger)color
                            callback:(void (^)(Error_Code code,
                                               NSDictionary * _Nonnull result))callBack;

// MARK: - 环境温温度测量控制 3.5.4.33

- (void)controlAmbientTemperatureAndHumidityMeasurement:(NSInteger)type
                                               callBack:(void (^)(Error_Code code,
                                                                  NSDictionary *result))callBack;


// MARK: - 保险信息推送 3.5.4.34


/// 推送保险信息
/// @param name 名称
/// @param code 保险编号
/// @param month 更新时间，月 1 ~ 12
/// @param day 更新时间, 日  1 ~ 31
/// @param amount 保险金额
/// @param callBack 推送结果
- (void)sendIInsurance:(NSString *)name
         insuranceCode:(NSInteger)code
           updateMonth:(NSInteger)month
             updateDay:(NSInteger)day
                status:(NSInteger)status
                amount:(NSInteger)amount
              callBack:(void (^)(Error_Code code,
                        NSDictionary *result))callBack ;

/// 发送保险名称
- (void)sendInsuranceName:(NSString *)name
                 callBack:(void (^)(Error_Code code,
                                    NSDictionary *result))callBack;

/// 发送健康基金数额
- (void)sendHealthFundAmount:(NSInteger)amount
                    callBack:(void (^)(Error_Code code,
                                       NSDictionary *result))callBack;


/// 发送动态保额数额
- (void)sendDynamicCoverage:(NSInteger)amount
                   callBack:(void (^)(Error_Code code,
                                      NSDictionary *result))callBack;

/// 发送次月保费数额
- (void)sendNextMonthPremium:(NSInteger)amount
                    callBack:(void (^)(Error_Code code,
                                       NSDictionary *result))callBack;


/// 发送次年保费数额
- (void)sendNextYearPremium:(NSInteger)amount
                    callBack:(void (^)(Error_Code code,
                                       NSDictionary *result))callBack;


/// 发送保险状态
- (void)sendInsuranceStatus:(NSInteger)status
                    callBack:(void (^)(Error_Code code,
                                       NSDictionary *result))callBack;

/// 设置该保险展示文
- (void)sendInsuranceShowStyle:(NSInteger)style
                      callBack:(void (^)(Error_Code code,
                                       NSDictionary *result))callBack;


/// 发送保险更新日期
- (void)sendInsuranceUpdateDate:(NSInteger)timeStamp
                       callBack:(void (^)(Error_Code code,
                                       NSDictionary *result))callBack;


// MARK: - 传感器数据存储开关控制 3.5.4.35


/// 传感器数据存储开关控制
/// @param type 类型
        /// 0x00: PPG
        /// 0x01: 加速度数据
        /// 0x02：ECG
        /// 0x03：温湿度
        /// 0x04：环境光
        /// 0x05：体温
/// @param isOpen YES - 开启，NO - 关闭
/// @param callBack 回调
- (void)controlSensorSaveData:(NSInteger)type
                       isOpen:(BOOL)isOpen
                     callBack:(void (^)(Error_Code code,
                                        NSDictionary *result))callBack;


// MARK: - 发送手机型号 3.5.4.36

- (void)sendPhoneMode:(NSString *)phoneMode
             callBack:(void (^)(Error_Code code,
                                NSDictionary *result))callBack;

// MARK: - 运动数据 3.5.4.37

- (void)sendSportData:(NSInteger)steps
            sportType:(NSInteger)sportType
            callBack:(void (^)(Error_Code code,
                   NSDictionary *result))callBack;

// MARK: - APP计算心率 3.5.4.38
- (void)sendAppCaclulateHeartRate:(NSInteger)heartRate
                         callBack:(void (^)(Error_Code code,
                                            NSDictionary *result))callBack;



// MARK: - App预警信息推送 3.5.4.39

- (void)sendAppAlertInformation:(NSInteger)type
                        message:(NSString *)message
                       callBack:(void (^)(Error_Code code,
                                           NSDictionary *result))callBack;


// MARK: - App信息推送 3.5.4.40

- (void)sendShowMessage:(NSInteger)messageType
                message:(NSString *)message
               callBack:(void (^)(Error_Code code,
                                           NSDictionary *result))callBack;


// MARK: - 温湿度校准命令  3.5.4.42


/// 温湿度校准
/// @param temperatureInteger 温度整数部分
/// @param temperatureDecimal 温度整数部分
/// @param humidityInteger 湿度整数部分
/// @param humidityDecimal 湿度小数部分
/// @param callBack 回调
- (void)calibrationTemperatureHumidity:(NSInteger)temperatureInteger
                    temperatureDecimal:(NSInteger)temperatureDecimal
                       humidityInteger:(NSInteger)humidityInteger
                       humidityDecimal:(NSInteger)humidityDecimal
                              callBack:(void (^)(Error_Code code, NSDictionary *result))callBack;

 

// MARK: - APP测量值回写  3.5.4.45

/// 测量值回写
/// @param type 数据类型
/// @param values <#values description#>
/// @param callBack <#callBack description#>
- (void)measurementDataWriteback:(NSInteger)type
                          values:(NSArray <NSNumber *> *)values
                        callBack:(void (^)(Error_Code code,
                                           NSDictionary *result))callBack;

// MARK: - 获取相关

// MARK: - 获取设备基本信息 3.5.3.1

// device info 3.5.3.1
- (void)getDevInfo:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 获取设备支持的功能信息 3.5.3.2

/// get fundations 3.5.3.2
- (NSDictionary *)getFoundationList;

// MARK: - 获取设备MAC地址 3.5.3.3

// get macaddress 3.5.3.3
- (void)getDevMac:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 获取设备名称或型号信息 3.5.3.4

// deve type name 3.5.3.4
- (void)getDevName:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 获取当前心率 3.5.3.6

- (void)getCurrentHeartRate:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 获取当前血压 3.5.3.7
- (void)getCurrentBloodPressure:(void (^)(Error_Code code,
                                          NSDictionary *result))callBack;


// MARK: - 获取用户配置信息 3.5.3.8

/// 获取用户配置信息
- (void)getUserConfigurationInfo:(void (^)(Error_Code code,
                                     NSDictionary *result))callBack;


// MARK: - 获取设备主界面式配置 (主题样式) 3.5.3.10

/// get theme
- (void)getMainTheme:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 获取心电右电极位置 3.5.3.11

- (void)getEcgLocation:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 获取当前实时运动数据 3.5.3.13

/// 获取实时运动数据 ; V0.85及以上版本支持 (需要监听通知)
- (void)getNowSport:(void (^)(Error_Code code, NSDictionary *result))callBack;

  
// MARK: - 获取历史记录概要信息 3.5.3.14
 
/// 获取历史记录概要信息;  V0.85及以上版本支持
/// @param callBack 结果
- (void)getHealthHistoryOutline:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 获取实时温度 3.5.3.15

/// 获得手环的实时温度
- (void)getDevRealTemperature:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 获取屏幕显示信息 3.5.3.16

- (void)getDeviceScreenInfo:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 获取天地五行的数据 3.5.3.17

// 0x00：天干地支, 0x01：五运六气, 0x02：季节
- (void)getHeavenAndEarthAndFiveElementsInfo:(NSInteger)type
                                    callBack:(void (^)(Error_Code code, NSDictionary *result))callBack;



// MARK: - 获取当前血氧 get Spo2 3.5.3.18

- (void)getBloodOxygen:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 获取当前环境光 3.5.3.19

- (void)getAmbientLightInfo:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 获取当前环境温湿度 3.5.3.20
 
- (void)getAmbientTemperatureAndHumidityInfo:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 获取传感器采样策略 3.5.22


///  传感器采样策略
/// @param type
            /// 0x00: PPG
            /// 0x01: 加速度数据
            /// 0x02：ECG
            /// 0x03：温湿度
            /// 0x04：环境光
            /// 0x05：体温
/// @param callBack 回调
- (void)getSensorSamplingInformation:(NSInteger)type
                            callBack:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 获取设备工作模式 3.5.3.23

- (void)getDeviceWorkMode:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 获取保险相关的信息 3.5.3.24

- (void)getInsuranceInformation:(NSInteger)type
                       callBack:(void (^)(Error_Code code,
                                          NSDictionary *result))callBack;


// MARK: - 获取上传提醒配置信息 3.5.3.25

/// 获取上传提醒配置信息
- (void)getUploadRemindersInfomation:(void (^)(Error_Code code,
                                               NSDictionary *result))callBack;


// MARK: - 获取手动模式工作状态 3.5.3.26

- (void)getManualModeWorkingState:(void (^)(Error_Code code,
                                           NSDictionary *result))callBack;

// MARK: - 获取事件提醒的信息 3.5.3.27

/// 获得事件的详细数据
- (void)getEventDetailInfo:(void (^)(Error_Code code,
                                     NSDictionary *result))callBack;


// MARK: - 获取当前手环芯片方案 3.5.3.28

/// 获得芯片的信息
- (void)getDeviceMCUInfo:(void (^)(Error_Code code,
                                   NSDictionary *result))callBack;

// MARK: - 获取手环设置提醒状态 3.5.3.31

/// 提醒状态 0x00:蓝牙断开提醒 0x01:运动达标提醒
- (void)getDeviceRemindSettingStatus:(NSInteger)type callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 获取实时数据 3.5.3.32

/// 获得实时数据
- (void)getDeviceRealTimeMonitoringData:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 设置相关 Settings

// MARK: - 3.5.1 时间设置 3.5.1 SDK连接后会自动设置(默认日历)


/// 设置时间
/// @param year 年份
/// @param month 月份
/// @param day 日期
/// @param hour 时
/// @param minute 分
/// @param second 少
/// @param weekDay 星期 0-6(星期一 ~ 星期天)
/// @param callBack 设置结果
- (void)settingTime:(NSInteger)year
              month:(NSInteger)month
                day:(NSInteger)day
               hour:(NSInteger)hour
             minute:(NSInteger)minute
             second:(NSInteger)second
            weekDay:(NSInteger)weekDay
           callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 闹钟设置 3.5.2

// 3.5.2.2 alarm 3.5.2.2.1
// type: 0x00 - sleep ......
// repeat: weekday
- (void)setttingAlarm:(NSInteger)type
            startHour:(NSInteger)hour
             startMin:(NSInteger)min
          alarmRepeat:(NSInteger)repeat
            delayTime:(NSInteger)time
             callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

/// modify alarm  3.5.2.2.4
- (void)modifyAlarm:(NSInteger)oldHour
             oldMin:(NSInteger)oldmin
          alarmType:(NSInteger)type
          startHour:(NSInteger)hour
           startMin:(NSInteger)min
        alarmRepeat:(NSInteger)repeat
          delayTime:(NSInteger)time
           callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


/// delete alarm 3.5.2.2.3
- (void)deleteAlarm:(NSInteger)startHour
           startMin:(NSInteger)startMin
           callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


/// select alarm
- (void)getAlarmSetting:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 目标设置 3.5.2.3

// step
- (void)settingGoalStep:(NSInteger)stepNum
               callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// sleep (Old method)
- (void)settingGoalSleep:(NSInteger)sleepHour
                callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// sleep (New method)
- (void)settingGoalSleep:(NSInteger)sleepHour
                sleepMin:(NSInteger)sleepMin
                callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// calorie
- (void)settingCalorie:(NSInteger)calories
              callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// distance
- (void)settingDistance:(NSInteger)distance
              callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// Exercise time
- (void)settingExerciseHour:(NSInteger)exerciseHour
                exerciseMin:(NSInteger)exerciseMin
                   callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// Effective steps
- (void)settingEffectiveSteps:(NSInteger)effectiveSteps
                     callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 用户信息设置 3.5.2.4

- (void)settingUserInfo:(NSInteger)height
                 weight:(NSInteger)weight
                    sex:(NSInteger)sex
                    age:(NSInteger)age
               callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 单位设置  3.5.2.5

- (void)settingUnit:(NSInteger)distanceUnit  //0x00:km 0x01:mile
             weight:(NSInteger)weightUnit  //0x00:kg 0x01:lb 0x02:st
               temp:(NSInteger)tempUnit  //0x00: °C 0x01: °F
         time24Or12:(NSInteger)timeUnit  //0x00:24 小时 0x01:12 小时
           callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 久座提醒 3.5.2.6

- (void)settingLongsite:(NSInteger)startHour
               startMin:(NSInteger)startMin
                endHour:(NSInteger)endHour
                 endMin:(NSInteger)endMin
             startHour2:(NSInteger)startHour2
              startMin2:(NSInteger)startMin2
               endHour2:(NSInteger)endHour2
                endMin2:(NSInteger)endMin2
               interval:(NSInteger)interval
                 repeat:(NSInteger)repeat
               callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 防丢设置 3.5.2.7

// 3.5.2.7
// old method  only soupport on/off
- (void)settingAntiLost:(BOOL)isOpen
               callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// new method soupport different type setting
- (void)settingAntiLostType:(NSInteger)lostType
                   callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// 3.5.2.8
- (void)settingAntiLostParameter:(NSInteger)mode
                   rssi:(NSInteger)rssi
              delayTime:(NSInteger)delayTime
disconnectionDelayOrNot:(BOOL)disconnectionDelayOrNot
                 repeat:(BOOL)repeat
                        callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 左右手 3.5.2.9 

- (void)settingLeftRightHandWear:(BOOL)isRightHand
                        callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 手机操作系统设置 3.5.2.10


// MARK: - 通知提醒开关设置 3.5.2.11

/// soupport push
- (void)settingPushSwitch:(BOOL)isOpen
                  appArg1:(NSInteger)arg1
                  appArg2:(NSInteger)arg2
                 callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


///// 通知类型
///// @param isOpen 总开关
///// @param notifications YCNotificationType 类型
///// @param callBack 设置结果
//- (void)settingPushSwitch:(BOOL)isOpen
//            notifications:(UInt16)notifications
//                 callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// only souuport call & app
//- (void)settingPushSwitch:(BOOL)isOpen
//                     call:(BOOL)call
//                      app:(BOOL)app
//                  message:(BOOL)message
//                 callback:(void (^)(Error_Code, NSDictionary * _Nonnull))callBack;



// MARK: - 心率监测与报警 3.5.2.12 / 3.5.2.13


/// 心率报警设置
/// @param isOpen 开关
/// @param highHeart 最高心率值
/// @param lowHeart 最低心率值
/// @param callBack 回调
- (void)settingHeartAlarm:(BOOL)isOpen
                highHeart:(NSInteger)highHeart
                 lowHeart:(NSInteger)lowHeart
                 callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

/// 心率监测模式设置
/// @param heartMode 模式 0x00手动模式 0x01自动模式
/// @param time 自动模式下心率监测间隔(分) 1-60
/// @param callBack 完成回调
- (void)settingHeartMode:(NSInteger)heartMode
           autoHeartTime:(NSInteger)time
                callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 找手机开关设置 3.5.2.14

- (void)settingFindPhone:(BOOL)isEnable
                callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 恢复出厂设置 3.5.2.15

- (void)settingReset:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 勿扰模式设置 3.5.2.16

- (void)settingNoDisturb:(BOOL)isOpen
               startHour:(NSInteger)startHour
                startMin:(NSInteger)startMin
                 endHour:(NSInteger)endHour
                  endMin:(NSInteger)endMin
                callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 语言设置  3.5.2.19

//0x00:英语 0x01: 中文
- (void)settingLanguage:(NSInteger)languageType
               callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 抬腕亮屏开关设置  3.5.2.20

- (void)settingRaiseScreen:(BOOL)isOpen
                  callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 显示屏亮度设置 3.5.2.21

// 0x00:低  0x01: 中  0x02: 高  0x03：自动  0x04: 较低  0x05：较高
- (void)settingDisplayBright:(NSInteger)brightLevel
                    callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 肤色设置 3.5.2.22

//0x00:白 0x01: 白间黄 0x02: 黄 0x03: 棕色 0x04: 褐色 0x05: 黑 0x07: 其它
- (void)settingSkinColor:(NSInteger)skinColorType
                 callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 血压范围设置 3.5.2.23

//0x00:偏低 0x01: 正常 0x02: 轻微偏高 0x03: 中度偏高 0x04: 重度高
- (void)settingBloodRange:(NSInteger)rangeMode
                callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 设置蓝牙设备名称 3.5.2.24

- (void)settingDeviceName:(NSString *)name
                 callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 设置传感器采样率 3.5.2.25

- (void)settingSensorSamplingRate:(NSInteger)ppg
                              ecg:(NSInteger)ecg
                          gSensor:(NSInteger)gSendor
                 tempeatureSensor:(NSInteger)tempeatureSensor
                         callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 设备主界面样式配置 3.5.2.26

/// settint theme
- (void)settingThemeIndex:(NSInteger)index
               callback:(void (^)(Error_Code code, NSDictionary *result))callBack;
 

// MARK: - 设置睡眠提醒时间 3.5.2.27

/// 设置睡眠提醒
/// @param sleepStartHour 睡眠开始时间小时 (0-23)
/// @param sleepStartMin 睡眠开始时间分(0-59)
/// @param sleepRepeat 重复  (bit7~bit0), bit7为总开关, bit6~bit0周日至周一
/// @param callBack 结果回调
- (void)sleepAlarmSetting:(NSInteger)sleepStartHour
                 startMin:(NSInteger)sleepStartMin
                   repeat:(NSInteger)sleepRepeat
                 callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 数据采集配置(传感器采样策略设置) 3.5.2.28 / 3.5.2.50


/// 设置PPG数据采集
/// @param isOpen 是否开启 YES开启 NO关闭
/// @param timeLen 测试时长,单位 秒
/// @param timeInterval 测试间隔,单位 分
/// @param callBack 结果
- (void)dataCollectPPGSetting:(BOOL)isOpen
                      timeLen:(NSInteger)timeLen
                 timeInterval:(NSInteger)timeInterval
                     callback:(void (^)(Error_Code code, NSDictionary *result))callBack;



/// 传感器采样策略设置
/// @param isEnable 是否开启 YES开启 NO关闭
/// @param type
                /// 0x00: PPG
                /// 0x01: 加速度数据
                /// 0x02：ECG
                /// 0x03：温湿度
                /// 0x04：环境光
                /// 0x05：体温
/// @param timeLen 测试时长,单位 秒
/// @param timeInterval 测试间隔,单位 分
/// @param callBack 回调
- (void)settingDataCollection:(BOOL)isEnable
                         type:(NSInteger)type
              acquisitionTime:(NSInteger)timeLen
          acquisitionInterval:(NSInteger)timeInterval
                     callBack:(void (^)(Error_Code code, NSDictionary *result))callBack;


/// 设置不同工作模式下传感器采样策略设置
/// @param mode 是否开启 工作模式
/// @param type
                /// 0x00: PPG
                /// 0x01: 加速度数据
                /// 0x02：ECG
                /// 0x03：温湿度
                /// 0x04：环境光
                /// 0x05：体温
/// @param timeLen 测试时长,单位 秒
/// @param timeInterval 测试间隔,单位 分
/// @param callBack 回调
- (void)settingWorkModeDataCollection:(NSInteger)mode
                                 type:(NSInteger)type
                      acquisitionTime:(NSInteger)timeLen
                  acquisitionInterval:(NSInteger)timeInterval
                             callBack:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 血压监测模式设置 3.5.2.29

- (void)settingBloodMode:(NSInteger)bloodModeEnable
           autoBloodTime:(NSInteger)time
                callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 温度模式设置 3.5.2.30 / 3.5.2.32 / 3.5.2.33

/// 设置温度模式
/// @param mode  设置模式
/// @param value 温度值
/// @param callBack 回调
- (void)settingTemperatureMode:(NSInteger)mode
                         value:(NSInteger)value
                      callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


/// 设置温度报警
/// @param isEnabel 0x01: 开启 0x00: 关闭
/// @param highTemperatureValue 高温报警阈值 36 – 100
/// @param lowTemperatureValue 低温报警阈值 -127 - 36
/// @param callBack 执行回调
- (void)settingTemperatureWarningEnabel:(NSInteger)isEnabel
                        highTemperatureValue:(NSInteger)highTemperatureValue
                       lowTemperatureValue:(NSInteger)lowTemperatureValue
                                  callback:(void (^)(Error_Code code,
                                                     NSDictionary * _Nonnull result))callBack;
 

/// 设置温度报警 (支持浮点数)
/// @param isEnable isEnable 0x01: 开启 0x00: 关闭
/// @param highTemperatureIntegerValue 高温报警整数阈值 36 – 100
/// @param highTemperatureDecimalValue 高温报警整数阈值 1 – 9
/// @param lowTemperatureIntegerValue 低温报警阈值 -127 - 36
/// @param lowTemperatureDecimalValue 高温报警整数阈值 1 – 9
/// @param callBack 执行回调
- (void)settingTemperatureWarningEnable:(NSInteger)isEnable
            highTemperatureIntegerValue:(NSInteger)highTemperatureIntegerValue
            highTemperatureDecimalValue:(NSInteger)highTemperatureDecimalValue
             lowTemperatureIntegerValue:(NSInteger)lowTemperatureIntegerValue
             lowTemperatureDecimalValue:(NSInteger)lowTemperatureDecimalValue
                                  callback:(void (^)(Error_Code code,
                                                     NSDictionary * _Nonnull result))callBack;

/// 设置温度监测模式
/// @param isEnabel 0x01: 开启 0x00: 关闭
/// @param monitoringInterval 间隔(分) 1-60
/// @param callBack 回调
- (void)settingTemperatureMonitoringEnabel:(NSInteger)isEnabel
                        monitoringInterval:(NSInteger)monitoringInterval
                                  callback:(void (^)(Error_Code code,
                                                     NSDictionary * _Nonnull result))callBack;



// MARK: - 息屏时间设置 3.5.2.34


///  设置息屏时间
/// @param time
                /// 0x00：5s
                /// 0x01: 10s
                /// 0x02: 15s
                /// 0x03：30s
/// @param callBack 回调
- (void)settingBreathScreenTime:(NSInteger)time
                       callback:(void (^)(Error_Code code,
                                          NSDictionary * _Nonnull result))callBack;


// MARK: - 环境光监测模式设置 3.5.2.35
 
- (void)settingAmbientLightMode:(BOOL)isEnable
                   timeInterval:(NSInteger)timeInterval
                       callback:(void (^)(Error_Code code,
                       NSDictionary * _Nonnull result))callBack;


// MARK: - 工作模式切换  3.5.2.36
 

/// 设置工作模式
/// @param mode 类型
        /// 0x00：设置为正常工作模式
        /// 0x01: 设置为关怀工作模式,
        /// 0x02：设置为省电工作模式
        /// 0x03:  设置为自定义工作模式
/// @param callBack 回调
- (void)settingWorkMode:(NSInteger)mode
               callback:(void (^)(Error_Code code,
                                  NSDictionary * _Nonnull result))callBack;


// MARK: - 意外监测模式设置 3.5.2.37

- (void)settingAccidentMonitoringEnable:(BOOL)isEnable
                               callback:(void (^)(Error_Code code,
                                                  NSDictionary * _Nonnull result))callBack;


// MARK: - 手环提醒设置 3.5.2.38


/// 蓝牙断开提醒  && 蓝牙断开提醒
/// @param isEnable YES - 打开，NO - 关闭
/// @param type 0x00: 蓝牙断开提醒， 0x01：运动达标提醒
/// @param callBack 回调
- (void)settingBraceletReminder:(BOOL)isEnable type:(NSInteger)type
                       callback:(void (^)(Error_Code code,
                                          NSDictionary * _Nonnull result))callBack;



// MARK: - 血氧设置 3.5.2.39
- (void)settingBloodOxygenMode:(BOOL)isEnable timeInterval:(NSInteger)timeInterval
                      callback:(void (^)(Error_Code code,
                                         NSDictionary * _Nonnull result))callBack;


// MARK: - 日程设置 3.5.2.40 / 3.5.3.21

/*
事件ID    对应事件
0x00    起床
0x01    早饭
0x02    晒太阳
0x03    午饭
0x04    午休
0x05    运动
0x06    晚饭
0x07    睡觉
0x08    自定义
 
 */

// 1.增加
/// 增加新的日程
- (void)addSchedule:(BOOL)scheduleEnable
      scheduleIndex:(NSInteger)scheduleIndex
          eventType:(NSInteger)eventType
         eventIndex:(NSInteger)eventIndex
        eventEnable:(BOOL)eventEnable
          eventTime:(NSInteger)eventTime
          eventName:(NSString *)eventName
           callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


- (void)modifySchedule:(BOOL)scheduleEnable
         scheduleIndex:(NSInteger)scheduleIndex
             eventType:(NSInteger)eventType
            eventIndex:(NSInteger)eventIndex
           eventEnable:(BOOL)eventEnable
             eventTime:(NSInteger)eventTime
             eventName:(NSString *)eventName
              callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


- (void)deleteSchedule:(NSInteger)scheduleIndex
            eventIndex:(NSInteger)eventIndex
             eventType:(NSInteger)eventType
              callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


 
- (void)getSchedule:(void (^)(Error_Code code, NSDictionary *result))callBack;

// MARK: - 环境温湿度设置 3.5.2.41

- (void)settingEnvironmentalTemperatureAndHumidityMonitoringMode:(BOOL)isEnable
                                                    timeInterval:(NSInteger)timeInterval
                                                        callback:(void (^)(Error_Code code,
                                                                           NSDictionary * _Nonnull result))callBack;




// MARK: - 日程开关设置 3.5.2.42

- (void)settingScheduleEnable:(BOOL)isOpen
                     callback:(void (^)(Error_Code code, NSDictionary *result))callBack;



// MARK: -  计步时间设置 3.5.2.43


/// 计步时间设置
/// @param time 取值 10, 5, 1 单位 分钟
/// @param callBack 回调
- (void)settingCaclulateStepsTime:(NSInteger)time
                         callback:(void (^)(Error_Code code, NSDictionary *result))callBack;



// MARK: - 上传提醒设置 3.5.2.44


///  上传提醒设置
/// @param isOpen YES - 开， NO - 关
/// @param data 存储阈值 0 ~ 100
/// @param callBack 执行回调
- (void)settingUploadReminders:(BOOL)isOpen
                          data:(NSInteger)data
                      callback:(void (^)(Error_Code code,
                                         NSDictionary *result))callBack;

// MARK: - 蓝牙广播间隔设置 3.5.2.45


/// 蓝牙广播间隔设置
/// @param interval 时间间隔 20 ~ 10240ms
/// @param callBack 回调
- (void)settingBroadcastInterval:(NSInteger)interval
                        callback:(void (^)(Error_Code code,
                                           NSDictionary *result))callBack;

// MARK: - 蓝牙发射功率 3.5.2.46

/// 蓝牙发射功率
/// @param power 功率值 最好不要设置成负值
/// @param callBack 回调
- (void)settingTransmitPower:(NSInteger)power
                    callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 运动心率区间设置 3.5.2.47


/// 设置运动心率区间
/// @param type 运动类型
/// @param lowestValue 最低心率值
/// @param highestValue 最高心率值
/// @param callBack 回调
- (void)settingExerciseHeartRateZone:(NSInteger)type
                         lowestValue:(NSInteger)lowestValue
                        highestValue:(NSInteger)highestValue
                            callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 事件提醒设置 3.5.2.48


/// 添加事件
/// @param eventEnable 是否开启
/// @param eventyType 类型 0x00/0x01
/// @param eventHour 0~ 23
/// @param eventMin 0 ~ 59
/// @param eventRepeat 按星期
/// @param intervals 下一次提醒的时间时间隔
/// @param eventName 名称
/// @param callBack 回调
- (void)addEventReminder:(BOOL)eventEnable
              eventyType:(NSInteger)eventyType
               eventHour:(NSInteger)eventHour
                eventMin:(NSInteger)eventMin
             eventRepeat:(NSInteger)eventRepeat
               intervals:(NSInteger)intervals
               eventName:(NSString *)eventName
                callback:(void (^)(Error_Code code, NSDictionary * _Nonnull result))callBack;


/// 删除指定时间的事件
/// @param eventID 事件ID
/// @param callBack 回调
- (void)deleteEventReminder:(NSInteger)eventID
                   callback:(void (^)(Error_Code code, NSDictionary * _Nonnull result))callBack;

/// 修改事件
/// @param eventID 事件ID
/// @param eventEnable 是否开启
/// @param eventyType 类型 0x00/0x01
/// @param eventHour 0~ 23
/// @param eventMin 0 ~ 59
/// @param eventRepeat 按星期计算重复
/// @param intervals 下一次提醒的时间时间隔
/// @param eventName 名称
/// @param callBack 回调
- (void)modifyEventReminder:(NSInteger)eventID
                eventEnable:(BOOL)eventEnable
                 eventyType:(NSInteger)eventyType
                  eventHour:(NSInteger)eventHour
                   eventMin:(NSInteger)eventMin
                eventRepeat:(NSInteger)eventRepeat
                  intervals:(NSInteger)intervals
                  eventName:(NSString *)eventName
                   callback:(void (^)(Error_Code code, NSDictionary * _Nonnull result))callBack;


// MARK: - 事件提醒设置 3.5.2.49

/// 设置事件提醒的总开关
/// @param isOpen 是否使能
/// @param callBack 设置回调
- (void)settingEventReminderEnable:(BOOL)isOpen
                          callback:(void (^)(Error_Code code, NSDictionary *result))callBack;


// MARK: - 保险界面开关控制 5.5.2.51


/// 保险界面开关控制
/// @param isEnable 是否使能
/// @param callBack 回调
- (void)settingShowInsuranceEnable:(BOOL)isEnable
                          callback:(void (^)(Error_Code code, NSDictionary *result))callBack;

#pragma mark- APP控制命令相关


- (void)beginECGTest;
- (void)endECGTest:(BOOL)isSync;
 
/// 判断队列里是否有ECG,PPG同步
- (BOOL)isQueueHaveEcgPpgData;
 

@end

NS_ASSUME_NONNULL_END
