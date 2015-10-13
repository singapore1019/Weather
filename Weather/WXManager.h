//
//  WXManager.h
//  Weather
//
//  Created by Hu Dan 胡丹 on 15/9/10.
//  Copyright (c) 2015年 Hu Dan 胡丹. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "WXCondition.h"

@import CoreLocation;

@interface WXManager : NSObject<CLLocationManagerDelegate>

// 2
+ (instancetype)sharedManager;

// 3
@property (nonatomic, strong, readonly) CLLocation *currentLocation;
@property (nonatomic, strong, readonly) WXCondition *currentCondition;
@property (nonatomic, strong, readonly) NSArray *hourlyForecast;
@property (nonatomic, strong, readonly) NSArray *dailyForecast;

// 4
- (void)findCurrentLocation;

@end
