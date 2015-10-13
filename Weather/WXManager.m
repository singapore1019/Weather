//
//  WXManager.m
//  Weather
//
//  Created by Hu Dan 胡丹 on 15/9/10.
//  Copyright (c) 2015年 Hu Dan 胡丹. All rights reserved.
//

#import "WXManager.h"
#import "WXClient.h"
#import <TSMessages/TSMessage.h>

@interface WXManager()
// 1
@property (nonatomic, strong, readwrite) WXCondition *currentCondition;
@property (nonatomic, strong, readwrite) CLLocation *currentLocation;
@property (nonatomic, strong, readwrite) NSArray *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray *dailyForecast;

// 2
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) WXClient *client;
@end

@implementation WXManager

+ (instancetype)sharedManager {
    static id _sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}


- (id)init{
    if (self == [super init]) {
        _locationManager = [[CLLocationManager alloc]init];
        _locationManager.delegate = self;
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 8)
        {
            //获取授权认证 由于IOS8中定位的授权机制改变 需要进行手动授权
            [_locationManager requestAlwaysAuthorization];
            [_locationManager requestWhenInUseAuthorization];
        }

//        _currentCondition = [[WXCondition alloc]init];
        _client = [[WXClient alloc]init];
        
        
        [[[[RACObserve(self, currentLocation) ignore:nil]
        flattenMap:^RACStream *(CLLocation *newLocation) {
            return [RACSignal merge:@[
                                      [self updateCurrentConditions],
                                      [self updateDailyForecast],
                                      [self updateHourlyForecast]
                                      ]];
        }]deliverOn:RACScheduler.mainThreadScheduler]
        subscribeError:^(NSError *error) {
            [TSMessage showNotificationWithTitle:@"Error"
                                        subtitle:@"There was a problem fetching the latest weather."
                                            type:TSMessageNotificationTypeError];
    
        }];
    }
    return self;

}


- (void)findCurrentLocation {
    self.isFirstUpdate = YES;
    [self.locationManager startUpdatingLocation];
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    // 1
    if (self.isFirstUpdate) {
        self.isFirstUpdate = NO;
        return;
    }
    
    CLLocation *location = [locations lastObject];
    
    // 2
    if (location.horizontalAccuracy > 0) {
        // 3
        self.currentLocation = location;
        [self.locationManager stopUpdatingLocation];
    }
}

- (RACSignal *)updateCurrentConditions {
    return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate] doNext:^(WXCondition *condition) {
        self.currentCondition = condition;
    }];
}
    
- (RACSignal *)updateHourlyForecast {
    return [[self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.hourlyForecast = conditions;
    }];
}
    
- (RACSignal *)updateDailyForecast {
    return [[self.client fetchDailyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.dailyForecast = conditions;
    }];
}
    
@end
