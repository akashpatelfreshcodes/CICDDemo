//
//  CBPeripheral+RSSI.h
//  SmartHealth
//
//  Created by yc on 2019/4/1.
//  Copyright © 2019 yucheng. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBPeripheral (RSSI)


- (void)setCBPeripheralRSSI:(NSNumber *)rssi;
- (NSNumber *)getRSSI;

- (void)setCBPeripheralMac:(NSString *)devMac;
- (NSString *)getDeviceMac;

@end

NS_ASSUME_NONNULL_END
