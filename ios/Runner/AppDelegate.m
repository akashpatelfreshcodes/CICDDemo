
#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "ZHBlePeripheral.h"
#import "ZHSendCmdTool.h"
#import "ScanDeviceModel.h"
#import "GSHealthKitManager.h"
#import <InetBleSDK/InetBleSDK.h>
#import "AppUser.h"
#import "FlutterDownloaderPlugin.h"
#include "NorchFilter.h"
#import "YCBTProduct.h"
#import "YCBTConstants.h"
#import "CBPeripheral+RSSI.h"
#import "YCECGResultManager.h"
#import "GoogleMaps/GoogleMaps.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <VeepooBleSDK/VeepooBleSDK.h>
#import <BackgroundTasks/BackgroundTasks.h>

///BREAK: Background Watch Data Sync
#import <AVFoundation/AVFoundation.h>


@import  Intents;
@import Firebase;
@import IntentsUI;

@interface FindBleVC : UIViewController <ZHBlePeripheralDelegate, ZHBleHealthDataSource, INUIAddVoiceShortcutViewControllerDelegate> {

}


@property(strong, nonatomic) NSMutableArray *foundPeripherals;//All peripherals
@property(strong, nonatomic) CBPeripheral *peripheral; //Single perimeter
@end


@interface AppDelegate () <AnalysisBLEDataManagerDelegate, INBluetoothManagerDelegate> {
}
@property(nonatomic, strong) NSMutableArray *peripheralArray;
@property(nonatomic, assign) BOOL isAddPeripheraling;
@property(nonatomic, strong) AppUser *appUser;
@property(nonatomic) int unit;

///BREAK: Background Watch Data Sync
@property(nonatomic, strong) NSTimer *syncTimer;
@property(nonatomic, strong) AVAudioPlayer *player;
@property(nonatomic, strong) AVAudioSession *session;

@end


@implementation AppDelegate

NSMutableArray *hBandDevices;

FlutterMethodChannel *channel;
NSMutableArray *deviceList;
FlutterResult resultForConnect;
FlutterResult resultForDisConnect;
FlutterResult resultForHeartRate;


GSHealthKitManager *healthKitManager;

int seconds;// Measure 30 seconds countdown
NSTimer *timer; // Timer

NSArray *arrEcgData;//ecg
NSArray *arrPpgData;//ppg
int heartRate;

NSInteger dataSourceCounterIndex1;//ecg
NSInteger xCoordinateInMoniter1;

NSInteger dataSourceCounterIndex2;//ppg
NSInteger xCoordinateInMoniter2;

NSMutableArray *arrSaveData;

float adc = 0;
int hrCalibration = 70;
int sbpCalibration = 120;
int dbpCalibration = 70;
BOOL isWearOnLeft = NO;

long ecgStartTime = 0;
long ppgStartTime = 0;
NSString *ecgStartTimeMilliseconds;
NSString *ppgStartTimeMilliseconds;

BOOL isLeadOff = NO;
BOOL isPoorConductivity = NO;


int e66Hr = 0;
int e66Hrv = 0;
int e66Sbp = 0;
int e66Dbp = 0;
CBCentralManager *cbCentralManager;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GMSServices provideAPIKey:@"AIzaSyCtprfu6ShvuvpBU2qa3N-zqkeloydHAuE"];
    [FIRApp configure];

    [AnalysisBLEDataManager shareManager].infoDelegate = self;
    [INBluetoothManager shareManager].delegate = self;
    [INBluetoothManager enableSDKLogs:YES]; //open log switch

    [YCBTProduct shared];
    [YCBTProduct setDebugLogEnable:YES];
    cbCentralManager = [CBCentralManager alloc];
    healthKitManager = [GSHealthKitManager sharedManager];
    int tIsEnable = false;

    ///BREAK: Background Watch Data Sync
    [self startTimer];
    [self audioPlayer];
    [self audioNotification];

    ecg_data_proc_init(ECG_BPM_FREQ_250_HZ, IOS_Ecg_Evt_Handle, tIsEnable);

    // BLE status
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bleConnectStateChange:) name:kNtfConnectStateChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(msgGetBlood:) name:kNtfRecvRealBloodData object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(msgGetEcgData:) name:kNtfRecvRealEcgData object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(msgGetHistoryData:) name:kNtfRecvHistroyData object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(msgGetPpgData:) name:kNtfRecvRealPpgData object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(realStepData:) name:kNtfRecvRealStepData object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(revicePPGStauts:) name:kNtfEcgPpgStatusData object:nil];


    [UIApplication.sharedApplication setMinimumBackgroundFetchInterval:60 * 15];
    FlutterViewController *controller = (FlutterViewController *) self.window.rootViewController;
    if (@available
    (iOS
    10.0, *)) {
        [UNUserNotificationCenter currentNotificationCenter].delegate = (id <UNUserNotificationCenterDelegate>) self;
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"Notification"]) {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Notification"];
    }
    hBandDevices = [[NSMutableArray alloc] init];

    // Create NSUserActivity for Siri Shortcuts
    //    if (@available(iOS 12.0, *)) {
    //        NSUserActivity* userActivity = [[NSUserActivity alloc] initWithActivityType:@"com.Meritopia.HealthGauge.StartMeasurement"];
    //        userActivity.title = [NSString stringWithFormat:@"Open %@ Remote", @"Health Gauge"];
    //        userActivity.eligibleForPrediction = YES;
    //        userActivity.eligibleForSearch = YES;
    //        userActivity.userInfo = @{@"ID" : @"Hello"};
    //        userActivity.requiredUserInfoKeys = [NSSet setWithArray:userActivity.userInfo.allKeys];
    //        userActivity.suggestedInvocationPhrase = @"Take Measurement";
    //        self.userActivity = userActivity; // Calls becomeCurrent/resignCurrent for us...
    //        userActivity.becomeCurrent;
    //    }

    // Create NSUserActivity for Siri Shortcuts
//    if (@available(iOS 12.0, *)) {
//        NSMutableArray<INShortcut *> *suggestions = [[NSMutableArray<INShortcut *> alloc] init];
//        NSUserActivity* userActivity = [[NSUserActivity alloc] initWithActivityType:@"com.Meritopia.HealthGauge.StartMeasurement"];
//        userActivity.persistentIdentifier =   @"com.Meritopia.HealthGauge.FindBracelet";
//        userActivity.title = [NSString stringWithFormat: @"Take Measurement"];
//        userActivity.eligibleForPrediction = YES;
//        userActivity.eligibleForSearch = YES;
//        userActivity.userInfo = @{@"ID" : @"Measurement"};
//        userActivity.requiredUserInfoKeys = [NSSet setWithArray:userActivity.userInfo.allKeys];
//        userActivity.suggestedInvocationPhrase = @"Take Measurement";
//        //self.userActivity = userActivity;
//        [suggestions addObject : [[INShortcut alloc] initWithUserActivity:userActivity]];
//
//        NSUserActivity* user2Activity = [[NSUserActivity alloc] initWithActivityType:@"com.Meritopia.HealthGauge.TakeWeightMeasurement"];
//        user2Activity.persistentIdentifier =   @"com.Meritopia.HealthGauge.StopMeasurement";
//        user2Activity.title = [NSString stringWithFormat: @"Take Weight Measurement"];
//        user2Activity.eligibleForPrediction = YES;
//        user2Activity.eligibleForSearch = YES;
//        user2Activity.userInfo = @{@"ID" : @"Welcome"};
//        user2Activity.requiredUserInfoKeys = [NSSet setWithArray:user2Activity.userInfo.allKeys];
//        user2Activity.suggestedInvocationPhrase = @"Take Weight Measurement";
//        //self.userActivity = userActivity;
//        [suggestions addObject : [[INShortcut alloc] initWithUserActivity:user2Activity]];
//
//        NSUserActivity* user5Activity = [[NSUserActivity alloc] initWithActivityType:@"com.Meritopia.HealthGauge.TellHealthGauge"];
//        user5Activity.persistentIdentifier =   @"com.Meritopia.HealthGauge.TellHealthGauge";
//        user5Activity.title = [NSString stringWithFormat: @"TellHealthGauge"];
//        user5Activity.eligibleForPrediction = YES;
//        user5Activity.eligibleForSearch = YES;
//        user5Activity.userInfo = @{@"ID" : @"W"};
//        user5Activity.requiredUserInfoKeys = [NSSet setWithArray:user5Activity.userInfo.allKeys];
//        user5Activity.suggestedInvocationPhrase = @"TellHealthGauge";
//        //self.userActivity = userActivity;
//        [suggestions addObject : [[INShortcut alloc] initWithUserActivity:user5Activity]];
////
////
////
////        NSUserActivity* user3Activity = [[NSUserActivity alloc] initWithActivityType:@"com.Meritopia.HealthGauge.AuthorizeHealthKit"];
////        user3Activity.persistentIdentifier =   @"com.Meritopia.HealthGauge.AuthorizeHealthKit";
////        user3Activity.title = [NSString stringWithFormat: @"Authorize Health Kit"];
////        user3Activity.eligibleForPrediction = YES;
////        user3Activity.eligibleForSearch = YES;
////        user3Activity.userInfo = @{@"ID" : @"Welc"};
////        user3Activity.requiredUserInfoKeys = [NSSet setWithArray:user3Activity.userInfo.allKeys];
////        user3Activity.suggestedInvocationPhrase = @"Authorize Health Kit";
////        //self.userActivity = userActivity;
////        [suggestions addObject : [[INShortcut alloc] initWithUserActivity:user3Activity]];
//
//
//
//        [[INVoiceShortcutCenter sharedCenter] setShortcutSuggestions:suggestions];
//
//
//    }

    channel = [FlutterMethodChannel methodChannelWithName:@"com.helthgauge" binaryMessenger:controller];

    [ZHBlePeripheral sharedUartManager].delegate = self;
    [ZHBlePeripheral sharedUartManager].sportDataSource = self;
    [ZHBlePeripheral sharedUartManager].healthDataSource = self;
    _appUser = [[AppUser alloc] init];
    _appUser.sex = 1;
    _appUser.age = 25;
    _appUser.height = 172;
    _appUser.weightKg = 0.0;

    //if ([INBluetoothManager shareManager].bleState == CBManagerStatePoweredOn) {
    //    [AnalysisBLEDataManager shareManager].infoDelegate = self;
    //    [INBluetoothManager shareManager].delegate = self;
    //    [INBluetoothManager enableSDKLogs:YES]; //open log switch
    //
    //
    //       } else {
    //           NSLog(@"---Error: BLE not avalible, pls check.");
    //       }

    arrSaveData = [@[] mutableCopy];


    [channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {

        if ([@"checkConnectionStatus" isEqualToString:call.method]) {
            [healthKitManager requestAuthorization];
            int sdkType = [[call.arguments objectForKey:@"type"] intValue];
            if (sdkType == 4) {
//                result(@([self hBandConnected]));
            }
            if (sdkType == 2) {
                NSString *dev_id = [[YCBTProduct shared] yc_dev_id];
                if (dev_id != nil && ![dev_id isEqualToString:@""]) {
                    NSLog(@"%@", dev_id);
                    result(@true);
                } else {
                    NSLog(@"Disconnected，Pls to Bind");
                    result(@false);
                }
            } else {
                result(@([self isConnected]));
            }

        } else if ([@"getDeviceList" isEqualToString:call.method]) {

            cbCentralManager = [cbCentralManager initWithDelegate:nil queue:nil options:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:CBCentralManagerOptionShowPowerAlertKey]];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            BOOL isForWeightScale = [call.arguments objectForKey:@"isForWeightScale"];
            deviceList = [[NSMutableArray alloc] init];
            if (sdkType == 4) {
                [[VPBleCentralManage sharedBleManager] veepooSDKStartScanDeviceAndReceiveScanningDevice:^(
                        VPPeripheralModel *peripheralModel) {
                    NSDictionary *scannedDevice = @{
                            @"name": peripheralModel.deviceName,
                            @"address": peripheralModel.deviceAddress,
                            @"rssi": @-63,
                            @"sdkType": @4,
                    };
                     NSLog(@"Value of rssi = %@", scannedDevice);
                    [hBandDevices addObject:peripheralModel];
                    [channel invokeMethod:@"getDeviceList" arguments:scannedDevice];
                }];

            }
            if (sdkType == 2) {
                [[YCBTProduct shared] startScanDevice:^(Error_Code code, NSMutableArray *_Nonnull
                                                        result) {
                    if (code == Error_Ok) {
                        NSLog(@"%@", result);
                        deviceList = result;
                        if (deviceList.count > 0) {

                            for (CBPeripheral *obj in deviceList) {
                                NSDictionary *scannedDevice = @{
                                        @"name": obj.name,
                                        @"address": obj.identifier.UUIDString,
                                        @"rssi": @-63,
                                        @"sdkType": @2,
                                };
                                 NSLog(@"Value of rssi = %@", scannedDevice);
                                [channel invokeMethod:@"getDeviceList" arguments:scannedDevice];
                            }
                        }
                        //   [[YCBTProduct shared] unBindDevice];
                    } else if (code == Error_BLENOTOpen) {
                        //  [Tools showMsg:@"蓝牙未打开!"];
                        NSLog(@"Bye");
                    } else {
                        NSLog(@"Hello");
                    }
                }];
            } else {
                if (isForWeightScale && sdkType == 3) {
                    [[INBluetoothManager shareManager] startBleScan];
                    [AnalysisBLEDataManager shareManager].infoDelegate = self;
                    [INBluetoothManager shareManager].delegate = self;
                    [INBluetoothManager enableSDKLogs:NO]; //open log switch
                }

                if (sdkType == 1) {
                    [[ZHBlePeripheral sharedUartManager] scanDevice];
                }
            }

        } else if ([@"stopScan" isEqualToString:call.method]) {
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 4) {
                [self stopHBandMeasurment:sdkType];
            }
            if (sdkType == 2) {
                [[YCBTProduct shared] stopScan];
            } else {
                [[ZHBlePeripheral sharedUartManager] stopScan];
            }
        } else if ([@"onGetHRData" isEqualToString:call.method]) {

            [self getHrData];
            result([NSNumber numberWithBool:true]);

        } else if ([@"connectToDevice" isEqualToString:call.method]) {
            //connect to device here
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            resultForConnect = result;
            NSLog(@"arguments = %@", [call.arguments objectForKey:@"address"]);
            if (sdkType == 4) {
                [self connectHbandToDevice:[call.arguments objectForKey:@"address"] sdkType:sdkType];
            } else {
                [self connectToDevice:[call.arguments objectForKey:@"address"] sdkType:sdkType];

            }
        } else if ([@"disConnectToDevice" isEqualToString:call.method]) {
            //disconnect to device here
            resultForDisConnect = result;
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 4) {
                [[VPBleCentralManage sharedBleManager] veepooSDKDisconnectDevice];

            }
            if (sdkType == 2) {
                [[YCBTProduct shared] forceDisconnectDevice];
            } else {
                [[ZHBlePeripheral sharedUartManager] didDisconnect];
            }
            if (resultForDisConnect != nil) {
                resultForDisConnect([NSNumber numberWithBool:true]);
                resultForDisConnect = nil;
            }

        } else if ([@"startMeasurement" isEqualToString:call.method]) {
            //start measurement
            NSLog(@"startMeasuarment_before");
            ecgStartTime = 0;
            ppgStartTime = 0;
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];

            if (sdkType == 4) {
                e66Hr = 0;
                e66Hrv = 0;
                e66Sbp = 0;
                e66Dbp = 0;

                [self startHbandMeasurment:sdkType];
                result([NSNumber numberWithBool:true]);
            }
            if (sdkType == 2) {
                e66Hr = 0;
                e66Hrv = 0;
                e66Sbp = 0;
                e66Dbp = 0;
//                [YCBTProduct.shared settingWorkMode:0x00 callback:^(Error_Code code, NSDictionary * _Nonnull
//                result) {
//                if (code == Error_Ok) {
//                NSLog(@"Success"); } else {
//                NSLog(@"Failed"); }
//                }];

                [[YCBTProduct shared] beginECGTest];
                result([NSNumber numberWithBool:true]);
//                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(msgGetBlood:) name:kNtfRecvRealBloodData object:nil];

                NSLog(@"startMeasuarment_after");
            } else {
                NSLog(@"startMeasuarment_11");
                [self startMeasuarment];
            }
        } else if ([@"stopMeasurement" isEqualToString:call.method]) {
            //stop measurement
            int sdkType = [call.arguments intValue];
            if (sdkType == 2) {
                [[YCBTProduct shared] endECGTest:true];
                result([NSNumber numberWithBool:true]);
            } else {
                [self stopMeasurement];
            }
        } else if ([@"vibrate" isEqualToString:call.method]) {
            //stop measurement
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 2) {
                [[YCBTProduct shared] findAntiLost:^(Error_Code code, NSDictionary *_Nonnull
                                                     result) {
                    if (code == Error_Ok) {
                        NSLog(@"Success");
                    } else {
                        NSLog(@"Failed");
                    }
                }];


            } else {
                [[ZHSendCmdTool shareIntance] sendFindBraceletCmd];
            }
        } else if ([@"Calibration" isEqualToString:call.method]) {

            hrCalibration = [[call.arguments objectForKey:@"hr"] intValue];
            sbpCalibration = [[call.arguments objectForKey:@"sbp"] intValue];
            dbpCalibration = [[call.arguments objectForKey:@"dbp"] intValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            __block bool response = false;
            if (sdkType == 2) {

                [YCBTProduct.shared bloodPressureCalibrationSystolicPressure:sbpCalibration diastolicPressure:dbpCalibration callBack:^(
                        Error_Code code, NSDictionary *_Nonnull result) {
                    if (code == Error_Ok) {
                        NSLog(@"Success");
                        response = true;
                    } else {
                        NSLog(@"Failed");
                        response = false;
                    }
                }];
//                [YCBTProduct.shared getDeviceWorkMode:^(Error_Code code, NSDictionary * _Nonnull result) {
//                if (code == Error_Ok) {
//                NSInteger mode = [result[@"mode"] integerValue];
//                NSLog(@"mode: %@", @(mode)); }
//                }];
            } else {
                [[ZHSendCmdTool shareIntance] sendHeartDataCmd:hrCalibration andSystolic:sbpCalibration andDiastolic:dbpCalibration];
            }
        } else if ([@"setWearType" isEqualToString:call.method]) {
            NSLog(@"%@", call.arguments);
            isWearOnLeft = [[call.arguments objectForKey:@"enable"] boolValue];
//            if(call.arguments == [NSNumber numberWithBool:YES]){
//                isWearOnLeft = YES;
//            }else{
//                isWearOnLeft = NO;
//            }
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 2) {
                [[YCBTProduct shared] settingLeftRightHandWear:isWearOnLeft callback:^(
                        Error_Code code, NSDictionary *_Nonnull result) {
                    if (code == Error_Ok) {
                        NSLog(@"Success");
                    } else {
                        NSLog(@"Failed");
                    }
                }];
            }

        } else if ([@"setLiftBrighten" isEqualToString:call.method]) {
            BOOL isLiftBrighten = [[call.arguments objectForKey:@"isLiftTheWristBrightnessOn"] boolValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 2) {
                [[YCBTProduct shared] settingRaiseScreen:isLiftBrighten callback:^(Error_Code code,
                                                                                   NSDictionary *_Nonnull
                                                                                   result) {
                    if (code == Error_Ok) {
                        NSLog(@"Success");
                    } else {
                        NSLog(@"Failed");
                    }
                }];
            } else {
                [[ZHSendCmdTool shareIntance] setRemindForType:FunctionBrightScreenType withSwitch:isLiftBrighten];
            }

        } else if ([@"setDoNotDisturb" isEqualToString:call.method]) {
            BOOL isDoNotDisturb = [[call.arguments objectForKey:@"enable"] boolValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 2) {
                [[YCBTProduct shared] settingNoDisturb:isDoNotDisturb
                                             startHour:0 startMin:00 endHour:23 endMin:59
                                              callback:^(Error_Code code, NSDictionary *
                                              _Nonnull result) {
                                                  if (code == Error_Ok) {
                                                      NSLog(@"Success");
                                                  } else {
                                                      NSLog(@"Failed");
                                                  }
                                              }];
            } else {
                [[ZHSendCmdTool shareIntance] setRemindForType:FunctionNotDisturbType withSwitch:isDoNotDisturb];
            }


        } else if ([@"setTimeFormat" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 2) {
                [[YCBTProduct shared] settingUnit:0x00
                                           weight:0x00
                                             temp:0x00
                                       time24Or12:isEnable ? 0x00 : 0x01
                                         callback:^(Error_Code code, NSDictionary *_Nonnull
                                                    result) {
                                             if (code == Error_Ok) {
                                                 NSLog(@"Success");
                                             } else {
                                                 NSLog(@"Failed");
                                             }
                                         }];
            } else {
                [[ZHSendCmdTool shareIntance] setRemindForType:FunctionTimeType withSwitch:isEnable];
            }
        } else if ([@"setUnits" isEqualToString:call.method]) {
            int weightUnit = [[call.arguments objectForKey:@"weightUnit"] intValue];
            int tempUnit = [[call.arguments objectForKey:@"tempUnit"] intValue];
            int distanceUnit = [[call.arguments objectForKey:@"distanceUnit"] intValue];
            int timeUnit = [[call.arguments objectForKey:@"timeUnit"] intValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 2) {
                [[YCBTProduct shared] settingUnit:distanceUnit == 0 ? 0x00 : 0x01
                                           weight:weightUnit == 0 ? 0x00 : 0x01
                                             temp:tempUnit == 0 ? 0x00 : 0x01
                                       time24Or12:timeUnit == 0 ? 0x01 : 0x00
                                         callback:^(Error_Code code, NSDictionary *_Nonnull
                                                    result) {
                                             if (code == Error_Ok) {
                                                 NSLog(@"Success");
                                             } else {
                                                 NSLog(@"Failed");
                                             }
                                         }];
            } else {
                [[ZHSendCmdTool shareIntance] setRemindForType:FunctionTimeType withSwitch:
                        timeUnit == 1];
            }
        } else if ([@"setHourlyHrMonitorOn" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            int timeInterval = [[call.arguments objectForKey:@"timeInterval"] intValue];

            if (sdkType == 2) {
                NSInteger mode = isEnable ? 0x01 : 0x00;
                [[YCBTProduct shared] settingHeartMode:mode
                                         autoHeartTime:timeInterval
                                              callback:^(Error_Code code, NSDictionary *
                                              _Nonnull result) {
                                                  if (code == Error_Ok) {
                                                      NSLog(@"Success");
                                                  } else {
                                                      NSLog(@"Failed");
                                                  }
                                              }];
            } else {
                [[ZHSendCmdTool shareIntance] setRemindForType:FunctionMonitorType withSwitch:isEnable];
            }
        } else if ([@"setUserData" isEqualToString:call.method]) {
            //unit will be came from profile
            NSInteger height = [[call.arguments objectForKey:@"Height"] integerValue];
            NSInteger weight = [[call.arguments objectForKey:@"Weight"] integerValue];
            NSInteger age = [[call.arguments objectForKey:@"Age"] integerValue];
            BOOL isMale = [[call.arguments objectForKey:@"Gender"] boolValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 2) {
                [[YCBTProduct shared] settingUserInfo:height
                                               weight:weight
                                                  sex:isMale ? 0 : 1
                                                  age:age
                                             callback:^(Error_Code code, NSDictionary *_Nonnull
                                                        result) {
                                                 if (code == Error_Ok) {
                                                     NSLog(@"Success");
                                                 } else {
                                                     NSLog(@"Failed");
                                                 }
                                             }];
            } else {

                NSString *strHeight = [NSString stringWithFormat:@"%ld", (long) height];
                NSString *strWeight = [NSString stringWithFormat:@"%ld", (long) weight];
                NSString *strAge = [NSString stringWithFormat:@"%ld", (long) age];
                NSString *strGender = [NSString stringWithFormat:@"%@", [call.arguments objectForKey:@"Gender"]];
                [[ZHSendCmdTool shareIntance] synPersonalInformationForAge:strAge andSex:strGender andHeight:strHeight andWeight:strWeight];
            }

        } else if ([@"setWaterReminder" isEqualToString:call.method]) {


            int startHour = [[call.arguments objectForKey:@"startHour"] intValue];
            int startMinute = [[call.arguments objectForKey:@"startMinute"] intValue];
            int endHour = [[call.arguments objectForKey:@"endHour"] intValue];
            int endMinute = [[call.arguments objectForKey:@"endMinute"] intValue];
            int interval = [[call.arguments objectForKey:@"interval"] intValue];
            BOOL isEnable = [[call.arguments objectForKey:@"isEnable"] boolValue];

            NSString *strStart = [NSString stringWithFormat:@"%02d:%02d", startHour, startMinute];
            NSString *strEnd = [NSString stringWithFormat:@"%02d:%02d", endHour, endMinute];

            [[ZHSendCmdTool shareIntance] setRemindTimeForType:FunctionDrinkType withStartTime:strStart EndTime:strEnd Interval:interval andSwitch:isEnable];

            [[YCBTProduct shared] setttingAlarm:0x07 startHour:startHour startMin:startMinute alarmRepeat:0xff delayTime:15 callback:^(
                    Error_Code code, NSDictionary *_Nonnull result) {
                if (Error_Ok == code) { /*
            @{
            device alarms exceeded (n-1)
            }];
            @"keyOptType": operation type, set alarm @"keySettingCode": operation result code 0x00: set successfully 0x01: setting failed -
            clock by 0x01
            maximum number of
            } */
                }
            }];
            result(@(true));

        } else if ([@"setMedicalReminder" isEqualToString:call.method]) {


            int startHour = [[call.arguments objectForKey:@"startHour"] intValue];
            int startMinute = [[call.arguments objectForKey:@"startMinute"] intValue];
            int endHour = [[call.arguments objectForKey:@"endHour"] intValue];
            int endMinute = [[call.arguments objectForKey:@"endMinute"] intValue];
            int interval = [[call.arguments objectForKey:@"interval"] intValue];
            BOOL isEnable = [[call.arguments objectForKey:@"isEnable"] boolValue];

            NSString *strStart = [NSString stringWithFormat:@"%02d:%02d", startHour, startMinute];
            NSString *strEnd = [NSString stringWithFormat:@"%02d:%02d", endHour, endMinute];

            [[ZHSendCmdTool shareIntance] setRemindTimeForType:FunctionMedicineType withStartTime:strStart EndTime:strEnd Interval:interval andSwitch:isEnable];

            [[YCBTProduct shared] setttingAlarm:0x03 startHour:startHour startMin:startMinute alarmRepeat:0xff delayTime:15 callback:^(
                    Error_Code code, NSDictionary *_Nonnull result) {
                if (Error_Ok == code) { /*
            @{
            device alarms exceeded (n-1)
            }];
            @"keyOptType": operation type, set alarm @"keySettingCode": operation result code 0x00: set successfully 0x01: setting failed -
            clock by 0x01
            maximum number of
            } */
                }
            }];
            result(@(true));

        } else if ([@"setSitReminder" isEqualToString:call.method]) {

            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            NSInteger startHour = [[call.arguments objectForKey:@"startHour"] intValue];
            NSInteger startMinute = [[call.arguments objectForKey:@"startMinute"] intValue];
            NSInteger endHour = [[call.arguments objectForKey:@"endHour"] intValue];
            NSInteger endMinute = [[call.arguments objectForKey:@"endMinute"] intValue];
            NSInteger interval = [[call.arguments objectForKey:@"interval"] intValue];
            BOOL isEnable = [[call.arguments objectForKey:@"isEnable"] boolValue];

            NSString *strStart = [NSString stringWithFormat:@"%02ld:%02ld", (long) startHour, (long) startMinute];
            NSString *strEnd = [NSString stringWithFormat:@"%02ld:%02ld", (long) endHour, (long) endMinute];
            if (sdkType == 1) {

                [[ZHSendCmdTool shareIntance] setRemindTimeForType:FunctionSedentaryType withStartTime:strStart EndTime:strEnd Interval:interval andSwitch:isEnable];
            } else if (sdkType == 2) {
                NSInteger secondStartHour = [[call.arguments objectForKey:@"secondStartHour"] intValue];
                NSInteger secondStartMinute = [[call.arguments objectForKey:@"secondStartMinute"] intValue];
                NSInteger secondEndHour = [[call.arguments objectForKey:@"secondEndHour"] intValue];
                NSInteger secondEndMinute = [[call.arguments objectForKey:@"secondEndMinute"] intValue];

                [[YCBTProduct shared] settingLongsite:startHour
                                             startMin:startMinute
                                              endHour:endHour
                                               endMin:endMinute
                                           startHour2:secondStartHour
                                            startMin2:secondStartMinute
                                             endHour2:secondEndHour
                                              endMin2:secondEndMinute
                                             interval:interval
                                               repeat:isEnable ? 0xFF : 0
                                             callback:^(Error_Code code, NSDictionary *_Nonnull
                                                        result) {
                                                 if (code == Error_Ok) {
                                                     NSLog(@"Success");
                                                 } else {
                                                     NSLog(@"Failed");
                                                 }
                                             }];
            }

            result(@(true));

        } else if ([@"setStepTarget" isEqualToString:call.method]) {
            int steps = [[call.arguments objectForKey:@"target"] intValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 2) {
                [[YCBTProduct shared] settingGoalStep:steps callback:^(Error_Code code,
                                                                       NSDictionary *_Nonnull
                                                                       result) {
                    if (code == Error_Ok) {
                        NSLog(@"Success");
                    } else {
                        NSLog(@"Failed");
                    }
                }];
            } else {
                [[ZHSendCmdTool shareIntance] sendSportTarget:steps];
            }
            result(@(steps));
        } else if ([@"setCaloriesTarget" isEqualToString:call.method]) {
            int calories = [[call.arguments objectForKey:@"caloriesValue"] intValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 2) {
                [[YCBTProduct shared] settingCalorie:calories callback:^(Error_Code code,
                                                                         NSDictionary *_Nonnull
                                                                         result) {
                    if (code == Error_Ok) {
                        NSLog(@"Success");
                    } else {
                        NSLog(@"Failed");
                    }
                }];
            }
            result(@(true));
        } else if ([@"setDistanceTarget" isEqualToString:call.method]) {
            int distance = [[call.arguments objectForKey:@"target"] intValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 2) {
                [[YCBTProduct shared] settingDistance:distance callback:^(Error_Code code,
                                                                          NSDictionary *_Nonnull
                                                                          result) {
                    if (code == Error_Ok) {
                        NSLog(@"Success");
                    } else {
                        NSLog(@"Failed");
                    }
                }];
            }
            result(@(true));
        } else if ([@"setSleepTarget" isEqualToString:call.method]) {
            int hour = [[call.arguments objectForKey:@"hour"] intValue];
            int minute = [[call.arguments objectForKey:@"minute"] intValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 2) {
                [[YCBTProduct shared] settingGoalSleep:hour sleepMin:minute
                                              callback:^(Error_Code code, NSDictionary *
                                              _Nonnull result) {
                                                  if (code == Error_Ok) {
                                                      NSLog(@"Success");
                                                  } else {
                                                      NSLog(@"Failed");
                                                  }
                                              }];

            }
            result(@(true));
        } else if ([@"setSkinType" isEqualToString:call.method]) {
            int skinType = [[call.arguments objectForKey:@"skinType"] intValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            if (sdkType == 2) {
                [[YCBTProduct shared] settingSkinColor:skinType callback:^(Error_Code code,
                                                                           NSDictionary *_Nonnull
                                                                           result) {
                    if (code == Error_Ok) {
                        NSLog(@"Success");
                    } else {
                        NSLog(@"Failed");
                    }
                }];
            }
        } else if ([@"addSDKAlarm" isEqualToString:call.method]) {
            //        int intId =[[call.arguments objectForKey:@"id"] intValue];
            //        int startHour =[[call.arguments objectForKey:@"startHour"] intValue];
            //        int startMinute =[[call.arguments objectForKey:@"startMinute"] intValue];
            //        int endHour =[[call.arguments objectForKey:@"endHour"] intValue];
            //        int endMinute =[[call.arguments objectForKey:@"endMinute"] intValue];
            //        int interval =[[call.arguments objectForKey:@"interval"] intValue];
            //        NSArray* day = [[call.arguments objectForKey:@"days"]array];

            int intId = [[call.arguments objectForKey:@"id"] intValue];
            int alarmHour = [[call.arguments objectForKey:@"alarmHour"] intValue];
            int alarmMinute = [[call.arguments objectForKey:@"alarmMin"] intValue];
            BOOL repeat = [[call.arguments objectForKey:@"repeat"] boolValue];
            int slider = [[call.arguments objectForKey:@"slider"] intValue];
            NSArray *day = [call.arguments objectForKey:@"days"];

            NSString *alarmTime = [NSString stringWithFormat:@"%02d:%02d", alarmHour, alarmMinute];

            ZHAlarmClockModel *model = [[ZHAlarmClockModel alloc] init];
            model.time = alarmTime;
            model.alarmID = intId;
            model.dayflags = day;
            model.slider = slider;
            model.repeat = repeat;
            [[ZHSendCmdTool shareIntance] setAlarmClockForModel:@[model]];

            result(@(true));
        } else if ([@"addE80SDKAlarm" isEqualToString:call.method]) {


            NSInteger alarmType = [[call.arguments objectForKey:@"type"] intValue];
            NSInteger alarmHour = [[call.arguments objectForKey:@"startHour"] intValue];
            NSInteger alarmMinute = [[call.arguments objectForKey:@"startMinute"] intValue];
            NSInteger repeat = [[call.arguments objectForKey:@"repeat"] intValue];
            NSInteger delay = [[call.arguments objectForKey:@"delay"] intValue];
            [[YCBTProduct shared] setttingAlarm:alarmType startHour:alarmHour startMin:alarmMinute alarmRepeat:repeat delayTime:delay callback:^(
                    Error_Code code, NSDictionary *_Nonnull result) {
                if (Error_Ok == code) { /*
            @{
            device alarms exceeded (n-1)
            }];
            @"keyOptType": operation type, set alarm @"keySettingCode": operation result code 0x00: set successfully 0x01: setting failed -
            clock by 0x01
            maximum number of
            } */
                }
            }];
            result(@(true));
        } else if ([@"modifyE80SDKAlarm" isEqualToString:call.method]) {

            NSInteger oldHour = [[call.arguments objectForKey:@"oldHour"] intValue];
            NSInteger oldMinute = [[call.arguments objectForKey:@"oldMinute"] intValue];
            NSInteger alarmType = [[call.arguments objectForKey:@"type"] intValue];
            NSInteger alarmHour = [[call.arguments objectForKey:@"startHour"] intValue];
            NSInteger alarmMinute = [[call.arguments objectForKey:@"startMinute"] intValue];
            NSInteger repeat = [[call.arguments objectForKey:@"repeat"] intValue];
            NSInteger delay = [[call.arguments objectForKey:@"delay"] intValue];

            [[YCBTProduct shared] modifyAlarm:oldHour
                                       oldMin:oldMinute
                                    alarmType:alarmType
                                    startHour:alarmHour
                                     startMin:alarmMinute
                                  alarmRepeat:repeat
                                    delayTime:delay
                                     callback:^(Error_Code code, NSDictionary *_Nonnull
                                                result) {
                                         if (code == Error_Ok) {
                                         }
                                     }];
            result(@(true));
        } else if ([@"deleteE80SDKAlarm" isEqualToString:call.method]) {

            NSInteger alarmHour = [[call.arguments objectForKey:@"startHour"] intValue];
            NSInteger alarmMinute = [[call.arguments objectForKey:@"startMinute"] intValue];

            [[YCBTProduct shared] deleteAlarm:alarmHour
                                     startMin:alarmMinute
                                     callback:^(Error_Code code, NSDictionary *_Nonnull
                                                result) {
                                         if (Error_Ok == code) {
                                         }
                                     }];
            result(@(true));
        } else if ([@"setCallEnable" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            [[ZHSendCmdTool shareIntance] setRemindForType:FunctionPhoneType withSwitch:isEnable];
            result(@(true));
        } else if ([@"setMessageEnable" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            [[ZHSendCmdTool shareIntance] setRemindForType:FunctionSMSType withSwitch:isEnable];
            result(@(true));
        } else if ([@"setQqEnable" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            [[ZHSendCmdTool shareIntance] setRemindForType:FunctionQQType withSwitch:isEnable];
            result(@(true));
        } else if ([@"setWeChatEnable" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            [[ZHSendCmdTool shareIntance] setRemindForType:FunctionWeChatType withSwitch:isEnable];
            result(@(true));
        } else if ([@"setLinkedInEnable" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            [[ZHSendCmdTool shareIntance] setRemindForType:FunctionLinkedInType withSwitch:isEnable];
            result(@(true));
        } else if ([@"setSkypeEnable" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            [[ZHSendCmdTool shareIntance] setRemindForType:FunctionSkypeType withSwitch:isEnable];
            result(@(true));
        } else if ([@"setFacebookMessengerEnable" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            [[ZHSendCmdTool shareIntance] setRemindForType:FunctionFacebookType withSwitch:isEnable];
            result(@(true));
        } else if ([@"setTwitterEnable" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            [[ZHSendCmdTool shareIntance] setRemindForType:FunctionTwitterType withSwitch:isEnable];
            result(@(true));
        } else if ([@"setWhatsAppEnable" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            [[ZHSendCmdTool shareIntance] setRemindForType:FunctionWhatsAppType withSwitch:isEnable];
            result(@(true));
        } else if ([@"setViberEnable" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            [[ZHSendCmdTool shareIntance] setRemindForType:FunctionViberType withSwitch:isEnable];
            result(@(true));
        } else if ([@"setLineEnable" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            [[ZHSendCmdTool shareIntance] setRemindForType:FunctionLineType withSwitch:isEnable];
            result(@(true));
        } else if ([@"requestHealthKitAuthorization" isEqualToString:call.method]) {
            [healthKitManager requestAuthorization];
            result(@(true));
        } else if ([@"readRestingCaloriesData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];

            [healthKitManager readBasalCalories:startDate endDate:endDate finishBlock:^(NSError *error,
                                                                                    NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    //  [channel invokeMethod:@"getStepDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"readActiveCaloriesData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];

            [healthKitManager readActiveCalories:startDate endDate:endDate finishBlock:^(NSError *error,
                                                                                    NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    //  [channel invokeMethod:@"getStepDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"readStepsData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];

            [healthKitManager readStepsData:startDate endDate:endDate finishBlock:^(NSError *error,
                                                                                    NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    //  [channel invokeMethod:@"getStepDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"readDistanceData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];
    
            [healthKitManager saveDistance:1.5 startDate:[NSDate date] endDate:[NSDate date] withFinishBlock:^(
                    NSError *error) {
                if (error) {
                    NSLog(@"error : %@", error);
                }
            }];

            [healthKitManager readWalkingAndRunningDistanceData:startDate endDate:endDate finishBlock:^(
                    NSError *error, NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    //[channel invokeMethod:@"getDistanceDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"readSleepData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];

            [healthKitManager readSleepData:startDate endDate:endDate finishBlock:^(NSError *error,
                                                                                    NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    // [channel invokeMethod:@"getSleepDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"readHeightData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];

            [healthKitManager readHeightData:startDate endDate:endDate finishBlock:^(NSError *error,
                                                                                     NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    //  [channel invokeMethod:@"getHeightDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"readBodyMassData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];

            [healthKitManager readBodyMass:startDate endDate:endDate finishBlock:^(NSError *error,
                                                                                   NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    // [channel invokeMethod:@"getBodyMassDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"readHeartRateData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];

            [healthKitManager readHeartRateData:startDate endDate:endDate finishBlock:^(
                    NSError *error, NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    //  [channel invokeMethod:@"getHeartRateDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"readEcgData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];

            [healthKitManager readECGData:startDate endDate:endDate finishBlock:^(NSError *error,
                                                                                  NSDictionary *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    //  [channel invokeMethod:@"getHeartRateDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"readSystolicBloodPressureData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];

            [healthKitManager readSystolicBloodPressure:startDate endDate:endDate finishBlock:^(
                    NSError *error, NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    // [channel invokeMethod:@"getSystolicBloodPressureDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"readDiastolicBloodPressureData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];

            [healthKitManager readDiastolicBloodPressure:startDate endDate:endDate finishBlock:^(
                    NSError *error, NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    // [channel invokeMethod:@"getDiastolicBloodPressureDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"readHRVData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];

            [healthKitManager readHeartRateVariabilityData:startDate endDate:endDate finishBlock:^(
                    NSError *error, NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    NSLog(@"value readHRVDatareadHRVDatareadHRVDatareadHRVData : %@", value);
                    //[channel invokeMethod:@"getHRVDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];

        } else if ([@"readBloodGlucoseData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];
            NSLog(@"startDate : %@", startDate);
            NSLog(@"endDate : %@", endDate);

            [healthKitManager readBloodGlucoseData:startDate endDate:endDate finishBlock:^(
                    NSError *error, NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    NSLog(@"value readBloodGlucoseDatareadBloodGlucoseDatareadBloodGlucoseDatareadBloodGlucoseData: %@", value);
                    //[channel invokeMethod:@"getHRVDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"readOxygenData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];
            [healthKitManager readOxygenData:startDate endDate:endDate finishBlock:^(NSError *error,
                                                                                     NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    //[channel invokeMethod:@"getHRVDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"readBodyTemperatureData" isEqualToString:call.method]) {
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];
            [healthKitManager readTemperatureData:startDate endDate:endDate finishBlock:^(
                    NSError *error, NSMutableArray *value) {
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                } else {
                    // value
                    NSLog(@"value: %@", value);
                    //[channel invokeMethod:@"getHRVDataFromHealthKit" arguments:value];
                    result(value);
                }
            }];
        } else if ([@"writeStepsData" isEqualToString:call.method]) {
            NSInteger steps = [[call.arguments objectForKey:@"steps"] intValue];
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            [healthKitManager writeSteps:steps startDate:[healthKitManager dateWithTimeFromString:startDate] endDate:[healthKitManager dateWithTimeFromString:startDate] withFinishBlock:^(
                    NSError *error) {
                // result block
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                }
            }];
            result(@(true));
        } else if ([@"writeBloodPressureData" isEqualToString:call.method]) {
            NSInteger sbp = [[call.arguments objectForKey:@"sbp"] intValue];
            NSInteger dbp = [[call.arguments objectForKey:@"dbp"] intValue];
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            // NSDate *now = [NSDate date];
            [healthKitManager saveBloodPressureIntoHealthStore:sbp Dysbp:dbp startDate:[healthKitManager dateWithTimeFromString:startDate] endDate:[healthKitManager dateWithTimeFromString:startDate] withFinishBlock:^(
                    NSError *error) {
                // result block
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                }
            }];
            result(@(true));
        } else if ([@"writeHeartRateData" isEqualToString:call.method]) {
            NSInteger heartRate = [[call.arguments objectForKey:@"heartRate"] intValue];
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            [healthKitManager writeHeartRateData:heartRate startDate:[healthKitManager dateWithTimeFromString:startDate] endDate:[healthKitManager dateWithTimeFromString:startDate] withFinishBlock:^(
                    NSError *error) {
                // result block
                if (error) {
                    // handle error
                    NSLog(@"error : %@", error);
                }
            }];
            result(@(true));
        } else if ([@"writeDistanceData" isEqualToString:call.method]) {
            double distance = [[call.arguments objectForKey:@"distance"] doubleValue];
            NSString *startDate = [call.arguments objectForKey:@"startDate"];

            [healthKitManager saveDistance:distance startDate:[healthKitManager dateWithTimeFromString:startDate] endDate:[healthKitManager dateWithTimeFromString:startDate] withFinishBlock:^(
                    NSError *error) {
                if (error) {
                    NSLog(@"error : %@", error);
                }
            }];
            result(@(true));
        } else if ([@"writeWeightData" isEqualToString:call.method]) {
            double weight = [[call.arguments objectForKey:@"weight"] doubleValue];
            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            [healthKitManager dateWithTimeFromString:startDate];
            [healthKitManager writeWeightSample:weight startDate:[healthKitManager dateWithTimeFromString:startDate] endDate:[healthKitManager dateWithTimeFromString:startDate]];
            result(@(true));
        } else if ([@"writeSleepData" isEqualToString:call.method]) {


            NSString *startDate = [call.arguments objectForKey:@"startDate"];
            NSString *endDate = [call.arguments objectForKey:@"endDate"];
            NSString *sleepType = [call.arguments objectForKey:@"sleepType"];
            [healthKitManager saveSleepAnalysis:sleepType startDate:[healthKitManager dateWithTimeFromString:startDate] endDate:[healthKitManager dateWithTimeFromString:endDate] withFinishBlock:^(
                    NSError *error) {
                if (error) {
                    NSLog(@"error : %@", error);
                }
            }];

            result(@(true));
        } else if ([@"isHealthDataAvailable" isEqualToString:call.method]) {
            BOOL value = ([healthKitManager isHealthDataAvailable]);
            result(@(value));
        }

            /*Weight Devices Method*/
        else if ([@"startScanWeightScaleDevices" isEqualToString:call.method]) {
            [[INBluetoothManager shareManager] startBleScan];
        } else if ([@"stopScanWeightScaleDevices" isEqualToString:call.method]) {
            [[INBluetoothManager shareManager] stopBleScan];
        } else if ([@"connectWeightScaleDevice" isEqualToString:call.method]) {
            DeviceModel *device;
            if (device.acNumber.intValue < 2) { //0、1 is broadcast scale
                [[INBluetoothManager shareManager] handleDataForBroadScale:device];
            } else { //2、3 is Link scale
                [[INBluetoothManager shareManager] connectToLinkScale:device];
            }
            [[INBluetoothManager shareManager] stopBleScan];
        } else if ([@"disconnectWeightScaleDevice" isEqualToString:call.method]) {
            [[INBluetoothManager shareManager] closeBleAndDisconnect];
        } else if ([@"setWeightScaleUser" isEqualToString:call.method]) {
            // appUser.id = [[call.arguments objectForKey:@"id"] intValue];
            int height = [[call.arguments objectForKey:@"height"] intValue];
            int age = [[call.arguments objectForKey:@"age"] intValue];
            int sex = [[call.arguments objectForKey:@"sex"] intValue];
            self->_appUser.height = height;
            self->_appUser.age = age;
            self->_appUser.sex = sex;
            [self syncWeighingUserToBle];

        } else if ([@"changeWeightScaleUnit" isEqualToString:call.method]) {
            self.unit = [call.arguments intValue];
            [self ChangeUnit:self.unit];
            // [[WriteToBLEManager shareManager] write_To_Unit: self.unit-1];
        } else if ([@"getDataForE66" isEqualToString:call.method]) {
            [[YCBTProduct shared] getDevInfo:^(Error_Code code, NSDictionary *_Nonnull result) {
                if (result) {
                    NSInteger keyDevVersionNum = [result[@"keyDevVersionNum"]
                            intValue];
                    NSInteger tPower = [result[@"keyDevBatteryNum"] integerValue];
                    NSDictionary *deviceInfo = @{
                            @"power": [NSNumber numberWithInteger:tPower],
                            @"device_number": [NSNumber numberWithInteger:keyDevVersionNum],
                    };
                    [channel invokeMethod:@"onResponseDeviceInfo" arguments:deviceInfo];
                }
            }];

            [YCBTProduct.shared syncDataHistory:0x04
                                       callback:^(Error_Code code, NSDictionary *_Nonnull result) {
                                           NSLog(@"%@", result);

                                       }];

            [YCBTProduct.shared syncDataHistory:0x02
                                       callback:^(Error_Code code, NSDictionary *_Nonnull result) {
                                           NSLog(@"%@", result);

                                       }];

            [[YCBTProduct shared] settingRealDataOpen:YES callback:^(Error_Code code,
                                                                     NSDictionary *_Nonnull
                                                                     result) {
                if (code == Error_Ok) {
                    NSLog(@"Success");
                }
            }];


            [YCBTProduct.shared syncDataHistory:0x09
                                       callback:^(Error_Code code, NSDictionary *_Nonnull result) {
                                           NSLog(@"%@", result);

                                       }];


            [YCBTProduct.shared syncDataHistory:0x06
                                       callback:^(Error_Code code, NSDictionary *_Nonnull result) {
                                           NSLog(@"%@", result);

                                       }];

            [YCBTProduct.shared syncDataHistory:0x08
                                       callback:^(Error_Code code, NSDictionary *_Nonnull result) {
                                           NSLog(@"%@", result);

                                       }];


            [YCBTProduct.shared syncDataHistory:0x2B
                                       callback:^(Error_Code code, NSDictionary *_Nonnull result) {
                                           NSLog(@"%@", result);

                                       }];

            [YCBTProduct.shared syncDataHistory:0x1A
                                       callback:^(Error_Code code, NSDictionary *_Nonnull result) {
                                           NSLog(@"%@", result);


                                       }];

            [YCBTProduct.shared syncDataHistory:0x1C
                                       callback:^(Error_Code code, NSDictionary *_Nonnull result) {
                                           NSLog(@"%@", result);


                                       }];


            result(@(true));
        } else if ([@"setBrightness" isEqualToString:call.method]) {
            NSInteger brightness = [[call.arguments objectForKey:@"brightness"] intValue];
            switch (brightness) {
                case 0:
                    brightness = 0x00;
                    break;

                case 1:
                    brightness = 0x01;
                    break;

                case 2:
                    brightness = 0x02;
                    break;

                default:
                    brightness = 0x03;
                    break;
            }


            [[YCBTProduct shared] settingDisplayBright:brightness callback:^(Error_Code code,
                                                                             NSDictionary *_Nonnull
                                                                             result) {
                if (code == Error_Ok) {
                    NSLog(@"Success");
                } else {
                    NSLog(@"Failed");
                }
            }];
            result(@(true));
        } else if ([@"setAppReminderForE66" isEqualToString:call.method]) {
            NSInteger arg1 = [[call.arguments objectForKey:@"arg1"] intValue];
            NSInteger arg2 = [[call.arguments objectForKey:@"arg2"] intValue];
            [[YCBTProduct shared] settingPushSwitch:YES appArg1:arg1 appArg2:arg2 callback:^(
                    Error_Code code, NSDictionary *_Nonnull result) {
                if (code == Error_Ok) {
                    NSLog(@"Success");
                } else {
                    NSLog(@"Failed");
                }
            }];
        } else if ([@"getAlarmListOfE80" isEqualToString:call.method]) {
            FlutterResult value = result;
            __block NSDictionary *alarmData = nil;
            [[YCBTProduct shared] getAlarmSetting:^(Error_Code code, NSDictionary *_Nonnull
                                                    result) {
                if (result) {
                    alarmData = (NSDictionary *) result;
                    value(alarmData);
                    NSInteger clockCount = [result[@"keyAlarmNum"] integerValue];
                }
            }];
//            if(alarmData != nil){
//                result(alarmData);
//            }
        } else if ([@"getCurrentHR" isEqualToString:call.method]) {
            __block int hr = 0;
            [YCBTProduct.shared getCurrentHeartRate:^(Error_Code code, NSDictionary *_Nonnull
                                                      result) {
                if (Error_Ok == code) {
                    NSInteger status = [result[@"keyCurrentHeartRateStatus"] integerValue];
                    hr = [result[@"keyCurrentHeartRateData"] intValue];
                    NSLog(@"status : %@, data: %@", @(status), @(hr));
                }
            }];
            result(@(hr));
        } else if ([@"getAllWatchdata" isEqualToString:call.method]) {
            __block int hr = 0;
            NSLog(@"Requesting from :: iOS native call getAllWatchdata");
            [YCBTProduct.shared syncDataHistory:0x09 callback:^(Error_Code code,
                                                                NSDictionary *_Nonnull result) {
                NSLog(@"Requesting from :: iOS native call 0x09");
                NSMutableArray *monitoredDataArray = [[NSMutableArray alloc] init];
                NSLog(@"Sync OS Data : %@", result);
                for (NSDictionary *data in result) {
                    // NSDictionary *data = historyDatas.lastObject;
                    NSDictionary *dataDic = @{
                            @"HRV": data[@"keyHRV"],
                            @"tempInt": data[@"keyTmepInt"],
                            @"tempDouble": data[@"keyTmepFloat"],
                            @"date": [self converTimstamp:[data[@"keyStartTime"] longValue] format:@"yyyy-MM-dd HH:mm:ss"],
                            @"cvrrValue": data[@"keyCVRR"],
                            @"oxygen": data[@"keyOO"],
                            @"stepValue": data[@"keyStep"],
                            @"heartValue": data[@"keyHeatRate"],
                            @"respiratoryRateValue": data[@"keyRespiratoryRate"],
                            @"SBPValue": data[@"keySBP"],
                            @"DBPValue": data[@"keyDBP"],
                    };
                    [monitoredDataArray addObject:dataDic];
                }
                NSLog(@"Requesting from :: onGetTempData %@", monitoredDataArray);
                [channel invokeMethod:@"onGetTempData" arguments:monitoredDataArray];

            }];
            [YCBTProduct.shared syncDataHistory:0x08 callback:^(Error_Code code,
                                                                NSDictionary *_Nonnull result) {
                NSMutableArray *monitoredDataArray = [[NSMutableArray alloc] init];
                NSLog(@"Requesting from :: iOS native call 0x08");
                for (NSDictionary *data in result) {
                    // NSDictionary *data = historyDatas.lastObject;
                    NSDictionary *dataDic = @{
                            @"bloodSBP": data[@"keySBP"],
                            @"bloodDBP": data[@"keyDBP"],
                            @"bloodStartTime": [self converTimstamp:[data[@"keyStartTime"] longValue] format:@"yyyy-MM-dd HH:mm:ss"]
                    };
                    [monitoredDataArray addObject:dataDic];
                }
                NSLog(@"Requesting from :: onResponseCollectBP %@", monitoredDataArray);
                [channel invokeMethod:@"onResponseCollectBP" arguments:monitoredDataArray];
            }];

            NSLog(@"Requesting from :: iOS native call syncDataHistory 0x06");
            [YCBTProduct.shared syncDataHistory:0x06 callback:^(Error_Code code,
                                                                NSDictionary *_Nonnull result) {
                NSMutableArray *hrArray = [[NSMutableArray alloc] init];
                NSLog(@"Requesting from :: iOS native call syncDataHistory %@:",result);
                for (NSDictionary *data in result) {
                    for (id key in data) {
                        NSLog(@"syncDataHistory data key: %@, value: %@ \n", key, [data objectForKey:key]);
                    }
                    NSLog( @"syncDataHistory data %@", data);
                    NSDictionary *dataDic = @{
                            @"heartValue": data[@"keyHeartNum"],
                            // @"heartStartTime" : [NSNumber numberWithLong: timestamp],
                            @"heartStartTime": [self converTimstamp:[data[@"keyStartTime"] longValue] format:@"yyyy-MM-dd HH:mm:ss"],
                    };
                    [hrArray addObject:dataDic];
                }
                if (resultForHeartRate != nil) {
                    resultForHeartRate(hrArray);
                    resultForHeartRate = nil;
                }
                NSLog(@"Requesting from :: onGetHeartRateData %@", hrArray);
                [channel invokeMethod:@"onGetHeartRateData" arguments:hrArray];

            }];

            [YCBTProduct.shared syncDataHistory:0x04 callback:^(Error_Code code,
                                                                NSDictionary *_Nonnull result) {
                NSLog(@"Requesting from :: iOS native call 0x04");
                if (result.count > 0) {
                    int lightSleepTime = 0;
                    int deepSleepTime = 0;
                    int stayUpTime = 0;
                    int totalSleepTime = 0;
                    NSMutableArray *dataListArray = [[NSMutableArray alloc] init];
                    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
                    NSMutableArray *sleepDataArray = [[NSMutableArray alloc] init];
                    //            NSDate *now = [NSDate date];
                    //            NSTimeInterval epochSeconds = [now timeIntervalSince1970];
                    //            NSString *startHour = [self converTimstamp: epochSeconds format:@"HH"];
                    //            NSInteger hour = [startHour integerValue];
                    //            NSString *startMin = [self converTimstamp: epochSeconds format:@"HH"];
                    //            NSInteger min = [startMin integerValue];
                    //            NSInteger seconds = (hour * 3600) + (min * 60) + 10800;
                    //            NSLog(@"%f",epochSeconds);
                    //            long time = epochSeconds - seconds;


                    // long timestamp = [historyDatas.lastObject[@"keyEndTime"] longValue];
                    //            NSString *dateString = [self converTimstamp: epochSeconds format:@"yyyy-MM-dd"];

                    long timestampValue = [result[@"keyEndTime"] longValue];
                    NSString *selectedDate = [self converTimstamp:timestampValue format:@"yyyy-MM-dd"];
                    NSString *hourTime = [self converTimstamp:timestampValue format:@"HH"];
                    NSInteger hourValue = [hourTime integerValue];
                    NSInteger startTimestamp = timestampValue;
                    NSInteger endTimestamp = timestampValue;
                    if (hourValue > 12) {
                        startTimestamp = startTimestamp - ((hourValue - 21) * 3600);
                        endTimestamp = endTimestamp + ((24 - hourValue) * 3600) + 46000;
                    } else {
                        startTimestamp = startTimestamp - (hourValue * 3600);
                        endTimestamp = endTimestamp + ((12 - hourValue) * 3600);
                    }
                    //            NSDate *date = [self convertStringToDate:dateString];
                    //            NSTimeInterval epochSecondsForEndTime = [date timeIntervalSince1970];
                    //            NSLog(@"date is %f", epochSecondsForEndTime);
                    //            NSString *endHour = [self converTimstamp: timestamp format:@"HH"];

                    for (NSDictionary *data in result) {
                        long endTimestampValue = [data[@"keyEndTime"] longValue];
                        if (endTimestampValue > startTimestamp &&
                            endTimestampValue < endTimestamp) {
                            [dataArray addObject:data];
                        } else {
                            NSMutableArray *copyDataArray = [[NSMutableArray alloc] init];
                            for (NSDictionary *value in dataArray) {
                                [copyDataArray addObject:value];
                            }
                            [dataListArray addObject:copyDataArray];
                            [dataArray removeAllObjects];
                            [dataArray addObject:data];

                            selectedDate = [self converTimstamp:endTimestampValue format:@"yyyy-MM-dd"];
                            hourTime = [self converTimstamp:endTimestampValue format:@"HH"];
                            hourValue = [hourTime integerValue];

                            if (hourValue > 12) {
                                startTimestamp = endTimestampValue - ((hourValue - 21) * 3600);
                                endTimestamp =
                                        endTimestampValue + ((24 - hourValue) * 3600) + 46000;
                            } else {
                                startTimestamp = endTimestampValue - (hourValue * 3600);
                                endTimestamp = endTimestampValue + ((12 - hourValue) * 3600);
                            }

                        }
                        //                long dataTime = [data[@"keyEndTime"] longValue];
                        //                if(dataTime > time){
                        //                    [dataArray addObject:data];
                        //                }
                    }

                    [dataListArray addObject:dataArray];

                    for (NSMutableArray *dataList in dataListArray) {
                        //   for (NSDictionary *sleepData in dataArray) {
                        NSMutableArray *dataInfo = [[NSMutableArray alloc] init];

                        for (int i = 0; i < [dataList count]; i++) {
                            NSDictionary *sleepData = [dataList objectAtIndex:i];

                            if (sleepData != nil) {
                                NSArray *data = sleepData[@"keyHistoryData"];
                                lightSleepTime = lightSleepTime +
                                                 [sleepData[@"keyLightSleepTotal"] intValue];
                                deepSleepTime =
                                        deepSleepTime + [sleepData[@"keyDeepSleepTotal"] intValue];
                                int lastElementType = 0;
                                for (NSDictionary *value in data) {
                                    NSString *startTime = [self converTimstamp:[value[@"keySleepStartTime"] longValue] format:@"HH:mm"];
                                    int type = [value[@"keySleepType"] intValue];
                                    if (type == 242) {
                                        //lightSleep
                                        type = 2;
                                        lastElementType = 2;
                                    } else if (type == 241) {
                                        //deeepSleep
                                        type = 3;
                                        lastElementType = 3;
                                    } else {
                                        lastElementType = 0;
                                    }

                                    //                    int sleepLen = [value[@"keySleepLen"] intValue];

                                    NSDictionary *info = @{
                                            @"type": [NSNumber numberWithInt:type],
                                            @"time": startTime,

                                    };
                                    [dataInfo addObject:info];
                                }
                                NSString *endTime = [self converTimstamp:[sleepData[@"keyEndTime"] longValue] format:@"HH:mm"];
                                NSDictionary *info;
                                if (i != ([dataArray count] - 1)) {
                                    info = @{
                                            //@"type" :[NSNumber numberWithInt: lastElementType],
                                            @"type": @0,
                                            @"time": endTime,
                                    };
                                } else {
                                    info = @{
                                            //@"type" :[NSNumber numberWithInt: lastElementType],
                                            @"type": [NSNumber numberWithInt:lastElementType],
                                            @"time": endTime,
                                    };
                                }
                                [dataInfo addObject:info];


                            }
                        }

                        NSInteger sleepEndTime = [dataList.lastObject[@"keyEndTime"] longValue];
                        NSString *sleepEndTimeHourString = [self converTimstamp:sleepEndTime format:@"HH"];
                        NSInteger sleepHourValue = [sleepEndTimeHourString integerValue];
                        if (sleepHourValue > 12) {
                            sleepEndTime = sleepEndTime + ((24 - sleepHourValue) * 3600);
                        }

                        //            for (int i=0; i<dataArray.count - 1; i++){
                        //                stayUpTime += [dataArray[i+1] [@"keyStartTime"] intValue] - [dataArray[i] [@"keyEndTime"] intValue];
                        //                NSLog(@"awake data %d", stayUpTime);
                        //                }
                        totalSleepTime = lightSleepTime + deepSleepTime + stayUpTime / 60;

                        NSDictionary *dataDic = @{
                                @"lightTime": [NSNumber numberWithInt:lightSleepTime],
                                @"deepTime": [NSNumber numberWithInt:deepSleepTime],
                                @"date": [self converTimstamp:sleepEndTime format:@"yyyy-MM-dd HH:mm:ss"],
                                @"typeDate": dataInfo,
                                @"sleepAllTime": [NSNumber numberWithInt:totalSleepTime],
                                @"stayUpTime": [NSNumber numberWithInt:stayUpTime / 60],
                                @"sdkType": @2,

                        };

                        [sleepDataArray addObject:dataDic];
                        lightSleepTime = 0;
                        deepSleepTime = 0;
                        stayUpTime = 0;
                        totalSleepTime = 0;
                    }
                    NSLog(@"Requesting from :: onResponseSleepInfoE66 %@", sleepDataArray);
                    [channel invokeMethod:@"onResponseSleepInfoE66" arguments:sleepDataArray];

                }

            }];

            result(@(hr));
        } else if ([@"getOxygenData" isEqualToString:call.method]) {
            [YCBTProduct.shared getBloodOxygen:^(Error_Code code, NSDictionary *_Nonnull result) {
                if (code == Error_Ok) {
                    NSInteger type = [result[@"keyBloodOxygenType"] integerValue];
                    NSInteger value = [result[@"keyBloodOxygenValue"] integerValue];
                    NSLog(@"type: %@, value: %@", @(type), @(value));

                }
            }];
        } else if ([@"setTemperatureMonitorOn" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            int timeInterval = [[call.arguments objectForKey:@"timeInterval"] intValue];
            if (sdkType == 2) {
                NSInteger mode = isEnable ? 0x01 : 0x00;
                [YCBTProduct.shared settingTemperatureMonitoringEnabel:mode monitoringInterval:timeInterval callback:^(
                        Error_Code code,
                        NSDictionary *_Nonnull result) {
                    if (code == Error_Ok) {
                        NSLog(@"Success is imortant");
                    } else {
                        NSLog(@"Failed");
                    }
                }];
            }
        } else if ([@"setOxygenMonitorOn" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            int timeInterval = [[call.arguments objectForKey:@"timeInterval"] intValue];
            if (sdkType == 2) {
                NSInteger mode = isEnable ? 0x01 : 0x00;
                [YCBTProduct.shared settingBloodOxygenMode:mode timeInterval:timeInterval callback:^(
                        Error_Code code, NSDictionary *
                _Nonnull result) {
                    if (code == Error_Ok) {
                        NSLog(@"Success");
                    } else {
                        NSLog(@"Failed");
                    }
                }];
            }
        } else if ([@"setBpMonitoring" isEqualToString:call.method]) {
            BOOL isEnable = [[call.arguments objectForKey:@"enable"] boolValue];
            int sdkType = [[call.arguments objectForKey:@"sdkType"] intValue];
            int timeInterval = [[call.arguments objectForKey:@"timeInterval"] intValue];
            if (sdkType == 2) {
                NSInteger mode = isEnable ? 0x01 : 0x00;
                [YCBTProduct.shared settingBloodMode:mode autoBloodTime:timeInterval callback:^(
                        Error_Code code, NSDictionary *_Nonnull result) {
                    if (code == Error_Ok) {
                        NSLog(@"Success");
                        NSLog(@"Success setBpMonitoringsetBpMonitoring %@",result);
                    } else {
                        NSLog(@"Failed");
                    }
                }];
            }
        } else if ([@"startMode" isEqualToString:call.method]) {
            NSInteger mode = [call.arguments integerValue];

            [YCBTProduct.shared beginRunMode:YES runType:mode];
            result(@(true));
        } else if ([@"endMode" isEqualToString:call.method]) {
            NSInteger mode = [call.arguments integerValue];

            [YCBTProduct.shared beginRunMode:NO runType:mode];
            result(@(true));
        } else if ([@"reset" isEqualToString:call.method]) {
            [[YCBTProduct shared] settingReset:^(Error_Code code, NSDictionary *_Nonnull result) {
            }];
        } else if ([@"shutdown" isEqualToString:call.method]) {
            [YCBTProduct.shared turnOnDevice:0x01 callBack:^(Error_Code code, NSDictionary *_Nonnull
                                                             result) {
                if (code == Error_Ok) {
                    NSLog(@"Success");
                } else {
                    NSLog(@"Failed");
                }
            }];

        } else if ([@"collectHeartRateHistory" isEqualToString:call.method]) {
            resultForHeartRate = result;
            [YCBTProduct.shared syncDataHistory:0x06
                                       callback:^(Error_Code code, NSDictionary *_Nonnull result) {
                                           NSLog(@"%@", result);
                                       }];
        } else if ([@"getTempData" isEqualToString:call.method]) {
            [YCBTProduct.shared openTemperatureMeasurementControl:0x01 callBack:^(Error_Code code,
                                                                                  NSDictionary *_Nonnull
                                                                                  result) {

                if (code == Error_Ok) {
                    NSLog(@"%@", result);
                }
            }];

            [YCBTProduct.shared getDevRealTemperature:^(Error_Code code, NSDictionary *_Nonnull
                                                        result) {

                if (code == Error_Ok) {

                    NSString *temperatue = result[@"keyRealTemperature"];

                    double temperatueValue = temperatue.doubleValue;
                    [channel invokeMethod:@"onGetRealTemp" arguments:@(temperatueValue)];
                }
            }];

        } else if ([@"deleteSport" isEqualToString:call.method]) {
            [YCBTProduct.shared deleteHistoryData:0x40 callback:^(Error_Code code,
                                                                  NSDictionary *_Nonnull
                                                                  result) {}];
        } else if ([@"deleteSleep" isEqualToString:call.method]) {
            [YCBTProduct.shared deleteHistoryData:0x41 callback:^(Error_Code code,
                                                                  NSDictionary *_Nonnull
                                                                  result) {}];
        } else if ([@"deleteHeartRate" isEqualToString:call.method]) {
            [YCBTProduct.shared deleteHistoryData:0x42 callback:^(Error_Code code,
                                                                  NSDictionary *_Nonnull
                                                                  result) {}];
        } else if ([@"deleteBloodPressure" isEqualToString:call.method]) {
            [YCBTProduct.shared deleteHistoryData:0x43 callback:^(Error_Code code,
                                                                  NSDictionary *_Nonnull
                                                                  result) {}];
        } else if ([@"deleteTempAndOxygen" isEqualToString:call.method]) {
            [YCBTProduct.shared deleteHistoryData:0x44 callback:^(Error_Code code,
                                                                  NSDictionary *_Nonnull
                                                                  result) {}];
        } else if ([@"collectECG" isEqualToString:call.method]) {

            [YCBTProduct.shared syncECGCollectList:^(Error_Code code, NSDictionary *
            _Nonnull resultValue) {
                if (resultValue) {
                    NSArray *data = resultValue[@"data"];
                    if (data != nil && [data count] > 0) {
                        NSInteger dataLength = [data count] - 1;
                        getEcgListFromSdk(dataLength, result);
                    }
                    NSLog(@" %@", data);

                }
            }];
        } else if ([@"getDeviceConfiguration" isEqualToString:call.method]) {
            [YCBTProduct.shared getUserConfigurationInfo:^(Error_Code code, NSDictionary *_Nonnull
                                                           result) {
                if (code == Error_Ok) {
                    [channel invokeMethod:@"deviceConfigurationInfo" arguments:result];
                    NSLog(@"%@", result);
                }
            }];
        }
    }];

    [GMSServices provideAPIKey:@"AIzaSyCtprfu6ShvuvpBU2qa3N-zqkeloydHAuE"];
    [GeneratedPluginRegistrant registerWithRegistry:self];
    if (@available
    (iOS
    10.0, *)) {
        [UNUserNotificationCenter currentNotificationCenter].delegate = (id <UNUserNotificationCenterDelegate>) self;
    }
    [FlutterDownloaderPlugin setPluginRegistrantCallback:registerPlugins];
//    [self configureProcessingTask];
//    [self scheduleProcessingTask];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}


void getEcgListFromSdk(NSInteger index, FlutterResult resultData) {
    [YCBTProduct.shared syncECGCollectData:index progress:^(float
                                                            ratio) {
                NSLog(@"%.0f%%", ratio * 100);
            }
                                  callback:^(Error_Code code, NSDictionary *_Nonnull ecgResult) {
                                      if (code == Error_Ok) {
                                          NSArray *ecgData = ecgResult[@"keyEcgData"];
                                          NSDictionary *ecgDictionary = @{
                                                  @"ecgData": ecgData
                                          };
                                          resultData(ecgDictionary);
                                          NSLog(@"finished");
                                      } else {
                                          NSLog(@"error");
                                      }
                                  }];
}

///BREAK: Background Watch Data Sync

///BREAK: Manage interruption of system and app audio
- (void)handleInterruption:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSInteger interruptionType = [userInfo[AVAudioSessionInterruptionTypeKey] integerValue];
    NSLog(@"Intrupt: %@", userInfo);
    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        // Audio interruption began, stop your audio playback here if needed.
        // [self.player pause];
    } else if (interruptionType == AVAudioSessionInterruptionTypeEnded) {
        [self setSession];
        [self.player play];
    }
}

///BREAK: Manage current audio session
- (void)setSession {

    self.session = [AVAudioSession sharedInstance];
    [self.session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];

    NSError *error = nil;
    [self.session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];

    if (error) {
        NSLog(@"Error deactivating AVAudioSession: %@", error.localizedDescription);
    }

    // Set the active state of the audio session.
    [self.session setActive:YES error:nil];
}

///BREAK: Audio session observer
- (void)audioNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
}

///BREAK: Playing Audio file to run the timer.
- (void)audioPlayer {
    NSString *path = [NSString stringWithFormat:@"%@/clock_ticking.mp3", [[NSBundle mainBundle] resourcePath]];
    NSURL *soundUrl = [NSURL fileURLWithPath:path];

    NSError *error;
    // Create an AVAudioPlayer instance.
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:&error];
    // Check if the player was created successfully.
    if (self.player) {
        // Play the audio file.
        [self.player setNumberOfLoops:-1];
        [self.player setVolume:0.0];
        [self.player prepareToPlay];
    } else {
        // The audio file could not be loaded.
        NSLog(@"Error loading audio file: %@", error);
    }
    // Delay execution of my block for 1 seconds.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.player play];
    });
}

///BREAK: iOS Timer Running all the time.
- (void)startTimer {
    // Invalidate any existing timer
    [self.syncTimer invalidate];

    // Create a new timer
    self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                                      target:self
                                                    selector:@selector(timerFired:)
                                                    userInfo:nil
                                                     repeats:YES];

    // Ensure that the timer runs even when the app is in the background
    [[NSRunLoop mainRunLoop] addTimer:self.syncTimer forMode:NSRunLoopCommonModes];
}

///BREAK: Method to cal from the timer (startTimer)
- (void)timerFired:(NSTimer *)syncTimer {
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];

    NSString *dateString = [dateFormatter stringFromDate:date];
    NSString *startTime = [NSString stringWithFormat:@"Requesting from iOS: %@:", dateString];

    NSLog(@"%@", startTime);
    [channel invokeMethod:@"syncWatchData" arguments:startTime];
}

- (void)bleConnectStateChange:(NSNotification *)ntf {
    NSDictionary *tUserInfo = ntf.userInfo;

    NSLog(@"bleConnectStateChange %@", tUserInfo);

    if (tUserInfo) {
        Error_Code tErrorCode = [tUserInfo[kNtfConnectStateKey] integerValue];
        if (tErrorCode == Error_Ok) {
        } else {

        }
    }
}

- (void)msgGetBlood:(NSNotification *)ntf {
    NSLog(@"msgGetBlood");
    //@{@"keyHeartNum":@(tHeartNum), @"keySystolicB":@(tSystolicB), @"keyDiastolicB":@(tDiastolicB)}

    NSDictionary *tUserInfo = ntf.userInfo;
    if (tUserInfo) {
        e66Hr = [tUserInfo[@"keyHeartNum"] intValue];
        e66Sbp = [tUserInfo[@"keySystolicB"] intValue];  //收缩压
        e66Dbp = [tUserInfo[@"keyDiastolicB"] intValue];
        e66Hrv = [tUserInfo[@"keyHRV"] intValue];

        NSDictionary *hrData = @{
                @"sbp": [NSNumber numberWithInt:e66Sbp],
                @"dbp": [NSNumber numberWithInt:e66Dbp],
                @"hr": [NSNumber numberWithInt:e66Hr],
        };

        [channel invokeMethod:@"onGetHRData" arguments:hrData];

    }
}

- (void)msgGetEcgData:(NSNotification *)ntf {
    NSLog(@"msgGetEcgData");
    //@{@"keyEcgData":tEcgArr}
    NSDictionary *tUserInfo = ntf.userInfo;
    if (tUserInfo) {
        NSMutableArray *tEcgArr = tUserInfo[@"keyEcgData"];
        if (ecgStartTime == 0) {
            NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:[[NSDate date] timeIntervalSince1970]];

            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss.SSS"];

            ecgStartTimeMilliseconds = [dateFormatter stringFromDate:timestamp];

            ecgStartTime = (long long) ([[NSDate date] timeIntervalSince1970]);
        }
        long endTime = (long long) ([[NSDate date] timeIntervalSince1970]);

        NSMutableArray *processedEcgArr = [[NSMutableArray alloc] init];
        for (NSNumber *tEcgNum in tEcgArr) {

            int tData = tEcgNum.intValue;
            float ecg_val = 0.0;

            ecg_val = ecg_data_proc(tData);
            [processedEcgArr addObject:[NSNumber numberWithInt:ecg_val]];
        }
        NSDictionary *data = @{
                @"approxHr": [NSNumber numberWithInt:e66Hr],
                @"approxSBP": [NSNumber numberWithInt:e66Sbp],
                @"approxDBP": [NSNumber numberWithInt:e66Dbp],
                // @"ecgPointY": number,
                @"hrv": [NSNumber numberWithInt:e66Hrv],
                @"startTime": @(ecgStartTime),
                @"endTime": @(endTime),
                @"isLeadOff": @YES,
                @"isPoorConductivity": @(isPoorConductivity),
                @"pointList": processedEcgArr,
                @"startTimeWithMilliseconds": ecgStartTimeMilliseconds,
        };
        [channel invokeMethod:@"onResponseEcgInfo" arguments:data];

        NSDictionary *dataPpg = @{
                @"point": @0.0,
                @"startTime": @(ecgStartTime),
                @"endTime": @(endTime),
        };

        //  [channel invokeMethod:@"onResponsePpgInfo" arguments:dataPpg];


        //     }
        NSLog(@"%@", tEcgArr);
    }

}

- (void)msgGetPpgData:(NSNotification *)ntf {
    NSLog(@"msgGetPpgData"); //@{@"keyEcgData":tEcgArr}
    NSDictionary *tUserInfo = ntf.userInfo;
    if (tUserInfo) {
        NSMutableArray *ppgData = tUserInfo[@"keyPpgData"];
        NSLog(@"PPG: %@", ppgData);

        if (ppgStartTime == 0) {
            NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:[[NSDate date] timeIntervalSince1970]];

            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss.SSS"];

            ppgStartTimeMilliseconds = [dateFormatter stringFromDate:timestamp];
            ppgStartTime = (long long) ([[NSDate date] timeIntervalSince1970]);
        }
        long endTime = (long long) ([[NSDate date] timeIntervalSince1970]);

//    for (int i=0; i<ppgData.count; i++) {
//        NSNumber *number = ppgData[i] ;
        NSDictionary *data = @{
                @"pointList": ppgData,
                @"startTime": @(ppgStartTime),
                @"endTime": @(endTime),
                @"startTimeWithMilliseconds": ppgStartTimeMilliseconds,
        };

        [channel invokeMethod:@"onResponsePpgInfo" arguments:data];
        // }
    }

}

- (void)revicePPGStauts:(NSNotification *)ntf {
    NSDictionary *dict = ntf.userInfo;
    NSLog(@"dict = %@", dict);
    int tPPGStatus = [dict[@"keyPpgStatus"] intValue];
    int tECGStatus = [dict[@"keyEcgStatus"] intValue];

    NSDictionary *data = @{
            @"ecgStatus": [NSNumber numberWithInt:tECGStatus],
            @"ppgStatus": [NSNumber numberWithInt:tPPGStatus],

    };

    [channel invokeMethod:@"onResponseLeadStatus" arguments:data];

//    if (tPPGStatus == 0) {
//        NSLog(@" Worn");
//    } else {
//        NSLog(@"Not worn");
//}

    NSLog(@" ECG Status is %ld", (long) tECGStatus);
}


- (void)syncWeighingUserToBle {
    //connect scale must input sex、weight、age

    BLEUser *user = [[BLEUser alloc] init];
    user.userSex = _appUser.sex;
    user.userAge = _appUser.age;
    user.userHeight = _appUser.height;
    [[WriteToBLEManager shareManager] syncWeighingUser:user];

}


- (void)msgGetHistoryData:(NSNotification *)ntf {


    NSDictionary *tUserInfo = ntf.userInfo;
    if (tUserInfo == nil) {

        return;
    }

    NSInteger tHistoryType = [tUserInfo[@"keyHistoryType"] integerValue];
    NSMutableArray *historyDatas = tUserInfo[@"keyHistoryData"];

    if (tHistoryType == 0x02) { // step

//        NSDate *now = [NSDate date];
//        NSTimeInterval epochSeconds = [now timeIntervalSince1970];
////        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
////           [dateFormatter setDateFormat:@"yyyy-MM-dd"];
////
////        NSString *dateString = [dateFormatter stringFromDate:now];
////           NSLog(@"Current date is %@",dateString);
////           NSDate *newDate = [dateFormatter dateFromString:dateString];
////        NSTimeInterval nowEpochSeconds = [newDate timeIntervalSince1970];
//        NSString *startHour = [self converTimstamp: epochSeconds format:@"HH"];
//        NSInteger hour = [startHour integerValue];
//        NSString *startMin = [self converTimstamp: epochSeconds format:@"mm"];
//        NSInteger min = [startMin integerValue];
//        NSInteger seconds = (hour * 3600) + (min * 60);
//        NSLog(@"%f",epochSeconds);
//        NSMutableArray *dataArray = [[NSMutableArray alloc] init];
//        long time = epochSeconds - seconds;
//        for (NSDictionary *data in historyDatas){
//            long dataTime = [data[@"keyEndTime"] longValue];
//            if(dataTime >=  time){
//                [dataArray addObject:data];
//            }
//        }
//
//        int totalStep = 0;
//        int totalCalories = 0;
//        double totalDistance = 0;
//
//        NSMutableArray *stepsArray = [[NSMutableArray alloc] init];
//        NSMutableArray *caloriesArray = [[NSMutableArray alloc] init];
//        NSMutableArray *distanceArray = [[NSMutableArray alloc] init];
//
//        for (int j = 0; j < 24; j++) {
//            [stepsArray addObject:@0];
//            [caloriesArray addObject:@0];
//            [distanceArray addObject:@0];
//        }
//
//        for (NSDictionary *data in dataArray){
//            NSString *startTime = [self converTimstamp: [data[@"keyStartTime"] longValue] format:@"HH"];
//            NSInteger hour = [startTime integerValue];
//
//            int steps = [[stepsArray objectAtIndex:hour] intValue];
//            int calories = [[stepsArray objectAtIndex:hour] intValue];
//            int distance = [[stepsArray objectAtIndex:hour] intValue];
//
//            steps = steps + [data[@"keyStep"] intValue];
//            calories = calories + [data[@"keyCalories"] intValue];
//            distance = distance + [data[@"keyDistance"] intValue];
//
//            [stepsArray replaceObjectAtIndex:hour withObject:[NSNumber numberWithInt:steps]];
//            [caloriesArray replaceObjectAtIndex:hour withObject:[NSNumber numberWithInt:calories]];
//            [distanceArray replaceObjectAtIndex:hour withObject:[NSNumber numberWithInt:distance]];
//
//            totalStep = totalStep + [data[@"keyStep"] intValue];
//            totalCalories = totalCalories + [data[@"keyCalories"] intValue];
//            totalDistance = totalDistance + [data[@"keyDistance"] intValue];
//        }
//
//        NSDictionary *data = @{
//            @"date" :  [self converTimstamp:epochSeconds format:@"yyyy-MM-dd HH:mm:ss"],
//            @"data" : stepsArray,
//            @"calories" : [NSNumber numberWithInt: totalCalories],
//            @"distance" : [NSNumber numberWithDouble: totalDistance/1000],
//            @"step": [NSNumber numberWithInt: totalStep]
//        };
//        NSLog(@"getSportForDate ",data);
//        [channel invokeMethod:@"onResponseMotionInfo" arguments:data];
//
//
//        /*
//         @[
//         @{
//         @"keyStartTime": 开始时间, 到1970年的秒数
//         @"keyEndTime": 结束时间,   到1970年的秒数
//         @"keyStep": 步数, 单位:步
//         @"keyCalories": 卡路里, 单位:千卡
//         @"keyDistance": 距离 单位:米
//         };
//         ]
//
//         */
//        NSLog(@"steps %@", historyDatas);


        if (historyDatas != nil) {
            if (historyDatas.count > 0) {
                long dataTime = [historyDatas.firstObject[@"keyStartTime"] longValue];
                NSString *date = [self converTimstamp:dataTime format:@"yyyy-MM-dd"];
                NSMutableArray *dataListArray = [[NSMutableArray alloc] init];
                NSMutableArray *dataArray = [[NSMutableArray alloc] init];
                for (NSDictionary *data in historyDatas) {
                    long elementTime = [data[@"keyStartTime"] longValue];
                    NSString *elementdate = [self converTimstamp:elementTime format:@"yyyy-MM-dd"];

                    if ([date isEqualToString:elementdate]) {
                        [dataArray addObject:data];
                    } else {
                        date = elementdate;
                        NSMutableArray *copyDataArray = [[NSMutableArray alloc] init];
                        for (NSDictionary *value in dataArray) {
                            [copyDataArray addObject:value];
                        }
                        [dataListArray addObject:copyDataArray];
                        [dataArray removeAllObjects];
                        [dataArray addObject:data];
                    }
                }
                [dataListArray addObject:dataArray];
                NSMutableArray *motionDataArray = [[NSMutableArray alloc] init];
                for (NSMutableArray *dataList in dataListArray) {
                    long date = [dataList.firstObject[@"keyStartTime"] longValue];
                    int totalStep = 0;
                    int totalCalories = 0;
                    double totalDistance = 0;

                    NSMutableArray *stepsArray = [[NSMutableArray alloc] init];
                    NSMutableArray *caloriesArray = [[NSMutableArray alloc] init];
                    NSMutableArray *distanceArray = [[NSMutableArray alloc] init];

                    for (int j = 0; j < 24; j++) {
                        [stepsArray addObject:@0];
                        [caloriesArray addObject:@0];
                        [distanceArray addObject:@0];
                    }
                    for (NSDictionary *data in dataList) {
                        NSString *startTime = [self converTimstamp:[data[@"keyStartTime"] longValue] format:@"HH"];
                        NSInteger hour = [startTime integerValue];

                        int steps = [[stepsArray objectAtIndex:hour] intValue];
                        int calories = [[stepsArray objectAtIndex:hour] intValue];
                        int distance = [[stepsArray objectAtIndex:hour] intValue];

                        steps = steps + [data[@"keyStep"] intValue];
                        calories = calories + [data[@"keyCalories"] intValue];
                        distance = distance + [data[@"keyDistance"] intValue];

                        [stepsArray replaceObjectAtIndex:hour withObject:[NSNumber numberWithInt:steps]];
                        [caloriesArray replaceObjectAtIndex:hour withObject:[NSNumber numberWithInt:calories]];
                        [distanceArray replaceObjectAtIndex:hour withObject:[NSNumber numberWithInt:distance]];

                        totalStep = totalStep + [data[@"keyStep"] intValue];
                        totalCalories = totalCalories + [data[@"keyCalories"] intValue];
                        totalDistance = totalDistance + [data[@"keyDistance"] intValue];
                    }

                    NSDictionary *data = @{
                            @"date": [self converTimstamp:date format:@"yyyy-MM-dd HH:mm:ss"],
                            @"data": stepsArray,
                            @"calories": [NSNumber numberWithInt:totalCalories],
                            @"distance": [NSNumber numberWithDouble:totalDistance / 1000],
                            @"step": [NSNumber numberWithInt:totalStep]
                    };
                    [motionDataArray addObject:data];

                }
                [channel invokeMethod:@"onResponseMotionInfoE66" arguments:motionDataArray];
                NSLog(@"steps %@", historyDatas);
            }
        }

    } else if (tHistoryType == 0x04) { // sleep
        if (historyDatas.count > 0) {
            int lightSleepTime = 0;
            int deepSleepTime = 0;
            int stayUpTime = 0;
            int totalSleepTime = 0;
            NSMutableArray *dataListArray = [[NSMutableArray alloc] init];
            NSMutableArray *dataArray = [[NSMutableArray alloc] init];
            NSMutableArray *sleepDataArray = [[NSMutableArray alloc] init];
//            NSDate *now = [NSDate date];
//            NSTimeInterval epochSeconds = [now timeIntervalSince1970];
//            NSString *startHour = [self converTimstamp: epochSeconds format:@"HH"];
//            NSInteger hour = [startHour integerValue];
//            NSString *startMin = [self converTimstamp: epochSeconds format:@"HH"];
//            NSInteger min = [startMin integerValue];
//            NSInteger seconds = (hour * 3600) + (min * 60) + 10800;
//            NSLog(@"%f",epochSeconds);
//            long time = epochSeconds - seconds;


            // long timestamp = [historyDatas.lastObject[@"keyEndTime"] longValue];
//            NSString *dateString = [self converTimstamp: epochSeconds format:@"yyyy-MM-dd"];
            long timestampValue = [historyDatas.firstObject[@"keyEndTime"] longValue];
            NSString *selectedDate = [self converTimstamp:timestampValue format:@"yyyy-MM-dd"];
            NSString *hourTime = [self converTimstamp:timestampValue format:@"HH"];
            NSInteger hourValue = [hourTime integerValue];
            NSInteger startTimestamp = timestampValue;
            NSInteger endTimestamp = timestampValue;
            if (hourValue > 12) {
                startTimestamp = startTimestamp - ((hourValue - 21) * 3600);
                endTimestamp = endTimestamp + ((24 - hourValue) * 3600) + 46000;
            } else {
                startTimestamp = startTimestamp - (hourValue * 3600);
                endTimestamp = endTimestamp + ((12 - hourValue) * 3600);
            }
//            NSDate *date = [self convertStringToDate:dateString];
//            NSTimeInterval epochSecondsForEndTime = [date timeIntervalSince1970];
//            NSLog(@"date is %f", epochSecondsForEndTime);
//            NSString *endHour = [self converTimstamp: timestamp format:@"HH"];

            for (NSDictionary *data in historyDatas) {
                long endTimestampValue = [data[@"keyEndTime"] longValue];
                if (endTimestampValue > startTimestamp && endTimestampValue < endTimestamp) {
                    [dataArray addObject:data];
                } else {
                    NSMutableArray *copyDataArray = [[NSMutableArray alloc] init];
                    for (NSDictionary *value in dataArray) {
                        [copyDataArray addObject:value];
                    }
                    [dataListArray addObject:copyDataArray];
                    [dataArray removeAllObjects];
                    [dataArray addObject:data];

                    selectedDate = [self converTimstamp:endTimestampValue format:@"yyyy-MM-dd"];
                    hourTime = [self converTimstamp:endTimestampValue format:@"HH"];
                    hourValue = [hourTime integerValue];

                    if (hourValue > 12) {
                        startTimestamp = endTimestampValue - ((hourValue - 21) * 3600);
                        endTimestamp = endTimestampValue + ((24 - hourValue) * 3600) + 46000;
                    } else {
                        startTimestamp = endTimestampValue - (hourValue * 3600);
                        endTimestamp = endTimestampValue + ((12 - hourValue) * 3600);
                    }

                }
//                long dataTime = [data[@"keyEndTime"] longValue];
//                if(dataTime > time){
//                    [dataArray addObject:data];
//                }
            }

            [dataListArray addObject:dataArray];

            for (NSMutableArray *dataList in dataListArray) {
                //   for (NSDictionary *sleepData in dataArray) {
                NSMutableArray *dataInfo = [[NSMutableArray alloc] init];

                for (int i = 0; i < [dataList count]; i++) {
                    NSDictionary *sleepData = [dataList objectAtIndex:i];

                    if (sleepData != nil) {
                        NSArray *data = sleepData[@"keyHistoryData"];
                        lightSleepTime =
                                lightSleepTime + [sleepData[@"keyLightSleepTotal"] intValue];
                        deepSleepTime = deepSleepTime + [sleepData[@"keyDeepSleepTotal"] intValue];
                        int lastElementType = 0;
                        for (NSDictionary *value in data) {
                            NSString *startTime = [self converTimstamp:[value[@"keySleepStartTime"] longValue] format:@"HH:mm"];
                            int type = [value[@"keySleepType"] intValue];
                            if (type == 242) {
                                //lightSleep
                                type = 2;
                                lastElementType = 2;
                            } else if (type == 241) {
                                //deeepSleep
                                type = 3;
                                lastElementType = 3;
                            } else {
                                lastElementType = 0;
                            }

//                    int sleepLen = [value[@"keySleepLen"] intValue];

                            NSDictionary *info = @{
                                    @"type": [NSNumber numberWithInt:type],
                                    @"time": startTime,

                            };
                            [dataInfo addObject:info];
                        }
                        NSString *endTime = [self converTimstamp:[sleepData[@"keyEndTime"] longValue] format:@"HH:mm"];
                        NSDictionary *info;
                        if (i != ([dataArray count] - 1)) {
                            info = @{
                                    //@"type" :[NSNumber numberWithInt: lastElementType],
                                    @"type": @0,
                                    @"time": endTime,
                            };
                        } else {
                            info = @{
                                    //@"type" :[NSNumber numberWithInt: lastElementType],
                                    @"type": [NSNumber numberWithInt:lastElementType],
                                    @"time": endTime,
                            };
                        }
                        [dataInfo addObject:info];


                    }
                }

                NSInteger sleepEndTime = [dataList.lastObject[@"keyEndTime"] longValue];
                NSString *sleepEndTimeHourString = [self converTimstamp:sleepEndTime format:@"HH"];
                NSInteger sleepHourValue = [sleepEndTimeHourString integerValue];
                if (sleepHourValue > 12) {
                    sleepEndTime = sleepEndTime + ((24 - sleepHourValue) * 3600);
                }

//            for (int i=0; i<dataArray.count - 1; i++){
//                stayUpTime += [dataArray[i+1] [@"keyStartTime"] intValue] - [dataArray[i] [@"keyEndTime"] intValue];
//                NSLog(@"awake data %d", stayUpTime);
//                }
                totalSleepTime = lightSleepTime + deepSleepTime + stayUpTime / 60;

                NSDictionary *dataDic = @{
                        @"lightTime": [NSNumber numberWithInt:lightSleepTime],
                        @"deepTime": [NSNumber numberWithInt:deepSleepTime],
                        @"date": [self converTimstamp:sleepEndTime format:@"yyyy-MM-dd HH:mm:ss"],
                        @"typeDate": dataInfo,
                        @"sleepAllTime": [NSNumber numberWithInt:totalSleepTime],
                        @"stayUpTime": [NSNumber numberWithInt:stayUpTime / 60],
                        @"sdkType": @2,

                };

                [sleepDataArray addObject:dataDic];
                lightSleepTime = 0;
                deepSleepTime = 0;
                stayUpTime = 0;
                totalSleepTime = 0;
            }

            [channel invokeMethod:@"onResponseSleepInfoE66" arguments:sleepDataArray];

        }

        NSLog(@"sleep data %@", historyDatas);

    } else if (tHistoryType == 0x06) { // heart
        if (historyDatas.count > 0) {
            NSMutableArray *hrArray = [[NSMutableArray alloc] init];
            for (NSDictionary *data in historyDatas) {
                //  long timestamp = [data[@"keyStartTime"]longValue];
                NSDictionary *dataDic = @{
                        @"heartValue": data[@"keyHeartNum"],
                        // @"heartStartTime" : [NSNumber numberWithLong: timestamp],
                        @"heartStartTime": [self converTimstamp:[data[@"keyStartTime"] longValue] format:@"yyyy-MM-dd HH:mm:ss"],
                };
                [hrArray addObject:dataDic];
            }
            if (resultForHeartRate != nil) {
                resultForHeartRate(hrArray);
                resultForHeartRate = nil;
            }
            [channel invokeMethod:@"onGetHeartRateData" arguments:hrArray];


        }

    } else if (tHistoryType == 0x08) { // blood

        if (historyDatas.count > 0) {
            NSMutableArray *monitoredDataArray = [[NSMutableArray alloc] init];
            for (NSDictionary *data in historyDatas) {
                // NSDictionary *data = historyDatas.lastObject;
                NSDictionary *dataDic = @{
                        @"bloodSBP": data[@"keySBP"],
                        @"bloodDBP": data[@"keyDBP"],
                        @"bloodStartTime": [self converTimstamp:[data[@"keyStartTime"] longValue] format:@"yyyy-MM-dd HH:mm:ss"]
                };
                [monitoredDataArray addObject:dataDic];
            }
            [channel invokeMethod:@"onResponseCollectBP" arguments:monitoredDataArray];

        }

    } else if (tHistoryType ==
               0x09) { // mutable data, such as SPpo2, blood, step, heart, hrv, cvrr, temperature...

        if (historyDatas.count > 0) {
            NSMutableArray *monitoredDataArray = [[NSMutableArray alloc] init];
            for (NSDictionary *data in historyDatas) {
                // NSDictionary *data = historyDatas.lastObject;
                NSDictionary *dataDic = @{
                        @"HRV": data[@"keyHRV"],
                        @"tempInt": data[@"keyTmepInt"],
                        @"tempDouble": data[@"keyTmepFloat"],
                        @"date": [self converTimstamp:[data[@"keyStartTime"] longValue] format:@"yyyy-MM-dd HH:mm:ss"],
                        @"cvrrValue": data[@"keyCVRR"],
                        @"oxygen": data[@"keyOO"],
                        @"stepValue": data[@"keyStep"],
                        @"heartValue": data[@"keyHeatRate"],
                        @"respiratoryRateValue": data[@"keyRespiratoryRate"],
                        @"SBPValue": data[@"keySBP"],
                        @"DBPValue": data[@"keyDBP"],
                };
                [monitoredDataArray addObject:dataDic];
            }
            [channel invokeMethod:@"onGetTempData" arguments:monitoredDataArray];

            /*
             @{
             @"keyStartTime": 测试开始时间，到1970年的秒数，
             @"keyStep": 步数, 单位:步,
             @"keyHeatRate": 心率值,
             @"keyDBP": 收缩压,
             @"keySBP": 舒张压,
             @"keyOO": 血氧值，
             @"keyRespiratoryRate": 呼呼率值,
             @"keyHRV": HRV值,
             @"keyCVRR": CVRR值,
             @"keyTmepInt": 摄氏温度整数部分，
             @"keyTmepFloat": 摄氏温度小数部分
             }
             */
        }

    } else if (tHistoryType == 0x1A) { // Spo2

        /*
         @[
         @{
         @"keyStartTime": 测试开始时间，到1970年的秒数,
         @"keyMode": 模式, 0x00: 单次模式, 0x01：监测模式,
         @"keyBloodOxygen": 血氧值, 30-240
         }
         ]
         */

        for (NSDictionary *dict in historyDatas) {

            NSLog(@"Spo2 %@", dict);
        }

    } else if (tHistoryType == 0x1C) { // Temperature and humidity

        /*
         @[
         @{
         @"keyStartTime": 测试开始时间，到1970年的秒数,
         @"keyMode": 模式, 0x00: 单次模式, 0x01：监测模式,
         @"keyTempertureInt": 温度整数部分,
         @"keyTempertureFloat": 温度小数部分,
         @"keyHumidityInt": 湿度整数部分，
         @"keyHumidityFloat": 湿度小数部分，
         }
         ]
         */

        for (NSDictionary *dict in historyDatas) {

            NSLog(@"Temperature and humidity %@", dict);
        }

    } else if (tHistoryType == 0x1E) { // Body temperature

        /*
         @[
         @{
         @"keyStartTime": 测试开始时间，到1970年的秒数,
         @"keyMode": 模式, 0x00: 单次模式, 0x01：监测模式,
         @"keyTempertureInt": 温度整数部分,
         @"keyTempertureFloat": 温度小数部分,
         }
         ]
         */

        for (NSDictionary *dict in historyDatas) {

            NSLog(@"Body temperature %@", dict);
        }

    } else if (tHistoryType == 0x20) { // Ambient light

        /*
         @[
         @{
         @"keyStartTime": 测试开始时间，到1970年的秒数,
         @"keyMode": 模式, 0x00: 单次模式, 0x01：监测模式,
         @"keyAmbientLight": 环境光的值,
         }
         ]
         */

        for (NSDictionary *dict in historyDatas) {

            NSLog(@"Ambient light %@", dict);
        }

    } else if (tHistoryType == 0x29) {  // wear off

        /*
         @[
         @{
         @"keyStartTime": 测试开始时间，到1970年的秒数,
         @"keyStatus": 状态, 0x00: 佩戴状态 0x01：脱落状态
         }
         ]
         */

        for (NSDictionary *dict in historyDatas) {

            NSLog(@"wear off %@", dict);
        }

    } else if (tHistoryType == 0x2B) { // health monitoring Data

        /*
         @[
            @{
                @"keyStartTime": 测试开始时间，到1970年的秒数，
                @"keyStep": 步数, 单位:步,
                @"keyHeatRate": 心率值,
                @"keyDBP": 收缩压,
                @"keySBP": 舒张压,
                @"keyOO": 血氧值，
                @"keyRespiratoryRate": 呼呼率值,
                @"keyHRV": HRV值,
                @"keyCVRR": CVRR值,
                @"keyTmepInt": 摄氏温度整数部分，
                @"keyTmepFloat": 摄氏温度小数部分,
                @"keyHumidityInt": 湿度整数部分,
                @"keyHumidityFloat": 湿度小数部分,
                @"keyAmbientLight": 环境光,
                @"keySportMode": 运动模式,0 普通模式，1 运动模式,
                @"keyCalorie": 卡路里,
                @"keyDistance": 运动距离, 单位: 米
            }
         ]
            
         
         */

        for (NSDictionary *dict in historyDatas) {

            NSLog(@"health monitoring Data %@", dict);
        }

    } else if (tHistoryType == 0x2D) {

        /*
        @[
            @{
                @"keyStartTime": 开始时间, 到1970年的秒数
                @"keyEndTime": 结束时间,   到1970年的秒数
                @"keyStep": 步数, 单位:步
                @"keyCalories": 卡路里, 单位:千卡
                @"keyDistance": 距离 单位:米
                @"keySportMode": 运动类型，参考运动类型启动与停止的详细说明。
            };
        ]
                
        */

        for (NSDictionary *dict in historyDatas) {

            NSLog(@"sportmode data %@", dict);
        }
    }
}


- (void)realStepData:(NSNotification *)ntf {
    int nowStep = [ntf.userInfo[@"RealStep"] intValue];
    double nowDis = [ntf.userInfo[@"RealDistance"] doubleValue];
    int nowKcal = [ntf.userInfo[@"RealCalories"] intValue];
    NSLog(@"sportmode data %d", nowStep);
    NSDictionary *data = @{
            @"calories": [NSNumber numberWithInt:nowKcal],
            @"step": [NSNumber numberWithInt:nowStep],
            @"distance": [NSNumber numberWithDouble:nowDis / 1000],

    };
    [channel invokeMethod:@"onResponseE80RealTimeMotionData" arguments:data];
}

- (NSString *)converTimstamp:(long)timestamp format:(NSString *)timeFormat {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = timeFormat;
    NSString *formattedDate = [formatter stringFromDate:date];
    return formattedDate;
}

- (NSDate *)convertStringToDate:(NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *date = [dateFormatter dateFromString:dateString];
    return date;
}

void registerPlugins(NSObject <FlutterPluginRegistry> *registry) {
    if (![registry hasPlugin:@"FlutterDownloaderPlugin"]) {
        [FlutterDownloaderPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterDownloaderPlugin"]];
    }
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray

<id <UIUserActivityRestoring>> *restorableObjects))restorationHandler
{
    // Check to make sure it's the correct activity type
    if ([userActivity.activityType isEqualToString:@"com.Meritopia.HealthGauge.StartMeasurement"]) {
        //[self startMeasuarment];
        [channel invokeMethod:@"onGetMeasurementQuery" arguments:@"Take Measurement"];
        // Extract the remote ID from the user info
        //  NSString* id = [userActivity.userInfo objectForKey:@"ID"];

        // Restore the remote screen...

        return YES;
    } else if ([userActivity.activityType isEqualToString:@"com.Meritopia.HealthGauge.FindBracelet"]) {
        [[ZHSendCmdTool shareIntance] sendFindBraceletCmd];
        //  [self startMeasuarment];
        // Extract the remote ID from the user info
        //  NSString* id = [userActivity.userInfo objectForKey:@"ID"];

        // Restore the remote screen...

        return YES;
    } else if ([userActivity.activityType isEqualToString:@"com.Meritopia.HealthGauge.TakeWeightMeasurement"]) {
        [channel invokeMethod:@"onGetMeasurementQuery" arguments:@"Take Weight Measurement"];
        //  [self startMeasuarment];
        // Extract the remote ID from the user info
        //  NSString* id = [userActivity.userInfo objectForKey:@"ID"];

        // Restore the remote screen...

        return YES;
    } else if ([userActivity.activityType isEqualToString:@"com.Meritopia.HealthGauge.TellHealthGauge"]) {
        [channel invokeMethod:@"onGetMeasurementQuery" arguments:@"Tell Health Gauge"];
        //  [self startMeasuarment];
        // Extract the remote ID from the user info
        //  NSString* id = [userActivity.userInfo objectForKey:@"ID"];

        // Restore the remote screen...

        return YES;
    }
    return NO;
}

//--------------------------------------------------------------------Connection part--------------------------------------------------------------------

//get device listener
- (void)didFindPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    @try {
        BOOL isMovefitBracelet = YES;
        if (advertisementData != nil &&
            [advertisementData objectForKey:@"kCBAdvDataLocalName"] != nil) {

            /* if([advertisementData objectForKey:@"kCBAdvDataLocalName"] != nil){
             NSString* name = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
             if ([[name uppercaseString] rangeOfString:@"CARE"].location != NSNotFound) {
             isMovefitBracelet = YES;
             }
             if ([[name uppercaseString] rangeOfString:@"E08th"].location != NSNotFound) {
             isMovefitBracelet = YES;
             }
             if ([[name uppercaseString] rangeOfString:@"G36"].location != NSNotFound) {
             isMovefitBracelet = YES;
             }
             }
             }
             }*/
            NSArray *arrayA = [advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"];
            CBUUID *someObj = arrayA.firstObject;
            //           NSMutableData *data=[[NSMutableData alloc] init];
            //
            //            NSData *data1 = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];  // length of the data received
            //            NSInteger length =  data1.length;
            //
            //              if (length != 0) {
            //                 const unsigned char *buffer =  data1.bytes; // bytes of the data received
            //                              [data appendBytes:buffer length:length]; // Appending the bytes in a mutable data
            //                              NSLog(@"string = %@",[[NSString alloc] initWithData:data encoding:NSUTF16StringEncoding]);
            //                              [[NSString alloc] initWithData:data encoding:NSUTF16StringEncoding];
            //              }


            if (advertisementData != nil &&
                [advertisementData objectForKey:@"kCBAdvDataLocalName"] != nil &&
                ![[advertisementData objectForKey:@"kCBAdvDataLocalName"] isEqual:@"Hesley"] &&
                ![[advertisementData objectForKey:@"kCBAdvDataLocalName"] containsString:@"HGauge"]) {
                @try {
                    if (peripheral != nil) {
                        [deviceList addObject:peripheral];
                    }
                } @catch (NSException *e) {
                    NSLog(@"Exception: %@", e);
                }

                NSDictionary *scannedDevice = @{
                        @"name": [advertisementData objectForKey:@"kCBAdvDataLocalName"],
                        @"address": peripheral.identifier.UUIDString,
                        @"rssi": RSSI,
                        @"sdkType": @1,
                };
                 
                NSLog(@"Value of rssi = %@", scannedDevice);
                if (isMovefitBracelet == YES) {
                    [channel invokeMethod:@"getDeviceList" arguments:scannedDevice];
                }
            }

        }
    }
    @catch (NSException *e) {
        NSLog(@"Exception: %@", e);
    }

}

- (void)stringFromData:(NSData *)dataValue {
    NSMutableData *data = [[NSMutableData alloc] init];

    NSUInteger length = dataValue.length;  // length of the data received
    if (length == 0) {
        // return nil;
    }
    const unsigned char *buffer = dataValue.bytes; // bytes of the data received
    [data appendBytes:buffer length:length]; // Appending the bytes in a mutable data
    NSLog(@"string = %@", [[NSString alloc] initWithData:data encoding:NSUTF16StringEncoding]);
    [[NSString alloc] initWithData:data encoding:NSUTF16StringEncoding]; // Returning a string received after converting data.

}


//for check that device is connected or not
- (Boolean)isConnected {

    if ([ZHBlePeripheral sharedUartManager].mConnected) {
        [[ZHBlePeripheral sharedUartManager] sportDataSource];
        [[ZHSendCmdTool shareIntance] synchronizeTime];
    }
    return [ZHBlePeripheral sharedUartManager].mConnected;
}

//on disconnect callback
- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral {

    //---------------------
    //After successfully connecting to Bluetooth, you need to transfer personal information to the device
    [[ZHBlePeripheral sharedUartManager] setMConnected:false];
    NSLog(@"disconnect", @"");
    if (resultForDisConnect != nil) {
        resultForDisConnect(@(true));
    }

}

//on connect callback
- (void)didConnectPeripheral:(CBPeripheral *)peripheral {


    //---------------------
    //After successfully connecting to Bluetooth, you need to transfer personal information to the device
    [[ZHBlePeripheral sharedUartManager] setMConnected:true];

    if (resultForConnect != nil) {
        resultForConnect(@(true));
    }

    @try {
        if (peripheral != nil) {
            NSDictionary *scannedDevice = @{
                    @"name": peripheral.name,
                    @"address": peripheral.identifier.UUIDString,
                    @"sdkType": @1,
            };
             
            NSLog(@"connect = %@", scannedDevice);
            [channel invokeMethod:@"onConnectIosDevice" arguments:scannedDevice];

            [[ZHBlePeripheral sharedUartManager] sportDataSource];
            [[ZHSendCmdTool shareIntance] synchronizeTime];


        }
    }
    @catch (NSException *e) {
        NSLog(@"Exception onConnectIosDevice : %@", e);
    }
}

//connect device
- (void)connectToDevice:(NSString *)deviceAddress sdkType:(int)sdkType {

    for (CBPeripheral *obj in deviceList) {
        if ([obj.identifier.UUIDString isEqualToString:deviceAddress]) {
            if (obj != nil) {
                //connect to device
                if (sdkType == 1) {
                    [[ZHBlePeripheral sharedUartManager] didDisconnect];
                    [ZHBlePeripheral sharedUartManager].mPeripheral = obj;
                    [[ZHBlePeripheral sharedUartManager] didConnect];
                } else if (sdkType == 2) {
                    [[YCBTProduct shared] connectDevice:obj callBack:^(Error_Code code) {
                        if (code == Error_Ok) {
                            NSLog(@"Connected");
                            if (resultForConnect != nil) {
                                resultForConnect([NSNumber numberWithBool:true]);


                            }
                            NSDictionary *scannedDevice = @{
                                    @"name": obj.name,
                                    @"address": obj.identifier.UUIDString,
                                    @"sdkType": @2,
                            };
                             NSLog(@"connect = %@", scannedDevice);
                            [channel invokeMethod:@"onConnectIosDevice" arguments:scannedDevice];
                        } else {
                            if (resultForConnect != nil) {
                                resultForConnect([NSNumber numberWithBool:false]);
                            }
                        }
                    }];
                    [[YCBTProduct shared] settingRealDataOpen:YES callback:^(Error_Code code,
                                                                             NSDictionary *_Nonnull
                                                                             result) {
                        if (code == Error_Ok) {
                            NSLog(@"Success");
                        }
                    }];
//                    [YCBTProduct.shared openTemperatureCalibration:0 TemperatureDecimal:0 callBack:^(Error_Code code, NSDictionary * _Nonnull result) {
//                        NSLog(@"%@", result);
//                    }];
                    [self getAllE66Data];
                }

            }
            break;
        }
    }

}

- (void)configureProcessingTask {
    if (@available
    (iOS
    13.0, *)) {
        [[BGTaskScheduler sharedScheduler] registerForTaskWithIdentifier:(@"com.healthGauge.synclocal") usingQueue:nil
                                                           launchHandler:^(BGTask *task) {

                                                               [self scheduleNotification];


                                                           }
        ];
    } else {
        // No fallback
    }
}

- (void)scheduleNotification {


}


- (void)scheduleProcessingTask {
    if (@available
    (iOS
    13.0, *)) {
        NSError *error = NULL;
        // cancel existing task (if any)
        // new task
        BGProcessingTaskRequest *request = [[BGProcessingTaskRequest alloc] initWithIdentifier:@"com.healthGauge.synclocal"];
        request.earliestBeginDate = [NSDate dateWithTimeIntervalSinceNow:5];
        BOOL success = [[BGTaskScheduler sharedScheduler] submitTaskRequest:request error:&error];
        if (!success) {
            NSLog(@"Failed to submit request: %@", error);
        } else {
            NSLog(@"Success submit request %@", request);
        }
    } else {
        // No fallback
    }
}

- (void)startHbandMeasurment:(int)sdkType {
    if (sdkType == 4) {
        [[VPBleCentralManage sharedBleManager].peripheralManage veepooSDKTestECGStart:(TRUE) testResult:^(
                VPTestECGState testECGState, NSUInteger testProgress,
                VPECGTestDataModel *testModel) {
        }];
    }
}

- (void)stopHBandMeasurment:(int)sdkType {
    if (sdkType == 4) {
        [[VPBleCentralManage sharedBleManager].peripheralManage veepooSDKTestECGStart:(false) testResult:^(
                VPTestECGState testECGState, NSUInteger testProgress,
                VPECGTestDataModel *testModel) {
        }];
    }
}

- (void)stopHbandScan:(int)sdkType {
    if (sdkType == 4) {
        [[VPBleCentralManage sharedBleManager] veepooSDKStopScanDevice];
    }
}


- (void)connectHbandToDevice:(NSString *)deviceAddress sdkType:(int)sdkType {

    for (VPPeripheralModel *obj in hBandDevices) {
        if ([obj.deviceAddress isEqualToString:deviceAddress]) {
            if (obj != nil) {
                //connect to device
                if (sdkType == 4) {

                    [[VPBleCentralManage sharedBleManager] veepooSDKConnectDevice:obj deviceConnectBlock:^(
                            DeviceConnectState connectState) {
                        if (connectState == BleConnecting) {
                            [[VPBleCentralManage sharedBleManager] veepooSDKSynchronousPasswordWithType:(VerifyPasswordType) password:(@"0000") SynchronizationResult:^(
                                    PasswordSynchronTpye result) {
                                if (result == PasswordReadSuccess) {
                                    if (resultForConnect != nil) {
                                        resultForConnect([NSNumber numberWithBool:true]);


                                    }
                                    NSDictionary *scannedDevice = @{
                                            @"name": obj.deviceName,
                                            @"address": obj.deviceAddress,
                                            @"sdkType": @4,
                                    };
                                     NSLog(@"connect = %@", scannedDevice);
                                    [channel invokeMethod:@"onConnectIosDevice" arguments:scannedDevice];
                                }
                            }];
                        }

                    }];
                }
                break;
            }
        }
    }
}

- (void)getAllE66Data {
    [[YCBTProduct shared] getDevInfo:^(Error_Code code, NSDictionary *_Nonnull result) {
        if (result) {
            NSInteger keyDevVersionNum = [result[@"keyDevVersionNum"]
                    intValue];
            NSInteger tPower = [result[@"keyDevBatteryNum"] integerValue];
            NSDictionary *deviceInfo = @{
                    @"power": [NSNumber numberWithInteger:tPower],
                    @"device_number": [NSNumber numberWithInteger:keyDevVersionNum],
            };
            [channel invokeMethod:@"onResponseDeviceInfo" arguments:deviceInfo];
        }
    }];

    [YCBTProduct.shared syncDataHistory:0x04
                               callback:^(Error_Code code, NSDictionary *_Nonnull result) {
                                   NSLog(@"%@", result);

                               }];

    [YCBTProduct.shared syncDataHistory:0x02
                               callback:^(Error_Code code, NSDictionary *_Nonnull result) {
                                   NSLog(@"%@", result);

                               }];

    [YCBTProduct.shared syncDataHistory:0x09
                               callback:^(Error_Code code, NSDictionary *_Nonnull result) {
                                   NSLog(@"%@", result);

                               }];

    [YCBTProduct.shared syncDataHistory:0x06
                               callback:^(Error_Code code, NSDictionary *_Nonnull result) {
                                   NSLog(@"%@", result);

                               }];

}

//on update bluetooth status
- (void)didUpdateBlueToothState:(CBCentralManager *)central {
    if ([self isConnected] == NO) {
        [[ZHBlePeripheral sharedUartManager] scanDevice];
    }
}

//device information
- (void)getDeviceNumber:(NSNumber *)deviceNumber andFirmwareVersion:(NSNumber *)firmwareVersion andDeviceVersion:(NSString *)deviceVersion andDeviceBattery:(NSNumber *)battery {
    NSLog(@"getDeviceNumber");
    NSDictionary *deviceInfo = @{
            @"power": battery,
            @"device_number": deviceNumber,
    };

    [channel invokeMethod:@"onResponseDeviceInfo" arguments:deviceInfo];
}

//sport data
- (void)getSportForDate:(NSString *)sportDate andStepData:(NSArray *)sportData andDistance:(CGFloat)distance andKcal:(CGFloat)kcal {


    NSDictionary *data = @{
            @"date": sportDate,
            @"data": sportData,
            @"calories": @(kcal),
            @"distance": @(distance),
            @"step": [sportData valueForKeyPath:@"@sum.intValue"]
    };
    NSLog(@"getSportForDate ", data);
    [channel invokeMethod:@"onResponseMotionInfo" arguments:data];
}

- (void)getHeartRateForDate:(NSString *)HRDate forHeartRateData:(NSArray *)HRData {
    NSLog(@"getSportForDate ", HRData);
    NSDictionary *hrDataInfo = @{
            @"data": HRData,
            @"date": HRDate,
    };
    [channel invokeMethod:@"onResponsePoHeartInfo" arguments:hrDataInfo];
}

//sleep information
- (void)getSleepForDate:(NSString *)sleepDate forTotalSleepTime:(NSString *)sleepTotalTime andForSleepTypeData:(NSArray *)typeDate {
    NSLog(@"getSleepForDate");
    NSDictionary *sleepInfo = @{
            @"date": sleepDate,
            @"sleepAllTime": sleepTotalTime,
            @"typeDate": typeDate,
            @"sdkType": @1,
    };

    [channel invokeMethod:@"onResponseSleepInfo" arguments:sleepInfo];
}


- (CGFloat)setUserHeight {
    return 160.0;
}

- (CGFloat)setUserWeight {
    return 45.0;
}

- (void)synchronousDataFinished {
    NSLog(@"Sync complete");
}


- (void)dfuProgressDidChangeFor:(NSInteger)part outOf:(NSInteger)totalParts to:(NSInteger)progress currentSpeedBytesPerSecond:(double)currentSpeedBytesPerSecond avgSpeedBytesPerSecond:(double)avgSpeedBytesPerSecond {
    NSLog(@"---part=%ld---totalParts=%ld---progress=%ld", (long) part, (long) totalParts,
          (long) progress);
}

- (void)findPhoneInstruction {
    NSLog(@"----Find phone");
}

/*
 * Set the bracelet wearing method (YES for left hand, NO for right hand) (if set to empty, YES)
 */
- (BOOL)setWearWay {
    //    NSLog(isWearOnLeft ? @"YES" : @"NO");
    return isWearOnLeft;
}

/*
 * Set user calibrated heart rate (if 0 or empty, default value: 70 bpm)
 */
- (int)setCalibrationHR {
    NSLog(@"setCalibrationHR %d", hrCalibration);
    return hrCalibration;
    //    return hrCalibration;
}

/*
 * Set user calibration high pressure (systolic pressure) (if 0 or empty, default value: 120 mmHg)
 */
- (int)setCalibrationSystolic; {
    NSLog(@"setCalibrationSystolic %d", sbpCalibration);
    return sbpCalibration;
    //    return sbpCalibration;
}

/*
 * Set user calibrated low pressure (diastolic pressure) (if 0 or empty, default value: 70 mmHg)
 */
- (int)setCalibrationDiastolic {
    NSLog(@"setCalibrationDiastolic %d", dbpCalibration);
    return dbpCalibration;
    //    return dbpCalibration;
}

- (void)begainOfflineDataTransfer {
    NSLog(@"----Start offline measurement");
}

- (void)getOfflineDataForDate:(NSString *)date andHeartRate:(int)HR andSystolic:(int)systolic andDiastolic:(int)diastolic andEcgData:(NSString *)data {
    NSLog(@"----Offline measurement time--%@", date);
}
//--------------------------------------------------------------------Connection part over here

//--------------------------------------------------------------------ECG And PPG Reding part starts from here

- (void)startMeasuarment {

    NSLog(@"startMeasuarment_1111");

    arrEcgData = [@[] mutableCopy];
    arrPpgData = [@[] mutableCopy];

    if (![ZHBlePeripheral sharedUartManager].mConnected) {
        return;
    }

    NSLog(@"startMeasuarment_1100");
    //It must be set to YES for the ECG to output the value and set to NO at the end.
    [ZHBlePeripheral sharedUartManager].ecgBool = YES;

    //Send ECG measurement instruction 0x01 is the start and 0x00 is the end
    [[ZHSendCmdTool shareIntance] sendEcgDataCmd:0x01];

    seconds = 32;

    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(beginTime) userInfo:nil repeats:YES];
}

- (void)getHrData {

    [YCBTProduct.shared syncDataHistory:0x06 callback:^(Error_Code code, NSDictionary *_Nonnull
                                                        result) {
        if (Error_Ok == code) {
            NSLog(@"getCurrentHeartRate %@", result);

            NSMutableArray *hrArray = [[NSMutableArray alloc] init];
            for (NSDictionary *data in result) {
                //  long timestamp = [data[@"keyStartTime"]longValue];
                NSDictionary *dataDic = @{
                        @"heartValue": data[@"keyHeartNum"],
                        // @"heartStartTime" : [NSNumber numberWithLong: timestamp],
                        @"heartStartTime": [self converTimstamp:[data[@"keyStartTime"] longValue] format:@"yyyy-MM-dd HH:mm:ss"],
                };
                [hrArray addObject:dataDic];
            }
            if (resultForHeartRate != nil) {
                resultForHeartRate(hrArray);
                resultForHeartRate = nil;
            }
            [channel invokeMethod:@"onGetHeartRateData" arguments:hrArray];

        }

    }];
}

- (void)beginTime {
    seconds--;


    if (seconds == 0) {
        [timer invalidate];
        timer = nil;
        [ZHBlePeripheral sharedUartManager].ecgBool = NO;
        [[ZHSendCmdTool shareIntance] sendEcgDataCmd:0x00];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:arrSaveData forKey:@"EcgData"];
        [defaults synchronize];

        [[ZHSendCmdTool shareIntance] sendBloodPressureParameterForGaoya:sbpCalibration andHeartRate:heartRate];

    }

}

- (void)stopMeasurement {
    seconds = 32;
    [timer invalidate];
    timer = nil;
    [ZHBlePeripheral sharedUartManager].ecgBool = NO;

    [[ZHSendCmdTool shareIntance] sendEcgDataCmd:0x00];
}

//---------------------
//Get ecg data
- (void)getFilterEcgData:(NSArray *)arrFilterEcgData andHeartRate:(int)HR Systolic:(int)systolic Diastolic:(int)diastolic HealthIndex:(int)healthIndex FatigueIndex:(int)fatigueIndex LoadIndex:(int)loadIndex QualityIndex:(int)qualityIndex heartIndex:(int)heartIndex {

    heartRate = HR;
    arrEcgData = arrFilterEcgData;

    if (ecgStartTime == 0) {
        ecgStartTime = (long long) ([[NSDate date] timeIntervalSince1970]);
    }
    long endTime = (long long) ([[NSDate date] timeIntervalSince1970]);

    for (int i = 0; i < arrFilterEcgData.count; i++) {
        NSNumber *number = arrFilterEcgData[i];
        //        number =  @([number intValue] * -1);
        NSDictionary *data = @{
                @"approxHr": [NSNumber numberWithInt:HR],
                @"approxSBP": [NSNumber numberWithInt:systolic],
                @"approxDBP": [NSNumber numberWithInt:diastolic],
                @"ecgPointY": number,
                @"hrv": [NSNumber numberWithInt:heartIndex],
                @"startTime": @(ecgStartTime),
                @"endTime": @(endTime),
                @"isLeadOff": @(isLeadOff),
                @"isPoorConductivity": @(isPoorConductivity),
        };


        [channel invokeMethod:@"onResponseEcgInfo" arguments:data];
    }
}

- (NSString *)timeInMiliSeconds {
    NSDate *date = [NSDate date];
    NSString *timeInMS = [NSString stringWithFormat:@"%lld", [@(floor(
            [date timeIntervalSince1970] * 1000)) longLongValue]];
    return timeInMS;
}

//---------------------
//Lead off tips
- (void)getLeedOff:(BOOL)leedOff {
    isLeadOff = leedOff;
    //    [channel invokeMethod:@"onGetLeadOff" arguments:[NSNumber numberWithBool:leedOff]];
}

//---------------------
//Tips for dry skin
- (void)getConductive:(BOOL)conductive {
    isPoorConductivity = conductive;
    //    [channel invokeMethod:@"onGetPoorConductivity" arguments:[NSNumber numberWithBool:conductive]];
}

//---------------------
//Get ppg data
- (void)getPpgData:(NSArray *)arrPpgData1 {

    arrPpgData = arrPpgData1;

    if (ppgStartTime == 0) {
        ppgStartTime = (long long) ([[NSDate date] timeIntervalSince1970]);
    }
    long endTime = (long long) ([[NSDate date] timeIntervalSince1970]);

    for (int i = 0; i < arrPpgData1.count; i++) {
        NSNumber *number = arrPpgData1[i];
        //         number =  @([number intValue] * -1);
        NSDictionary *data = @{
                @"point": number,
                @"startTime": @(ppgStartTime),
                @"endTime": @(endTime),
        };

        [channel invokeMethod:@"onResponsePpgInfo" arguments:data];
    }
}

// Get device configuration Data


//- (void)applicationWillEnterForeground:(UIApplication *)application{
//     if (@available(iOS 12.0, *)) {
//    NSUserActivity* user6Activity = [[NSUserActivity alloc] initWithActivityType:@"com.Meritopia.HealthGauge.FindBracelet4"];
//                       user6Activity.persistentIdentifier =   @"com.Meritopia.HealthGauge.FindBracelet4";
//                       user6Activity.title = [NSString stringWithFormat: @"Take Measurement"];
//                       user6Activity.eligibleForPrediction = YES;
//                       user6Activity.eligibleForSearch = YES;
//                       user6Activity.userInfo = @{@"ID" : @"We"};
//                       user6Activity.requiredUserInfoKeys = [NSSet setWithArray:user6Activity.userInfo.allKeys];
//                       user6Activity.suggestedInvocationPhrase = @"Take Measurement";
//
//    INUIAddVoiceShortcutViewController *vc = [[INUIAddVoiceShortcutViewController alloc] initWithShortcut: [[INShortcut alloc] initWithUserActivity:user6Activity]];
//               vc.delegate = self;
//              [self.window.rootViewController presentViewController:vc animated:YES completion:nil];
//     }
//}

//- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler
//{
//    // Check to make sure it's the correct activity type
//    if ([userActivity.activityType isEqualToString:@"com.unified.UR.Remote"])
//    {
//        // Extract the remote ID from the user info
//        NSString* id = [userActivity.userInfo objectForKey:@"ID"];
//
//        // Restore the remote screen...
//
//        return YES;
//    }
//    return NO;
//}
//--------------------------------------------------------------Weight Scale Device Implementaton-----------------------------------------------------
#pragma mark - BluetoothManagerDelegate of weight scale sdk

- (void)BluetoothManager:(INBluetoothManager *)manager didDiscoverDevice:(DeviceModel *)deviceModel {
    if (self.isAddPeripheraling == YES) return;
    self.isAddPeripheraling = YES;

    BOOL willAdd = YES;
    for (DeviceModel *model in self.peripheralArray) //avoid add the same device
    {
        if ([model.deviceAddress isEqualToString:deviceModel.deviceAddress] &&
            [model.deviceName isEqualToString:deviceModel.deviceName]) {
            willAdd = NO;
        }
    }

    if (willAdd) {
        [self.peripheralArray addObject:deviceModel];
    }


    if (deviceModel.acNumber.intValue < 2) { //0、1 is broadcast scale
        [[INBluetoothManager shareManager] handleDataForBroadScale:deviceModel];
    } else { //2、3 is Link scale
        [[INBluetoothManager shareManager] connectToLinkScale:deviceModel];
    }

    [channel invokeMethod:@"onDeviceConnected" arguments:@1];
    [[INBluetoothManager shareManager] stopBleScan];
    //[channel invokeMethod:@"weightScaleDeviceList" arguments:_peripheralArray];
    self.isAddPeripheraling = NO;
}

#pragma mark ============ BluetoothManagerDelegate ==============

- (void)BluetoothManager:(INBluetoothManager *)manager updateCentralManagerState:(BluetoothManagerState)state {
    switch (state) {
        case BluetoothManagerState_PowerOn: {

            break;
        }
        case BluetoothManagerState_PowerOff: {

            break;
        }
        case BluetoothManagerState_Disconnect: {

            break;
        }
        default:
            break;
    }
}

// change unit of weight scale device
- (void)ChangeUnit:(int)unit {
    [[WriteToBLEManager shareManager] write_To_Unit:unit - 1];
}

//only used for link scale
- (void)BluetoothManager:(INBluetoothManager *)manager didConnectDevice:(DeviceModel *)deviceModel {

}


#pragma mark - AnalysisBLEDataManagerDelegate

///Added by: Shahzad
///Added on: 18/09/2020
///this method is used to get status of weight scale device
- (void)AnalysisBLEDataManager:(AnalysisBLEDataManager *)analysisManager updateBleDataAnalysisStatus:(BleDataAnalysisStatus)bleDataAnalysisStatus {
    switch (bleDataAnalysisStatus) {
        case BleDataAnalysisStatus_SyncTimeSuccess: {

            //set unit(Check this method in demo)
            [self ChangeUnit:self.unit];

            //then sync user to be weighing
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                        [self syncWeighingUserToBle];
                    });

            //sync offline userlist(If no need offline history function, do not call this method)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                        // [self syncOfflineUserListToBle];
                    });

            //request history (If no need offline history function, do not call this method)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                        [[WriteToBLEManager shareManager] requestOfflineHistory];
                    });

            break;
        }
        case BleDataAnalysisStatus_SyncTimeFailed: {

            break;
        }
        case BleDataAnalysisStatus_SyncUserSuccess: {
            [channel invokeMethod:@"onDeviceConnected" arguments:@4];
            break;
        }
        case BleDataAnalysisStatus_SyncUserFailed: {
            [channel invokeMethod:@"onDeviceConnected" arguments:@6];
            break;
        }
        case BleDataAnalysisStatus_UnstableWeight: {
            [channel invokeMethod:@"onDeviceConnected" arguments:@2];

            break;
        }
        case BleDataAnalysisStatus_StableWeight: {
            [channel invokeMethod:@"onDeviceConnected" arguments:@3];

            break;
        }
        case BleDataAnalysisStatus_MeasureComplete: {
            [channel invokeMethod:@"onDeviceConnected" arguments:@3];
            break;
        }
        case BleDataAnalysisStatus_AdcError: {
            [channel invokeMethod:@"onDeviceConnected" arguments:@7];
            break;
        }
        case BleDataAnalysisStatus_LightOff: {
            [channel invokeMethod:@"onDeviceConnected" arguments:@5];
            break;
        }
        default:
            break;
    }
}

///Added by: Shahzad
///Added on: 17/09/2020
///this method is used to get details from weight scale device
- (void)AnalysisBLEDataManager:(AnalysisBLEDataManager *)analysisManager updateMeasureUserInfo:(UserInfoModel *)infoModel {

    float weight = infoModel.weightsum / pow(10, infoModel.weightOriPoint);
    NSLog(@"---infoModel:%@", infoModel);
    _appUser.weightKg = weight;
    NSDictionary *data;
    if (infoModel.measureStatus == MeasureStatus_Complete && infoModel.newAdc > 0) {
        adc = infoModel.newAdc;


        AlgorithmModel *algModel = [AlgorithmSDK getBodyfatWithWeight:weight adc:adc sex:_appUser.sex age:_appUser.age height:_appUser.height];

        NSLog(@"---adcValue:%f", infoModel.newAdc);


        BfsCalculateItem *item = [BfsCalculateSDK getBodyfatItemWithSex:_appUser.sex height:_appUser.height weight:weight bfr:algModel.bfr rom:algModel.rom pp:algModel.pp];

        data = @{
                @"date": infoModel.date,
                @"time": infoModel.time,
                @"weightsum": @(weight),
                @"BMI": @(algModel.bmi.floatValue),
                @"fatRate": @(algModel.bfr.floatValue),
                @"muscle": @(algModel.rom.floatValue),
                @"moisture": @(algModel.vwc.floatValue),
                @"boneMass": @(algModel.bm.floatValue),
                @"subcutaneousFat": @(algModel.sfr.floatValue),
                @"BMR": @(algModel.bmr.floatValue),
                @"proteinRate": @(algModel.pp.floatValue),
                @"visceralFat": @(algModel.uvi.floatValue),
                @"physicalAge": @(algModel.physicalAge.floatValue),
                @"standardWeight": @(item.standardWeight),
                @"weightControl": @(item.weightControl),
                @"fatMass": @(item.fatMass),
                @"weightWithoutFat": @(item.weightWithoutFat),
                @"muscleMass": @(item.muscleMass),
                @"proteinMass": @(item.proteinMass),
                @"fatlevel": @(item.fatlevel),

        };
    } else {
        data = @{
                @"weightsum": @(weight)
        };
    }
    //NSLog(@"bfr %@",@(algModel.bfr.floatValue));
    NSLog(@"---weightData:%@", data);
    [channel invokeMethod:@"onGetWeightScaleData" arguments:data];


}


- (NSMutableArray *)peripheralArray {
    if (_peripheralArray == nil) {
        _peripheralArray = [[NSMutableArray alloc] init];
    }
    return _peripheralArray;
}

#pragma mark- ECG算法处理回调 method

void (IOS_Ecg_Evt_Handle)(NTF_TYPE evt_type, void *params) {
    //TODO 实现HRV显示和洛伦茨画图

}

@end

