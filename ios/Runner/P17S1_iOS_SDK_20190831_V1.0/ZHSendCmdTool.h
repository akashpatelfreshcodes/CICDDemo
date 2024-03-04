//
//  ZHSendCmdTool.h
//
//  Created by Soar.
//  Copyright ©  zhouhai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHAlarmClockModel.h"

/*
 功能开关类型
 */
typedef NS_ENUM(NSInteger, FunctionSwitchType) {
    FunctionPhoneType,          // 通话 / call
    FunctionSMSType,            // 短信 / SMS
    FunctionBrightScreenType,   // 抬腕亮屏 / Lift the wrist screen
    FunctionNotDisturbType,     // 勿扰模式 / Do not disturb mode
    FunctionMonitorType,        // 整点监测开关
    FunctionTimeType,           // 24小时制(YES为24，NO为12) / 24-hour clock (YES is 24, NO is 12)
    FunctionUnitType,           // 公制英制切换(YES为公制，NO为英制) / Metric system switching (YES is metric, NO is English)
    FunctionWeChatType,         // 微信   /  WeChat
    FunctionQQType,             // QQ
    FunctionSkypeType,          // Skype
    FunctionWhatsAppType,       // WhatsApp
    FunctionFacebookType,       // Facebook
    FunctionLinkedInType,       // LinkedIn
    FunctionTwitterType,        // Twitter
    FunctionViberType,          // Viber
    FunctionLineType            // Line

};

/*
 功能设置时间类型
 */
typedef NS_ENUM(NSInteger, FunctionSetTimeType) {
    FunctionSedentaryType,      // 久坐  /   Sedentary
    FunctionMedicineType,       // 吃药  /   Taking medicine
    FunctionDrinkType,          // 喝水  /   Drink water
};


@interface ZHSendCmdTool : NSObject

/**
 *  实例化 / Instantiation
 */
+ (ZHSendCmdTool *)shareIntance;

/**
 *  同步时间指令，向蓝牙同步电量，运动，睡眠，心率等数据，从蓝牙获得数据需要此指令 / Synchronize time command, synchronize power, motion, sleep, heart rate and other data to Bluetooth. This command is required to obtain data from Bluetooth.
 */
-(void)synchronizeTime;

/*******************
 *
 *  发送告诉手环是iOS设备指令及某国语言(此为连接蓝牙成功后必设置项）
 *  @param  language_value 多国语言标识位：00为英文 1为中文 2为繁体 3为日 4为法 5为德 6为意大利 7为西班牙 8为俄罗斯 9为葡萄牙 10为马来西亚语 11为韩文 12为波兰
 */
- (void)sendiOSDeviceAndLanguageValue:(int)language_value;

/*******************
 * 发送计步目标 / Send step gauge target
 *
 * @param target  步数目标值<可设置范围：1000-100000> /Count the target < can set range: 1000-100000 >
 *
 */
- (void)sendSportTarget:(int)target;

/*******************
 * 发送心电测量开关 / Send ECG measurement switch
 *
 * @param keyValue  开为：0x01  关为：0x00 / Open as: 0x01 Off: 0x00
 *
 */
- (void)sendEcgDataCmd:(int)keyValue;

/**
 *  查找手环指令 / Find bracelet instructions
 */
- (void)sendFindBraceletCmd;

/**
 *  摇摇拍照指令  /  Shake the camera command
 */
- (void)sendShakePhotographCmd;

/**
 *  DFU(固件升级指令) (Firmware upgrade instruction)
 */
- (void)sendUpdateCmd;

/**
 *  恢复出厂设置指令 / Restore factory settings
 */
- (void)sendFactorySettingCmd;

/**
 *  发送测量后心率 血压 / Send measured heart rate, blood pressure
 *
 *  @param heart 心率 / HeartRate
 *  @param systolic 收缩压(高压) / Systolic pressure (high pressure)
 *  @param diastolic 舒张压(低压) / Diastolic blood pressure (low pressure)
 *
 */
- (void)sendHeartDataCmd:(int)heart andSystolic:(int)systolic andDiastolic:(int)diastolic;



/**
 *   蓝牙同步个人信息（此为连接蓝牙成功后必设置项）/ Bluetooth sync personal information (this is a mandatory item after connecting Bluetooth successfully)
 *
 *  @param ageStr :25  sex:1  height:170cm  weight:65kg
 */
-(void)synPersonalInformationForAge:(NSString *)ageStr andSex:(NSString *)sexStr andHeight:(NSString *)heightStr andWeight:(NSString *)weightStr;

/*******************
 * 发送校准收缩压，心率 （此为连接蓝牙成功后必设置项）/ Send calibration systolic pressure, heart rate (this is a mandatory item after connecting Bluetooth successfully)
 *
 * @param systolic 校准收缩压(高压) 默认：120 mmHg / Calibration systolic pressure (high pressure) Default: 120 mmHg
 * @param heartRate 校准心率  默认：70 bpm / Calibrate heart rate Default: 70 bpm
 *
 */
-(void)sendBloodPressureParameterForGaoya:(int)systolic andHeartRate:(int)heartRate;

/*******************
 * 连接蓝牙时发送默认开关指令（此为通知必设置项) / Send the default switch command when connecting to Bluetooth (this is the notification must be set)
 *
 * @param
 * time 12 / 24Hour system(0 is 12 1 is 24)
 * unit: metric inch (0 is metric 1 is inch)
 * hand: wrist lift screen
 * switch wrist: turn wrist screen switch
 * switch monitor: heart rate whole point monitoring
 * notDisturb: do not disturb mode
 * 12/24 hour system (0 is 12 1 for 24)
 * unit: metric system (0 is metric 1 for inch)
 * hand: lift wrist
 * switch bright: wrist switch
 * switch monitor: heart rate point monitoring
 * notDisturb: Do not disturb mode
  *
 */
- (void)sendRemindStatusPhone:(int)phone andSMS:(int)sms andWeChat:(int)weChat andQQ:(int)qq andSkype:(int)skype andWhatsapp:(int)whatsapp andFacebook:(int)facebook andTime:(int)time andUnit:(int)unit andHand:(int)hand andWrist:(int)wrist andMonitor:(int)monitor andNotDisturb:(int)notDisturb andLinkedIn:(int)linkedIn andTwitter:(int)twitter andViber:(int)viber andLine:(int)line;

/*******************
 * 发送提醒开关指令 / Send reminder switch command
 *
 * @param type 功能类型 枚举FunctionSwitchType /  Function Type Enumeration FunctionSwitchType
 * @param isOpen 是否开着的 / Whether it is open
 *
 */
- (void)setRemindForType:(FunctionSwitchType)type withSwitch:(BOOL)isOpen;

/*******************
 * 久坐、吃药、喝水提醒 / Sedentary, taking medicine, drinking water reminder
 *
 * @param type 功能类型 枚举FunctionSetTimeType / Function Type Enumeration FunctionSetTimeType
 * @param startTime 开始时间 格式：HH:mm  / Start time Format: HH: mm
 * @param endTime   结束时间 格式：HH:mm / End time Format: HH: mm
 * @param interval  时间间隔 四个选择--久坐、喝水：1，2，3，4小时  吃药：4，8，12，16小时 /Time interval Four choices - sedentary, drinking water: 1, 2, 3, 4 hours medication: 4, 8, 12, 16 hours
 * @param isOpen  是否打开 / Whether to open
 *
 */
- (void)setRemindTimeForType:(FunctionSetTimeType)type withStartTime:(NSString *)startTime EndTime:(NSString *)endTime Interval:(int)interval andSwitch:(BOOL)isOpen;

/*******************
 * 设置会议提醒 / Set meeting reminder
 *
 * @param time 提醒时间 格式：yyyy:MM:dd HH:mm / Reminder time Format: yyyy:MM:dd HH:mm
 * @param isOpen  是否打开 / Whether to open
 *
 */
- (void)setMeetingRemindForTime:(NSString *)time andSwitch:(BOOL)isOpen;

/*******************
 * 设置闹钟 / Set an alarm
 *
 * @param arrModel 闹钟数据模型数组 / Alarm clock data model array
 *
 */
- (void)setAlarmClockForModel:(NSArray <ZHAlarmClockModel *> *)arrModel;


@end
