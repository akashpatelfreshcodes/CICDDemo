//
//  ZHBlePeripheral.h
//
//  Created by Soar.
//  Copyright ©  zhouhai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>


@protocol ZHBlePeripheralDelegate <NSObject>

@optional
/*
 * 蓝牙状态更新的回调 / Bluetooth status update callback
 */
- (void)didUpdateBlueToothState:(CBCentralManager *)central;
/*
 * 搜索找到设备回调 / Search find device callback
 */
- (void)didFindPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber*)RSSI;
/*
 * 连接蓝牙成功回调 / Connect Bluetooth successfully callback
 */
- (void)didConnectPeripheral:(CBPeripheral *)peripheral;
/*
 * 连接蓝牙失败回调 / Connect Bluetooth failure callback
 */
- (void)didFailToConnectPeripheral:(CBPeripheral *)peripheral;
/*
 * 断开蓝牙回调 / Disconnect Bluetooth callback
 */
- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral;
/*
 * 未发现服务的回调 / No callbacks found for the service
 */
- (void)notfindAvailableDevice:(CBPeripheral *)peripheral;
/*
 * 连接错误回调 / Connection error callback
 */
- (void)connectPeripheralError:(NSString *)error;

@end

@protocol ZHBleSportDataSource <NSObject>

@required
/*
 * 设置用户身高(计算距离、卡路里需要)(若为空或0，则为默认值：175 kg) / Set the user's height (required distance, calorie required) (if empty or 0, the default value: 175 kg)
 */
- (CGFloat)setUserHeight;
/*
 * 设置用户体重(计算距离、卡路里需要)(若为空或0，则为默认值：60 kg) / Set user weight (calculation distance, calorie required) (if empty or 0, default value: 60 kg)
 */
- (CGFloat)setUserWeight;

@optional
/*******************
 * 获得某天的运动数据 / Get sports data for a certain day
 *
 * @param sportDate 某天的日期 格式:yyyy-MM-dd / Date of a certain day Format: yyyy-MM-dd
 * @param sportData 24个小时每个小时运动数据数组（共24条，0-23点）/ 24 hours of motion data array per hour (24 in total, 0-23 points)
 */
- (void)getSportForDate:(NSString *)sportDate andStepData:(NSArray *)sportData andDistance:(CGFloat)distance andKcal:(CGFloat)kcal;

/*******************
 * 获得某天的睡眠数据 (某天的睡眠数据是指在设备端前一天的睡眠数据，例如今天20日的睡眠数据是在设备端是19日) / Get the sleep data of a certain day (The sleep data of a day refers to the sleep data of the day before the device, for example, the sleep data of today's 20th is 19th on the device side)
 *
 * @param sleepDate 某天的日期 格式:yyyy-MM-dd / Date of a certain day Format: yyyy-MM-dd
 * @param sleepTotalTime 总睡眠时长 / Total sleep duration
 * @param typeDate 类型睡眠时长（0:熬夜,1:入睡,2:浅睡,3:深睡,4:中途醒来,5:起床）/ Type sleep duration (0: stay up all night, 1: sleep, 2: light sleep, 3: deep sleep, 4: wake up halfway, 5: get up)
 */
- (void)getSleepForDate:(NSString *)sleepDate forTotalSleepTime:(NSString *)sleepTotalTime andForSleepTypeData:(NSArray *)typeDate;

/*******************
 * 获得某天的心率数据 / Get heart rate data for a certain day
 *
 * @param HRDate 某天的日期 格式:yyyy-MM-dd / Date of a certain day Format: yyyy-MM-dd
 * @param HRData 心率数据 / Heart rate data
 */
- (void)getHeartRateForDate:(NSString *)HRDate forHeartRateData:(NSArray *)HRData;

/*******************
 * 获得MAC地址 / Get the MAC address
 *
 * @param MAC Device mac address (-:-:-:-:-:-)
 */
- (void)getDeviceMAC:(NSString *)MAC;

/*******************
 * 获取设备信息 / Get device information
 *
 * @param deviceNumber 设备类型 / Equipment type
 * @param firmwareVersion 固件版本 / Firmware version
 * @param deviceVersion 设备版本号
 * @param battery 电量 / Electricity
 */
- (void)getDeviceNumber:(NSNumber *)deviceNumber
     andFirmwareVersion:(NSNumber *)firmwareVersion
       andDeviceVersion:(NSString *)deviceVersion
       andDeviceBattery:(NSNumber *)battery;

/*
 * 摇摇拍照指令回调 / Shake the camera command callback
 */
- (void)shakePhotographInstruction;

/*
 * 找手机指令回调 / Looking for a phone callback
 */
- (void)findPhoneInstruction;

/*
 * 同步数据完成回调(运动、睡眠、心率、离线等数据) / Synchronous data completion callback (sports, sleep, heart rate, offline, etc.)
 */
- (void)synchronousDataFinished;

@end

@protocol ZHBleHealthDataSource <NSObject>

@required
/*
 * 设置手环佩戴方式(YES为左手，NO为右手)(若设为空，则为：YES) / Set the bracelet to wear (YES is left hand, NO is right hand) (if set to empty, it is: YES)
 */
- (BOOL)setWearWay;
/*
 * 设置用户校准心率(若为0或者空，则为默认值：70 bpm) / Set the user calibration heart rate (if 0 or empty, the default value is: 70 bpm)
 */
- (int)setCalibrationHR;
/*
 * 设置用户校准高压(收缩压)(若为0或者空，则为默认值：120 mmHg) / Set user calibration high pressure (systolic pressure) (default value: 120 mmHg if 0 or empty)
 */
- (int)setCalibrationSystolic;
/*
 * 设置用户校准低压(舒张压)(若为0或者空，则为默认值：70 mmHg) / Set user calibration low pressure (diastolic pressure) (default value: 70 mmHg if 0 or empty)
 */
- (int)setCalibrationDiastolic;


@optional
/*******************
 * 获得心电测量时导联脱落状态(每次从蓝牙接到的数据) / Get the lead-off status of the ECG measurement (data received from Bluetooth each time)
 *
 * @param leedOff  导联脱落标识 (YES为正常 NO为脱落) / Lead off indicator (YES is normal NO is off)
 */
- (void)getLeedOff:(BOOL)leedOff;

/*******************
 * 获得心电测量时皮肤干燥提示标识(每次从蓝牙接到的数据) / Skin dryness indicator when getting ECG measurements (data received from Bluetooth each time)
 *
 * @param conductive  皮肤干燥提示标识 (YES为正常 NO为干燥) / Dry skin tips (YES is normal NO is dry)
 */
- (void)getConductive:(BOOL)conductive;

/*******************
 * 获得实时心电测量的心电数据(每次从蓝牙接到的数据) / Get real-time ECG filtered ECG data <Data received from Bluetooth each time>
 *
 * @param arrFilterEcgData 每次返回的心电数据，共30秒数据 / Each time you return the ECG data, a total of 30 seconds of data
 * @param HR 实时心电测量的心率值 / Heart rate value of real-time ECG measurement
 * @param systolic 实时心电测量的高压值(收缩压) / High-voltage value (systolic pressure) of real-time ECG measurement
 * @param diastolic 实时心电测量的低压值(舒张压) / Low-voltage value (diastolic blood pressure) of real-time ECG measurement
 * 备注：以下参数,途中测量为默认值计算，测量结束为正确值。建议只在测量结束时显示 / Remarks: The following parameters, the midway measurement is the default value calculation, and the measurement end is the correct value. It is recommended to display only at the end of the measurement
 * @param healthIndex 健康指数 / Health index
 * @param fatigueIndex 疲劳指数 / Fatigue index
 * @param loadIndex 身心负荷 / Physical and mental load
 * @param qualityIndex 身体素质 / Physical fitness
 * @param heartIndex 心脏强度 / Heart strength
 */
- (void)getFilterEcgData:(NSArray *)arrFilterEcgData andHeartRate:(int)HR Systolic:(int)systolic Diastolic:(int)diastolic HealthIndex:(int)healthIndex FatigueIndex:(int)fatigueIndex LoadIndex:(int)loadIndex QualityIndex:(int)qualityIndex heartIndex:(int)heartIndex;

/*******************
 * 获得的PPG数据(每次从蓝牙接到的数据)
 *
 * @param arrPpgData 每次返回的ppg，共30秒数据
 *
 */
- (void)getPpgData:(NSArray *)arrPpgData;

/*******************
 * 离线测量数据开始传输回调
 */
- (void)begainOfflineDataTransfer;

/*******************
 * 离线数据传输完成回调<获取数据> / Offline data transfer completion callback  <Access to data after filtering>
 *
 * @param date 离线测量时间 / Offline measurement time
 * @param arrEcgData 心电滤波后数据 / Ecg data after filtering
 * @param HR 心率 / HeartRate
 * @param systolic  收缩压(高压) / Systolic pressure (high pressure)
 * @param diastolic 舒张压(低压) / Diastolic blood pressure (low pressure)
 * @param healthIndex 健康指数  / Health index
 * @param fatigueIndex 疲劳指数 / Fatigue index
 * @param loadIndex 身心负荷 / Physical and mental load
 * @param qualityIndex 身体素质 / Physical fitness
 * @param heartIndex 心脏强度 / Heart strength
 *
 */
- (void)getOfflineDataForDate:(NSString *)date andFilterEcgData:(NSArray *)arrEcgData andHeartRate:(int)HR Systolic:(int)systolic Diastolic:(int)diastolic HealthIndex:(int)healthIndex FatigueIndex:(int)fatigueIndex LoadIndex:(int)loadIndex QualityIndex:(int)qualityIndex heartIndex:(int)heartIndex;

/*******************
 * 离线测量数据传输失败回调
 */
- (void)errorOfflineDataTransfer;


@end




@interface ZHBlePeripheral : NSObject <CBPeripheralDelegate, CBCentralManagerDelegate>


@property (strong, nonatomic) CBCentralManager * centralManager;
@property (nonatomic, strong) CBPeripheral *mPeripheral;

/*
 * 蓝牙连接代理 / Bluetooth connection agent
 */
@property (nonatomic, weak) id<ZHBlePeripheralDelegate> delegate;
/*
 * 运动数据源 / Motion data source
 */
@property (nonatomic, weak) id<ZHBleSportDataSource> sportDataSource;
/*
 * 心电健康数据源 / ECG health data source
 */
@property (nonatomic, weak) id<ZHBleHealthDataSource> healthDataSource;

/*
 * 蓝牙打开状态 / Bluetooth open status
 */
@property (nonatomic, assign) BOOL mIsOpen; // 蓝牙是否打开 / Whether Bluetooth is turned on

/*
 * 设备连接状态 / Device connection status
 */
@property (nonatomic,assign) BOOL mConnected;//YES 已连接  NO 失去连接 / YES connected NO lost connection

/*
 * 是否重连
 */
@property (assign, nonatomic) BOOL isReconnection;

/*
 设置心电开关 （测量时，需要设为YES，结束时设为NO）/ Set the ECG switch (to be set to YES when measuring, set to NO at the end)
 */
@property (assign, nonatomic) BOOL ecgBool;

/*
 * 实例化 / Instantiation
 */
+ (instancetype)sharedUartManager;

/*
 * deviceUUID
 */
+ (CBUUID *) uartServiceUUID;

/**
 *  扫描蓝牙设备 / Scanning Bluetooth devices
 */
-(void)scanDevice;

/**
 *  停止扫描蓝牙设备 / Stop scanning Bluetooth devices
 */
-(void)stopScan;

/**
 *  连接蓝牙 / Connect to Bluetooth
 */
- (void)didConnect;

/**
 *  断开蓝牙 / Disconnect Bluetooth
 */
- (void)didDisconnect;


/**
 * 写入蓝牙指令 / Write Bluetooth command
 *
 * @param data 需要写入的数据 / Data to be written
 */
- (void) writeData:(NSMutableData *) data;



@end

