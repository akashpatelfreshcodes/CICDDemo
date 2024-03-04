//Class to read and write data in Health Kit
#import "GSHealthKitManager.h"
#import <HealthKit/HealthKit.h>
 
 
@interface GSHealthKitManager ()
 
@property (nonatomic, retain) HKHealthStore *healthStore;
 
@end
 
 
@implementation GSHealthKitManager
 
/// Added by: Akhil
/// Added on: Nov/13/2020
/// Shared object to call functions to read and write data in health kit
///Return -> shared instance of the class
+ (GSHealthKitManager *)sharedManager {
    static dispatch_once_t pred = 0;
    static GSHealthKitManager *instance = nil;
    dispatch_once(&pred, ^{
        instance = [[GSHealthKitManager alloc] init];
        instance.healthStore = [[HKHealthStore alloc] init];
    });
    return instance;
}

  /// Added by: Akhil
  /// Added on: Nov/13/2020
  /// function to check health app is available in device ir not
  ///Return -> Bool
 - (BOOL)isHealthDataAvailable {
   return [HKHealthStore isHealthDataAvailable];
    }

/// Added by: Akhil
 /// Added on: Nov/13/2020
 /// function to request authorization for reading and writing data from health kit
- (void)requestAuthorization {
    [self.healthStore authorizationStatusForType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight]];
    if ([HKHealthStore isHealthDataAvailable] == NO) {
        // If our device doesn't support HealthKit -> return.
        return;
    }
     
    
    NSMutableArray *readTypes = [[NSMutableArray alloc] initWithObjects:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],[HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],[HKCategoryType categoryTypeForIdentifier: HKCategoryTypeIdentifierSleepAnalysis],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRateVariabilitySDNN],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyTemperature],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierOxygenSaturation],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned], [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalEnergyBurned],nil];
    
    if (@available(iOS 14.0, *)) {
        [readTypes addObject: [HKElectrocardiogramType electrocardiogramType]];
    } else {
        // Fallback on earlier versions
    } // Works with NSMutableArray
    
       NSArray *writeTypes = [[NSArray alloc] initWithObjects:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],[HKCategoryType categoryTypeForIdentifier: HKCategoryTypeIdentifierSleepAnalysis],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRateVariabilitySDNN],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose],nil];
     
    [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithArray:writeTypes]
                                             readTypes:[NSSet setWithArray:readTypes] completion:^(BOOL success, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Not Authorized");
        }
    } ];
}
 
/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to read DOB from healthkit
///return-> DOB of user
- (NSDate *)readBirthDate {
    NSError *error;
    NSDate *dateOfBirth = [self.healthStore dateOfBirthComponentsWithError:&error];   // Convenience method of HKHealthStore to get date of birth directly.
     
    if (!dateOfBirth) {
        NSLog(@"Either an error occured fetching the user's age information or none has been stored yet. In your app, try to handle this gracefully.");
    }
     
    return dateOfBirth;
}

/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to write weight data in health kit
- (void)writeWeightSample:(double)weight startDate:(NSDate *)startDate
endDate:(NSDate *)endDate {
    if ([_healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]] == HKAuthorizationStatusSharingAuthorized ){
    // Each quantity consists of a value and a unit.
    HKUnit *kilogramUnit = [HKUnit gramUnitWithMetricPrefix:HKMetricPrefixKilo];
    HKQuantity *weightQuantity = [HKQuantity quantityWithUnit:kilogramUnit doubleValue:weight];
     
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    // For every sample, we need a sample type, quantity and a date.
    HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:startDate endDate:endDate];
     
    [self.healthStore saveObject:weightSample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"Error while saving weight (%f) to Health Store: %@.", weight, error);
        }
    
    }];
    }
}

/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to read steps data from health kit
/// params-> start date , end date and finish block
///return -> array of steps data
- (void)readStepsData:(NSString *)startDate
          endDate:(NSString *)endDate
          finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];
    // start date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    
    // end date
    NSDate *endingDate = [self dateWithTimeFromString: endDate];
    
    // Sample type
    HKSampleType *sampleStepCount = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];
    
    // valud
    //__block float dailyValue = 0;
    
    // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleStepCount
                                                           predicate: predicate
                                                               limit: 0
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {
                                                                  
                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);
                                                                  
                                                              } else {
                                                                 
                                                                  for(HKQuantitySample *samples in results)
                                                                  {
                                                                  //    dailyValue += [[samples quantity] doubleValueForUnit:[HKUnit countUnit]];
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                        NSDictionary *dictionary = @{
                                                                     @"value" : ([NSString stringWithFormat:@"%f", [[samples quantity] doubleValueForUnit:[HKUnit countUnit]]]),
                                                                     @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                                     @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                                     @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                                 };
                                                                      [data addObject:dictionary];
                                                                      }
                                                                  }
                                                                  
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
                            ];
    
    // execute query
    [self.healthStore executeQuery:query];
}


- (void)readBasalCalories:(NSString *)startDate
             endDate:(NSString *)endDate
        finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];

    // start date and end date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    NSDate *endingDate = [self dateWithTimeFromString: endDate];

    // Sample Type
    HKSampleType *sampleEnergyBurned = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalEnergyBurned];

    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];

    // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleEnergyBurned
                                                           predicate: predicate
                                                               limit: HKObjectQueryNoLimit
                                                     sortDescriptors: @[[NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO]]
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){

                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {

                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);

                                                              } else {
                                                                  for(HKQuantitySample *samples in results)
                                                                  {
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                                          NSDictionary *dictionary = @{
                                                                                  @"value" : ([NSString stringWithFormat:@"%f", [[samples quantity] doubleValueForUnit:[HKUnit kilocalorieUnit]]]),
                                                                                  @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                                                  @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                                                  @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                                          };
                                                                          [data addObject:dictionary];
                                                                      }
                                                                  }
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
    ];

    // execute query
    [self.healthStore executeQuery:query];
}


- (void)readActiveCalories:(NSString *)startDate
             endDate:(NSString *)endDate
        finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];

    // start date and end date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    NSDate *endingDate = [self dateWithTimeFromString: endDate];

    // Sample Type
    HKSampleType *sampleEnergyBurned = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];

    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];

    // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleEnergyBurned
                                                           predicate: predicate
                                                               limit: HKObjectQueryNoLimit
                                                     sortDescriptors: @[[NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO]]
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){

                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {

                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);

                                                              } else {
                                                                  for(HKQuantitySample *samples in results)
                                                                  {
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                                          NSDictionary *dictionary = @{
                                                                                  @"value" : ([NSString stringWithFormat:@"%f", [[samples quantity] doubleValueForUnit:[HKUnit kilocalorieUnit]]]),
                                                                                  @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                                                  @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                                                  @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                                          };
                                                                          [data addObject:dictionary];
                                                                      }
                                                                  }
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
    ];

    // execute query
    [self.healthStore executeQuery:query];
}


/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to read Body Mass data from health kit
/// params-> start date , end date and finish block
///return -> array of Body Mass data
- (void)readBodyMass:(NSString *)startDate
          endDate:(NSString *)endDate
          finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];
    // start date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    
    // end date
    NSDate *endingDate = [self dateWithTimeFromString: endDate];
    
    // Sample type
    HKQuantityType *sampleBodyMass = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    
    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];
    
    
    // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleBodyMass
                                                           predicate: predicate
                                                               limit: 0
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {
                                                                  
                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);
                                                                  
                                                              } else {
                                                                  
                                                                  for(HKQuantitySample *samples in results)
                                                                  {
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                        NSDictionary *dictionary = @{
                                                                     @"value" : ([NSString stringWithFormat:@"%f", [[samples quantity] doubleValueForUnit:[HKUnit gramUnit]]/1000]),
                                                                     @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                                     @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                                     @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                                 };
                                                                      [data addObject:dictionary];
                                                                  }
                                                                  }
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
                            ];
    
    // execute query
    [self.healthStore executeQuery:query];
}

/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to read height data from health kit
/// params-> start date , end date and finish block
///return -> array of height data
- (void)readHeightData:(NSString *)startDate
          endDate:(NSString *)endDate
          finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];
    // start date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    
    // end date
    NSDate *endingDate = [self dateWithTimeFromString:endDate];
    
    // Sample type
    HKSampleType *sampleHeightData = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    
    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];
    
    
    // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleHeightData
                                                           predicate: predicate
                                                               limit: 0
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {
                                                                  
                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);
                                                                  
                                                              } else {
                                                                  
                                                                  for(HKQuantitySample *samples in results)
                                                                  {
                                                                      
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                        NSDictionary *dictionary = @{
                                                                     @"value" : ([NSString stringWithFormat:@"%f", [[samples quantity] doubleValueForUnit:[HKUnit meterUnit]]]),
                                                                     @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                                     @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                                     @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                                 };
                                                                      [data addObject:dictionary];
                                                                  }
                                                                  }
                                                                  
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
                            ];
    
    // execute query
    [self.healthStore executeQuery:query];
}
/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to read sleep data from health kit
/// params-> start date , end date and finish block
///return -> array of sleep data
- (void)readSleepData:(NSString *)startDate
          endDate:(NSString *)endDate
          finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];
    // start date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    
    // end date
    NSDate *endingDate = [self dateWithTimeFromString:endDate];
    
    // Sample type
    HKSampleType *sampleSleepData = [HKSampleType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    
    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];
    
    // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleSleepData
                                                           predicate: predicate
                                                               limit: 0
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {
                                                                  
                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);
                                                                  
                                                              } else {
                                                                  
                                                                  for(HKCategorySample *samples in results)
                                                                  {
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                        NSDictionary *dictionary = @{
                                                            @"value" : ([NSString stringWithFormat:@"%ld", (long)[samples value]]),
                                                            @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                            @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                            @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                             
                                                                 };
                                                                      [data addObject:dictionary];
                                                                  }
                                                                  }
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
                            ];
     // execute query
    [self.healthStore executeQuery:query];
}

/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to read heart rate data from health kit
/// params-> start date , end date and finish block
///return -> array of heart rate data
- (void)readHeartRateData:(NSString *)startDate
          endDate:(NSString *)endDate
          finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];
    // start date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    
    // end date
    NSDate *endingDate = [self dateWithTimeFromString:endDate];
    
    // Sample type
    HKSampleType *sampleHeartRate = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];
        // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleHeartRate
                                                           predicate: predicate
                                                               limit: 0
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {
                                                                  
                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);
                                                                  
                                                              } else {
                                                                  
                                                                  for(HKQuantitySample *samples in results)
                                                                  {
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                        NSDictionary *dictionary = @{
                                                                     @"value" : ([NSString stringWithFormat:@"%f", [[samples quantity] doubleValueForUnit:[HKUnit unitFromString: @"count/min"]]]),
                                                                     @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                                     @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                                     @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                                 };
                                                                      [data addObject:dictionary];
                                                                  }
                                                                  }
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
                            ];
    
    // execute query
    [self.healthStore executeQuery:query];
}

/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to read SBP data from health kit
/// params-> start date , end date and finish block
///return -> array of SBP data
- (void)readSystolicBloodPressure:(NSString *)startDate
          endDate:(NSString *)endDate
          finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];
    // start date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    
    // end date
    NSDate *endingDate = [self dateWithTimeFromString:endDate];
    
    // Sample type
    HKSampleType *sampleSystolicBloodPressure = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic];
    
    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];
    
    
    
    // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleSystolicBloodPressure
                                                           predicate: predicate
                                                               limit: 0
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {
                                                                  
                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);
                                                                  
                                                              } else {
                                                                  
                                                                  for(HKQuantitySample *samples in results)
                                                                  {
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                        NSDictionary *dictionary = @{
                                                                     @"value" : ([NSString stringWithFormat:@"%f", [[samples quantity] doubleValueForUnit:[HKUnit millimeterOfMercuryUnit]]]),
                                                                     @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                                     @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                                     @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                                 };
                                                                      [data addObject:dictionary];
                                                                  }
                                                                  }
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
                            ];
    
    // execute query
    [self.healthStore executeQuery:query];
}

/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to read DBP data from health kit
/// params-> start date , end date and finish block
///return -> array of DBP data
- (void)readDiastolicBloodPressure:(NSString *)startDate
          endDate:(NSString *)endDate
          finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];
    // start date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    
    // end date
    NSDate *endingDate = [self dateWithTimeFromString:endDate];
    
    // Sample type
    HKSampleType *sampleDiastolicBloodPressure = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic];
    
    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];
    
    // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleDiastolicBloodPressure
                                                           predicate: predicate
                                                               limit: 0
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {
                                                                  
                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);
                                                                  
                                                              } else {
                                                                  
                                                                  for(HKQuantitySample *samples in results)
                                                                  {
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                                    NSDictionary *dictionary = @{
                                                                     @"value" : ([NSString stringWithFormat:@"%f", [[samples quantity] doubleValueForUnit:[HKUnit millimeterOfMercuryUnit]]]),
                                                                     @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                                     @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                                     @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                                 };
                                                                      [data addObject:dictionary];
                                                                  }
                                                                  }
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
                            ];
    
    // execute query
    [self.healthStore executeQuery:query];
}

/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to read HRV data from health kit
/// params-> start date , end date and finish block
///return -> array of HRV data
- (void)readHeartRateVariabilityData:(NSString *)startDate
          endDate:(NSString *)endDate
          finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];
    // start date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    
    // end date
    NSDate *endingDate = [self dateWithTimeFromString:endDate];
    
    // Sample type
    HKSampleType *sampleHeartRateVariabilityData = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRateVariabilitySDNN];
    
    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];
    
    // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleHeartRateVariabilityData
                                                           predicate: predicate
                                                               limit: 0
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {
                                                                  
                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);
                                                                  
                                                              } else {
                                                                  
                                                                  for(HKQuantitySample *samples in results)
                                                                  {
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                        NSDictionary *dictionary = @{
                                                                     @"value" : ([NSString stringWithFormat:@"%f", [[samples quantity] doubleValueForUnit:[HKUnit unitFromString: @"ms"]]]),
                                                                     @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                                     @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                                     @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                                 };
                                                                      [data addObject:dictionary];
                                                                  }
                                                                  }
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
                            ];
    
    // execute query
    [self.healthStore executeQuery:query];
}

/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to read walking and running distance data from health kit
/// params-> start date , end date and finish block
///return -> array of walking and running distance data
- (void)readWalkingAndRunningDistanceData:(NSString *)startDate
          endDate:(NSString *)endDate
          finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];
    // start date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    
    // end date
    NSDate *endingDate = [self dateWithTimeFromString:endDate];
    
    // Sample type
    HKSampleType *sampleDistanceData = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    
    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];
    
    // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleDistanceData
                                                           predicate: predicate
                                                               limit: 0
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {
                                                                  
                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);
                                                                  
                                                              } else {
                                                                  
                                                                  for(HKQuantitySample *samples in results)
                                                                  {
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                                    NSDictionary *dictionary = @{
                                                                     @"value" : ([NSString stringWithFormat:@"%f", [[samples quantity] doubleValueForUnit:[HKUnit meterUnit]]/1000]),
                                                                     @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                                     @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                                     @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                                 };
                                                                      [data addObject:dictionary];
                                                                  }
                                                                  }
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
                            ];
    
    // execute query
    [self.healthStore executeQuery:query];
}

/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to read Blood Glucose data from health kit
/// params-> start date , end date and finish block
 ///return -> array of Blood Glucose  data
- (void)readBloodGlucoseData:(NSString *)startDate
          endDate:(NSString *)endDate
          finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];
    // start date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    
    // end date
    NSDate *endingDate = [self dateWithTimeFromString:endDate];
    
    // Sample type
    HKSampleType *sampleStepCount = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose];
    
    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];
    // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleStepCount
                                                           predicate: predicate
                                                               limit: 0
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {
                                                                  
                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);
                                                                  
                                                              } else {
                                                                  
                                                                  for(HKQuantitySample *samples in results)
                                                                  {
                                                                  //    dailyValue += [[samples quantity] doubleValueForUnit:[HKUnit countUnit]];
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                        NSDictionary *dictionary = @{
                                                                     @"value" : ([NSString stringWithFormat:@"%f", [[samples quantity] doubleValueForUnit:[HKUnit unitFromString: @"mg/dl"]]]),
                                                                     @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                                     @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                                     @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                                 };
                                                                      [data addObject:dictionary];
                                                                  }
                                                                  }
                                                                  
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
                            ];
    
    // execute query
    [self.healthStore executeQuery:query];
}

/// Added by: Akhil
/// Added on: May/05/2021
/// function to read Body Temperature data from health kit
/// params-> start date , end date and finish block
 ///return -> array of  Body Temperature  data
- (void)readTemperatureData:(NSString *)startDate
          endDate:(NSString *)endDate
          finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];
    // start date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    
    // end date
    NSDate *endingDate = [self dateWithTimeFromString:endDate];
    
    // Sample type
    HKSampleType *sampleStepCount = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyTemperature];
    
    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];
    // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleStepCount
                                                           predicate: predicate
                                                               limit: 0
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {
                                                                  
                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);
                                                                  
                                                              } else {
                                                                  
                                                                  for(HKQuantitySample *samples in results)
                                                                  {
                                                                  //    dailyValue += [[samples quantity] doubleValueForUnit:[HKUnit countUnit]];
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                        NSDictionary *dictionary = @{
                                                                     @"value" : ([NSString stringWithFormat:@"%f", [[samples quantity] doubleValueForUnit:[HKUnit degreeCelsiusUnit]]]),
                                                                     @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                                     @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                                     @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                                 };
                                                                      [data addObject:dictionary];
                                                                  }
                                                                  }
                                                                  
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
                            ];
    
    // execute query
    [self.healthStore executeQuery:query];
}

/// Added by: Akhil
/// Added on: Oct/7/2021
/// function to read Oxygen Saturation data from health kit
/// params-> start date , end date and finish block
 ///return -> array of  Oxygen Saturation  data
- (void)readOxygenData:(NSString *)startDate
          endDate:(NSString *)endDate
          finishBlock:(void (^)(NSError *error, NSMutableArray *value))finishBlock
{
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray<NSDictionary *> alloc] init];
    // start date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    
    // end date
    NSDate *endingDate = [self dateWithTimeFromString:endDate];
    
    // Sample type
    HKSampleType *sampleStepCount = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierOxygenSaturation];
    
    // Predicate
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                               endDate:endingDate
                                                               options:HKQueryOptionStrictStartDate];
    // query
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: sampleStepCount
                                                           predicate: predicate
                                                               limit: 0
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                                              if (error) {
                                                                  
                                                                  NSLog(@"error");
                                                                  finishBlock(error, nil);
                                                                  
                                                              } else {
                                                                  
                                                                  for(HKQuantitySample *samples in results)
                                                                  {
                                                                 
                                                                      NSString *source = [[[samples sourceRevision] source] name];
                                                                      if ([source containsString:@"Health Gauge"] != YES) {
                                                        NSDictionary *dictionary = @{
                                                                     @"value" : ([NSString stringWithFormat:@"%f", [[samples quantity] doubleValueForUnit:[HKUnit countUnit]] * 100]),
                                                                     @"startTime" : ([NSString stringWithFormat:@"%@",[samples startDate]]),
                                                                     @"endTime": ([NSString stringWithFormat:@"%@",[samples endDate]]),
                                                                     @"valueId": ([NSString stringWithFormat:@"%@",[samples UUID]])
                                                                 };
                                                                      [data addObject:dictionary];
                                                                  }
                                                                  }
                                                                  
                                                                  finishBlock(nil, data);
                                                              }
                                                          });
                                                      }
                            ];
    
    // execute query
    [self.healthStore executeQuery:query];
}


/// Added by: Akhil
/// Added on: June/03/2021
/// function to read ECG data from health kit
/// params-> start date , end date and finish block
 ///return -> array of  ECG  data
- (void)readECGData:(NSString *)startDate
          endDate:(NSString *)endDate
          finishBlock:(void (^)(NSError *error, NSDictionary *value))finishBlock
{
    // start date
    NSDate *startingDate = [self dateWithTimeFromString: startDate];
    
    // end date
    NSDate *endingDate = [self dateWithTimeFromString:endDate];
    
    // Create the electrocardiogram sample type.
    if (@available(iOS 14.0, *)) {
        HKSampleType *ecgType = [HKObjectType electrocardiogramType];
   
        // Predicate
        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startingDate
                                                                   endDate:endingDate
                                                                   options:HKQueryOptionStrictStartDate];

        
        // query
        HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: ecgType
                                                               predicate: predicate
                                                                   limit: 0
                                                         sortDescriptors: nil
                                                          resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                              
                                                              dispatch_sync(dispatch_get_main_queue(), ^{
                                                                  if (error) {
                                                                      
                                                                      NSLog(@"error");
                                                                      finishBlock(error, nil);
                                                                      
                                                                  } else {
                                                                      
                                                                      NSArray<HKElectrocardiogram *> *ecgSamples = results;
                                                                      NSMutableArray *data = [[NSMutableArray alloc] init];
                                                                      if ([ecgSamples count] > 0){
                                                                          HKElectrocardiogram *ecgData = [ecgSamples lastObject];
                                                                          NSLog(@"%@", ecgData);
                                                                          int hr =  [[ecgData averageHeartRate] doubleValueForUnit:[HKUnit unitFromString: @"count/min"]];
                                                                          
                                                                          HKElectrocardiogramQuery *voltageQuery = [[HKElectrocardiogramQuery alloc]  initWithElectrocardiogram: ecgData dataHandler:^(HKElectrocardiogramQuery * _Nonnull query, HKElectrocardiogramVoltageMeasurement * _Nullable voltageMeasurement, BOOL done, NSError * _Nullable error) {
                                                                              
                                                                              if (error) {
                                                                                  
                                                                                  NSLog(@"error");
                                                                                  finishBlock(error, nil);
                                                                                  
                                                                              } else {
                                                                                  if (voltageMeasurement){
                                                                                      NSLog(@"voltageMeasurement");
                                                                                    
//                                                                                      NSDictionary *voltageDictionary = @{    @"value" : @([[voltageMeasurement quantityForLead: HKElectrocardiogramLeadAppleWatchSimilarToLeadI] doubleValueForUnit:[HKUnit voltUnit]]),
//
//                                                                                    @"startTime":@(voltageMeasurement.timeSinceSampleStart)
                                                                                      
//                                                                                    };
                                                                                [data addObject: @([[voltageMeasurement quantityForLead: HKElectrocardiogramLeadAppleWatchSimilarToLeadI] doubleValueForUnit:[HKUnit voltUnit]])];
                                                                                  }
                                                                                  if(done){
                                                                                      NSDictionary *ecgDataDictionary = @{
                                                                                                   @"hrValue" : @(hr),
                                                                                                
                                                                                                   @"ecgList": data
                                                                                               };
                                                                                    
                                                                                    finishBlock(nil, ecgDataDictionary);
                                                                                  }
                                                                              }
                                                                          }

                                                                                                                    ];
                                                                          // Execute the query.
                                                                          [self.healthStore executeQuery:voltageQuery];
                                                                          
                                                      
                                                                      }
                                                                      else{
                                                                          finishBlock(nil, nil);
                                                                      }
                                                                    }
                                                              });
                                                          }
                                ];
     // Execute the query.
        [self.healthStore executeQuery:query];
        
    }
    else {
       // Fallback on earlier versions
   }
    
}



/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to write steps data in health kit
/// params-> steps ,start date , end date and finish block

- (void)writeSteps:(NSInteger)steps
         startDate:(NSDate *)startDate
           endDate:(NSDate *)endDate
   withFinishBlock:(void (^)(NSError *error))finishBlock
{
    if ([_healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]] == HKAuthorizationStatusSharingAuthorized ){
    // write steps
    // quantity type :  steps
    HKQuantityType *stepsQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    // generate count unit
    HKUnit *unit = [HKUnit countUnit];
    // generate quantity object with step count value
    HKQuantity *quantity = [HKQuantity quantityWithUnit:unit doubleValue:steps];
    // generate quantity sample object
    HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:stepsQuantityType quantity:quantity startDate:startDate endDate:endDate];
    // save sample object using health-store object
    [self.healthStore saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
        
        NSLog(@"Saving steps to healthStore - success: %@", success ? @"YES" : @"NO");
        dispatch_sync(dispatch_get_main_queue(), ^{
            finishBlock(error);
        });
    }];
    }
}

/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to write BP data in health kit
/// params-> SBP,DBP ,start date , end date and finish block
- (void)saveBloodPressureIntoHealthStore:(NSInteger)Systolic Dysbp:(NSInteger)Diastolic startDate:(NSDate *)startDate
endDate:(NSDate *)endDate  withFinishBlock:(void (^)(NSError *error))finishBlock{
 if ([_healthStore authorizationStatusForType:[HKObjectType correlationTypeForIdentifier:
 HKCorrelationTypeIdentifierBloodPressure]] == HKAuthorizationStatusSharingAuthorized){
    
HKUnit *BloodPressureUnit = [HKUnit millimeterOfMercuryUnit];

HKQuantity *SystolicQuantity = [HKQuantity quantityWithUnit:BloodPressureUnit doubleValue:Systolic];
HKQuantity *DiastolicQuantity = [HKQuantity quantityWithUnit:BloodPressureUnit doubleValue:Diastolic];

HKQuantityType *SystolicType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic];
HKQuantityType *DiastolicType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic];

HKQuantitySample *SystolicSample = [HKQuantitySample quantitySampleWithType:SystolicType quantity:SystolicQuantity startDate:startDate endDate:endDate];
HKQuantitySample *DiastolicSample = [HKQuantitySample quantitySampleWithType:DiastolicType quantity:DiastolicQuantity startDate:startDate endDate:endDate];

NSSet *objects=[NSSet setWithObjects:SystolicSample,DiastolicSample, nil];
HKCorrelationType *bloodPressureType = [HKObjectType correlationTypeForIdentifier:
                                 HKCorrelationTypeIdentifierBloodPressure];
HKCorrelation *BloodPressure = [HKCorrelation correlationWithType:bloodPressureType startDate:startDate endDate:endDate objects:objects];
                                [self.healthStore saveObject:BloodPressure withCompletion:^(BOOL success, NSError *error) {
    if (!success) {
        dispatch_sync(dispatch_get_main_queue(), ^{
                   finishBlock(error);
               });
    }
   }];
 }
}

/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to write heart rate data in health kit
/// params-> heart rate ,start date , end date and finish block
- (void)writeHeartRateData:(NSInteger)heartRate startDate:(NSDate *)startDate
endDate:(NSDate *)endDate  withFinishBlock:(void (^)(NSError *error))finishBlock {
        if ([_healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]] == HKAuthorizationStatusSharingAuthorized ){
    HKUnit *heartRateCountUnit = [HKUnit countUnit];
    HKQuantity *beatsPerMinuteQuantity = [HKQuantity quantityWithUnit:[heartRateCountUnit unitDividedByUnit: HKUnit.minuteUnit] doubleValue:heartRate];
    HKQuantityType *heartRateType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    HKQuantitySample *beatsPerMinuteType = [HKQuantitySample quantitySampleWithType:heartRateType quantity:beatsPerMinuteQuantity startDate:startDate endDate:endDate];
    [self.healthStore saveObject:beatsPerMinuteType withCompletion:^(BOOL success, NSError *error) {
           if (!success) {
               dispatch_sync(dispatch_get_main_queue(), ^{
                          finishBlock(error);
                      });
           }
          }];
        }
       }

/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to write sleep data in health kit
/// params-> sleepType ,start date , end date and finish block
- (void)saveSleepAnalysis:(NSString *)sleepType startDate:(NSDate *)startDate
endDate:(NSDate *)endDate  withFinishBlock:(void (^)(NSError *error))finishBlock {
//    if ([_healthStore authorizationStatusForType:[HKCategoryType quantityTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]] == HKAuthorizationStatusSharingAuthorized) {
    HKCategoryType *sampleSleepData  = [HKSampleType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKCategorySample *sleepData;
    if ([sleepType  isEqual: @"inBed"]){
   sleepData = [HKCategorySample categorySampleWithType:sampleSleepData value:HKCategoryValueSleepAnalysisInBed startDate:startDate endDate:endDate ];
    } else
        if ([sleepType  isEqual: @"asleep"]){
   sleepData = [HKCategorySample categorySampleWithType:sampleSleepData value:HKCategoryValueSleepAnalysisAsleep startDate:startDate endDate:endDate ];
        }
        else {
   sleepData = [HKCategorySample categorySampleWithType:sampleSleepData value:HKCategoryValueSleepAnalysisAwake startDate:startDate endDate:endDate ];
        }
    
     [self.healthStore saveObject:sleepData withCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                           finishBlock(error);
                       });
               }
           }];
   //  }
        }
/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to write distance data in health kit
/// params-> distance ,start date , end date and finish block
- (void)saveDistance:(double)distanceRecorded startDate:(NSDate *)startDate
endDate:(NSDate *)endDate  withFinishBlock:(void (^)(NSError *error))finishBlock {
    if ([_healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning]] == HKAuthorizationStatusSharingAuthorized ){
     // Set the quantity type to the running/walking distance.
    HKQuantityType *distanceType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
     
     // Set the unit of measurement to miles.
    
    //HKQuantity *distanceQuantity = HKQuantity(unit: HKUnit.mileUnit(), doubleValue: distanceRecorded)
    HKQuantity *distanceQuantity = [HKQuantity quantityWithUnit:HKUnit.meterUnit doubleValue:distanceRecorded];
     
     // Set the official Quantity Sample.
    HKQuantitySample *distance = [HKQuantitySample quantitySampleWithType:distanceType quantity:distanceQuantity startDate:startDate endDate:endDate];
     
      [self.healthStore saveObject:distance withCompletion:^(BOOL success, NSError *error) {
               if (!success) {
                   dispatch_sync(dispatch_get_main_queue(), ^{
                              finishBlock(error);
                          });
                   
               }
              }];
    }
           }

/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to write Blood Glucose data in health kit
/// params-> blood glucodse ,start date , end date and finish block
- (void)saveBloodGlucose:(NSInteger)bloodGlucose startDate:(NSDate *)startDate
   endDate:(NSDate *)endDate  withFinishBlock:(void (^)(NSError *error))finishBlock {
             
    HKQuantityType *glucoseType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose];

    HKQuantity *glucoseQuantity =[HKQuantity quantityWithUnit:[[HKUnit moleUnitWithMetricPrefix:HKMetricPrefixMilli molarMass: HKUnitMolarMassBloodGlucose] unitDividedByUnit:HKUnit.literUnit] doubleValue:bloodGlucose];
    HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:glucoseType quantity:glucoseQuantity startDate:startDate endDate:endDate];
   
   
      [self.healthStore saveObject:sample withCompletion:^(BOOL success, NSError *error) {
               if (!success) {
                   dispatch_sync(dispatch_get_main_queue(), ^{
                              finishBlock(error);
                          });
                }
              }];
           }


/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to convert date from string
/// reture-> date
- (NSDate *)dateFromString:(NSString *)dateString
{
    NSString *dt_format_string = @"yyyy-MM-dd";
    NSDateFormatter *dtFormat = [[NSDateFormatter alloc]init];
    [dtFormat setDateFormat:dt_format_string];
//    NSCalendar *gregorian = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
//    dtFormat.calendar = gregorian;
//    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
//    dtFormat.locale = enUSPOSIXLocale;
   // dtFormat.locale = NSLocale.currentLocale;
    NSDate *date = [dtFormat dateFromString:dateString];
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate: date];
    return [NSDate dateWithTimeInterval: seconds sinceDate: date];
    //return date;
}
  
/// Added by: Akhil
/// Added on: Nov/13/2020
/// function to convert date with time from string
/// reture-> date with time
- (NSDate *)dateWithTimeFromString:(NSString *)dateString
{

    NSDateFormatter *dtFormat = [[NSDateFormatter alloc] init];
    [dtFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    //[dtFormat setDateFormat:@"yyyy-MM-dd"];
    NSDate *date =[[NSDate alloc]init];
    date = [dtFormat dateFromString:dateString];
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate: date];
    //return [NSDate dateWithTimeInterval: seconds sinceDate: date];
    return date;
}
 @end
