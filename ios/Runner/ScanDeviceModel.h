//
//  NSObject+ScanDeviceModel.h
//  Runner
//
//  Created by EbitNHP-i1 on 11/03/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScanDeviceModel : NSObject

@property (weak, nonatomic) CBPeripheral* peripheral;
@property (weak, nonatomic) NSString* name;
@property (weak, nonatomic) NSString* address;
@property (weak, nonatomic) NSNumber* RSSI;

@end

NS_ASSUME_NONNULL_END
