//
//  AppUser.h
//  Runner
//
//  Created by daffolapmac-140 on 21/09/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppUser : NSObject


@property (nonatomic, assign) float weightKg;
/**Be Noted:
 male: 1 female: 2
 */
@property (nonatomic, assign) int id;
@property (nonatomic, assign) int sex;
@property (nonatomic, assign) int age;
@property (nonatomic, assign) int height;

@end

NS_ASSUME_NONNULL_END
