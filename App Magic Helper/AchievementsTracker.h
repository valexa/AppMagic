//
//  AchievementsTracker.h
//  App Magic Helper
//
//  Created by Vlad Alexa on 2/9/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

@interface AchievementsTracker : NSObject <CLLocationManagerDelegate,NSUserNotificationCenterDelegate>
{
    NSArray *achievements;
    NSMutableDictionary *appTotals;
    NSMutableDictionary *customTotals;
    
    CLLocationManager *locationManager;
    CLLocation *location;
    BOOL didLaunch;
}

-(void)counterLoop;

@end
