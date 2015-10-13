//
//  WXClient.m
//  Weather
//
//  Created by Hu Dan 胡丹 on 15/9/10.
//  Copyright (c) 2015年 Hu Dan 胡丹. All rights reserved.
//

#import "WXClient.h"
#import "WXCondition.h"
#import "WXDailyForecast.h"
#import <MJExtension/MJExtension.h>

@interface WXClient()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation WXClient

- (instancetype)init{
    if (self == [super init]) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

- (RACSignal *)fetchJSONFromURL:(NSURL *)url{
    NSLog(@"Fetching:%@",url.absoluteString);
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:[NSURLRequest requestWithURL:url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (! error) {
                NSError *jsonError = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
                if (! jsonError) {
                    // 1
                    [subscriber sendNext:json];
                }
                else {
                    // 2
                    [subscriber sendError:jsonError];
                } 
            } 
            else { 
                // 2 
                [subscriber sendError:error]; 
            } 
            
            // 3 
            [subscriber sendCompleted]; 

        }];
        [dataTask resume];
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
    }]
    doError:^(NSError *error) {
        NSLog(@"%@",error);
    }]
    ;

}
- (RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate{
    // 1
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&units=imperial",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // 3
        [WXCondition setupReplacedKeyFromPropertyName:^NSDictionary *{
            return @{
                     @"date": @"dt",
                     @"locationName": @"name",
                     @"humidity": @"main.humidity",
                     @"temperature": @"main.temp",
                     @"tempHigh": @"main.temp_max",
                     @"tempLow": @"main.temp_min",
                     @"sunrise": @"sys.sunrise",
                     @"sunset": @"sys.sunset",
                     @"conditionDescription": @"weather.description",
                     @"condition": @"weather.main",
                     @"icon": @"weather.icon",
                     @"windBearing": @"wind.deg",
                     @"windSpeed": @"wind.speed"
                     };
            
        }];

        
//        return [MTLJSONAdapter modelOfClass:[WXCondition class] fromJSONDictionary:json error:nil];
//        WXCondition *c = [WXCondition objectWithKeyValues:json];
        return [WXCondition objectWithKeyValues:json];
    }];

}
- (RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate{
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast?lat=%f&lon=%f&units=imperial&cnt=12",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 1
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // 2
        RACSequence *list = [json[@"list"] rac_sequence];
        
        // 3
        return [[list map:^(NSDictionary *item) {
            // 4
//            return [MTLJSONAdapter modelOfClass:[WXCondition class] fromJSONDictionary:item error:nil];
            [WXCondition setupReplacedKeyFromPropertyName:^NSDictionary *{
                return @{
                         @"date": @"dt",
                         @"locationName": @"name",
                         @"humidity": @"main.humidity",
                         @"temperature": @"main.temp",
                         @"tempHigh": @"main.temp_max",
                         @"tempLow": @"main.temp_min",
                         @"sunrise": @"sys.sunrise",
                         @"sunset": @"sys.sunset",
                         @"conditionDescription": @"weather.description",
                         @"condition": @"weather.main",
                         @"icon": @"weather.icon",
                         @"windBearing": @"wind.deg",
                         @"windSpeed": @"wind.speed"
                         };

            }];
            
            return [WXCondition objectWithKeyValues:json];
            // 5
        }] array];
    }];
}
- (RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate{
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast/daily?lat=%f&lon=%f&units=imperial&cnt=7",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Use the generic fetch method and map results to convert into an array of Mantle objects
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // Build a sequence from the list of raw JSON
        RACSequence *list = [json[@"list"] rac_sequence];
        
        // Use a function to map results from JSON to Mantle objects
        return [[list map:^(NSDictionary *item) {
            
            [WXDailyForecast setupReplacedKeyFromPropertyName:^NSDictionary *{
                return @{
                         @"date": @"dt",
                         @"humidity": @"humidity",
                         @"temperature": @"temp.day",
                         @"conditionDescription": @"weather.description",
                         @"condition": @"weather.main",
                         @"icon": @"weather.icon",
                         @"tempHigh": @"temp.max",
                         @"tempLow": @"temp.min"
                        };
                
            }];

//            return [MTLJSONAdapter modelOfClass:[WXDailyForecast class] fromJSONDictionary:item error:nil];
//            WXDailyForecast *w = [WXDailyForecast objectWithKeyValues:item];
            return [WXDailyForecast objectWithKeyValues:item];
        }] array];
    }]; 

}

@end
