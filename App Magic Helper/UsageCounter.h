//
//  UsageCounter.h
//  App Magic
//
//  Created by Vlad Alexa on 7/18/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RemoteListener;
@class AchievementsTracker;

@interface UsageCounter : NSObject
{
    RemoteListener *remoteListener;
    AchievementsTracker *achievementsTracker;
    NSMutableDictionary *activeList;
    NSMutableDictionary *passiveList;
    NSMutableDictionary *usesList;
    NSMutableDictionary *lastUseDateList;
    NSMutableString *tracking;
    NSDate *trackingActiveSince;
    NSDate *trackingPassiveSince;
    NSDate *lastEventDate;
    NSTimer *loopTimer;
}

-(void)terminate;

-(void)timerLoop:(id)sender;

-(NSString *)machineSerial;


@end
