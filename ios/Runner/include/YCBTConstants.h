//
//  YCBTConstants.h
//  SmartHealth
//
//  Created by qiaoliwei on 2019/3/24.
//  Copyright © 2019年 yucheng. All rights reserved.
//

#ifndef YCBTConstants_h
#define YCBTConstants_h

//static BOOL enableDebug = YES;

//#define DBG_ON 1
//
//#if DBG_ON
//#define DBG(fmt, arg...) do{NSLog(fmt, ##arg);}while(0)
//#else
//#define DBG(fmt, arg...) do{}while(0)
//#endif

typedef enum : NSUInteger {
    Error_Ok,
    Error_BLENOTOpen,
    Error_BLEDisconnect,
    Error_Failed,
    Error_TimeOut
} Error_Code;

typedef void (^YCSendCallBack)(Error_Code code,  NSDictionary * _Nullable result);


///// 通知类型
//typedef NS_ENUM(NSUInteger, YCNotificationType) {
//
//    YCNotificationTypeNone      = 0,
//
//    YCNotificationTypeApp       = 1 << 0,
//    YCNotificationTypeSnapchat  = 1 << 1,
//    YCNotificationTypeLine      = 1 << 2,
//    YCNotificationTypeSkype     = 1 << 3,
//    YCNotificationTypeInstagram = 1 << 4,
//    YCNotificationTypeLinkedIn  = 1 << 5,
//    YCNotificationTypeWhatsAPP  = 1 << 6,
//    YCNotificationTypeMessenger = 1 << 7,
//
//    YCNotificationTypeTwitter   = 1 << (8 + 0),
//    YCNotificationTypeFacebook  = 1 << (8 + 1),
//    YCNotificationTypeSinaWeiBo = 1 << (8 + 2),
//    YCNotificationTypeQQ        = 1 << (8 + 3),
//    YCNotificationTypeWeChat    = 1 << (8 + 4),
//    YCNotificationTypeEmail     = 1 << (8 + 5),
//    YCNotificationTypeMessage   = 1 << (8 + 6),
//    YCNotificationTypeCall      = 1 << (8 + 7),
//
//    YCNotificationTypeAll       = 0xFFFF, // 全部支持
//
//};


/// 运动类型
typedef NS_ENUM(NSInteger, YCDeviceSportType) {
     
    YCDeviceSportTypeNone           = 0,    // 保留
    YCDeviceSportTypeRun            = 0x01, // 跑步 (户外)
    YCDeviceSportTypeSwimming       = 0x02, // 游泳
    YCDeviceSportTypeRiding         = 0x03, // 户外骑行
    YCDeviceSportTypeFitness        = 0x04, // 健身
    
    YCDeviceSportTypeRopeskipping   = 0x06, // 跳绳
    YCDeviceSportTypePlayball       = 0x07, // 篮球(打球)
    YCDeviceSportTypeWalk           = 0x08, // 健走
    YCDeviceSportTypeBadminton      = 0x09, // 羽毛球
   
    YCDeviceSportTypeFootball       = 0x0A, // 足球
    YCDeviceSportTypeMountaineering = 0x0B, // 支持登山
    YCDeviceSportTypePingPang       = 0x0C, // 支持乒乓球

    YCDeviceSportTypeIndoorRunning  = 0x0E, // 室内跑步
    YCDeviceSportTypeOutdoorRunning = 0x0F, // 户外跑步
    YCDeviceSportTypeOutdoorWalking = 0x10, // 户外步行
    YCDeviceSportTypeIndoorWalking  = 0x11, // 室内步行

    YCDeviceSportTypeIndoorRiding   = 0x13, // 室内骑行
    YCDeviceSportTypeStepper        = 0x14, // 踏步机
    YCDeviceSportTypeRowingMachine  = 0x15, // 划船机
    YCDeviceSportTypeRealTimeMonitoring  = 0x16, // 实时监护
    
};

/// 语言种类
typedef NS_ENUM(NSUInteger, YCDeviceLanguage) {
    
    YCDeviceLanguageEnglish             = 0x00,
    YCDeviceLanguageChineseSimplified   = 0x01,
    YCDeviceLanguageRussian             = 0x02,
    YCDeviceLanguageGerman              = 0x03,
    YCDeviceLanguageFrench              = 0x04,
    YCDeviceLanguageJapanese            = 0x05,
    YCDeviceLanguageSpanish             = 0x06,
    YCDeviceLanguageItalian             = 0x07,
    YCDeviceLanguagePortuguese          = 0x08,
    YCDeviceLanguageKorean              = 0x09,
    YCDeviceLanguagePoland              = 0x0A,
    YCDeviceLanguageMalay               = 0x0B,
    YCDeviceLanguageChineseTradition    = 0x0C,
    YCDeviceLanguageThai                = 0x0D,
    
    YCDeviceLanguageVietnamese          = 0x0F,
    YCDeviceLanguageHungarian           = 0x10, // 匈牙利语
    YCDeviceLanguageArabic              = 0x1A,
    YCDeviceLanguageGreek               = 0x1B,
    YCDeviceLanguageMalaysian           = 0x1C, //马来西亚
    YCDeviceLanguageHebrew              = 0x1D,
    YCDeviceLanguageFinnish             = 0x1E,
    YCDeviceLanguageCzech               = 0x1F,
    YCDeviceLanguageCroatian            = 0x20, // 克罗地亚
    
    YCDeviceLanguagePersian             = 0x24, // 伊朗 波斯
    
    YCDeviceLanguageUkrainian           = 0x27, // 乌克兰
    YCDeviceLanguageTurkish             = 0x28, // 土耳其语
    
    YCDeviceLanguageDanish              = 0x2B, // 丹麦语
    YCDeviceLanguageSwedish             = 0x2C, // 瑞典语
    YCDeviceLanguageNorwegian           = 0x2D, // 挪威语
    YCDeviceLanguageRomanian            = 0x32, // 罗马尼亚语
    
};

/*
 设备 蓝牙连接状态 改变
 */
extern NSString * const YCBTConnectStateChangeKey;



#endif /* YCBTConstants_h */
