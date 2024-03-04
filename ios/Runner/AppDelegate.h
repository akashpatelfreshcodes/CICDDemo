#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import "ZHBlePeripheral.h"
#import "ZHSendCmdTool.h"
#import "YCBTProduct.h"

@interface AppDelegate : FlutterAppDelegate <ZHBleSportDataSource,ZHBlePeripheralDelegate,ZHBleHealthDataSource>

@property (nonatomic, weak) id <ZHBleHealthDataSource> delegate;
+ (AppDelegate *)sharedManager;
 
- (void)requestAuthorization;
 
- (NSDate *)readBirthDate;
- (void)writeWeightSample:(CGFloat)weight;
@end

