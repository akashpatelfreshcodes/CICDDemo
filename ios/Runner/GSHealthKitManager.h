#import <UIKit/UIKit.h>
 
@interface GSHealthKitManager : NSObject
 
+ (GSHealthKitManager *)sharedManager;
 
- (void)requestAuthorization;
 
- (NSDate *)readBirthDate;
- (void)writeWeightSample:(double)weight startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
- (void)readStepsData:(NSString *)startDate endDate: (NSString *)endDate finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readBodyMass:(NSString *)startDate endDate:(NSString *)endDate finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readActiveCalories:(NSString *)startDate endDate:(NSString *)endDate finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readBasalCalories:(NSString *)startDate endDate:(NSString *)endDate finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readHeightData:(NSString *)startDate endDate:(NSString *)endDate finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readSleepData:(NSString *)startDate endDate:(NSString *)endDate finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readHeartRateData:(NSString *)startDate endDate:(NSString *)endDate finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readSystolicBloodPressure:(NSString *)startDate endDate:(NSString *)endDate finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readDiastolicBloodPressure:(NSString *)startDate endDate:(NSString *)endDate finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readHeartRateVariabilityData:(NSString *)startDate endDate:(NSString *)endDate finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readWalkingAndRunningDistanceData:(NSString *)startDate endDate:(NSString *)endDate finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readBloodGlucoseData:(NSString *)startDate
          endDate:(NSString *)endDate
                 finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readTemperatureData:(NSString *)startDate
          endDate:(NSString *)endDate
                 finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readOxygenData:(NSString *)startDate
          endDate:(NSString *)endDate
                 finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock;
- (void)readECGData:(NSString *)startDate
          endDate:(NSString *)endDate
        finishBlock:(void (^)(NSError *error, NSDictionary *value))finishBlock;
- (void)writeSteps:(NSInteger)steps startDate:(NSDate *)startDate endDate:(NSDate *)endDate
   withFinishBlock:(void (^)(NSError *error))finishBlock;
- (NSDate *)dateFromString:(NSString *)dateString;
- (BOOL)isHealthDataAvailable;
- (void)saveBloodPressureIntoHealthStore:(NSInteger)Systolic Dysbp:(NSInteger)Diastolic startDate:(NSDate *)startDate endDate:(NSDate *)endDate  withFinishBlock:(void (^)(NSError *error))finishBlock;
- (void)writeHeartRateData:(NSInteger)heartRate startDate:(NSDate *)startDate endDate:(NSDate *)endDate  withFinishBlock:(void (^)(NSError *error))finishBlock;
- (void)saveSleepAnalysis:(NSString *)sleepType startDate:(NSDate *)startDate endDate:(NSDate *)endDate  withFinishBlock:(void (^)(NSError *error))finishBlock;
- (void)saveDistance:(double)distanceRecorded startDate:(NSDate *)startDate endDate:(NSDate *)endDate  withFinishBlock:(void (^)(NSError *error))finishBlock;
- (void)saveBloodGlucose:(NSInteger)bloodGlucose startDate:(NSDate *)startDate endDate:(NSDate *)endDate  withFinishBlock:(void (^)(NSError *error))finishBlock;
- (NSDate *)dateWithTimeFromString:(NSString *)dateString;
@end
