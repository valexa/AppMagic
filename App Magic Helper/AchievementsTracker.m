//
//  AchievementsTracker.m
//  App Magic Helper
//
//  Created by Vlad Alexa on 2/9/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import "AchievementsTracker.h"

#import "CloudFunctions.h"

#import "DataFunctions.h"

#import "MiscFunctions.h"

@implementation AchievementsTracker

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        center.delegate = self;
    
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        [locationManager setPurpose:@"Your current location will be used for the first hop"];
        [locationManager startUpdatingLocation];
        
        NSString *file = [[NSBundle mainBundle] pathForResource:@"achievments" ofType:@""];
        NSError *err = nil;
        NSString *string = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:&err];
        if (err)
        {
            NSLog(@"ERROR Loading achievements");
        }else{
            achievements = [MiscFunctions plistToArray:string];
            NSLog(@"Loaded %lu achievements",(unsigned long)[achievements count]);
        }
        
        appTotals = [NSMutableDictionary dictionaryWithCapacity:1];
        customTotals = [NSMutableDictionary dictionaryWithCapacity:1];
        
        [self getAppTotals];

    }
    
    return self;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if ([notification.title isEqualToString:@"New achievement"])
    {
        if (didLaunch) return; //dont launch it multiple times
        NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@a",NSTemporaryDirectory()]];
        BOOL opened = [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:url] withAppBundleIdentifier:@"com.vladalexa.appmagic" options:NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync additionalEventParamDescriptor:nil launchIdentifiers:NULL];
        if (!opened) [MiscFunctions deliverNotification:@"Communication error" text:@"Helper was prevented to communicate achievements to main application."];
        didLaunch = YES;
    }else{
        NSLog(@"Unhandled notification %@",notification.title);
    }
}

-(void)getAppTotals
{
    [appTotals removeAllObjects];
    
    NSURL *root = [CloudFunctions getDocsPathFor:@"" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
    
    [CloudFunctions scanDirectory:root completionHandler: ^(NSOrderedSet *foundFiles) {
        if (!foundFiles) return;
        
        NSDictionary *db = [DataFunctions dataAtPath:root list:foundFiles];
        
        NSDictionary *appsDict = [DataFunctions appsForMachine:@"All Machines" db:db];
        
        NSURL *dbURL = [NSURL fileURLWithPath:[[root path] stringByAppendingPathComponent:@"database.plist"]];
        NSDictionary *database = [CloudFunctions coordonatedReadURL:dbURL];
        
        for (NSString *bid in appsDict)
        {
            NSNumber *uses = [[appsDict objectForKey:bid] objectForKey:@"uses"];
            NSNumber *active = [[appsDict objectForKey:bid] objectForKey:@"active"];
            NSNumber *passive = [[appsDict objectForKey:bid] objectForKey:@"passive"];
            NSDate *lastUse = [[[database objectForKey:@"appsdb"] objectForKey:bid] objectForKey:@"lastuse"];
            NSDate *firstUse = [[[database objectForKey:@"appsdb"] objectForKey:bid] objectForKey:@"firstuse"];//will be nil many times
            NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:active,@"active",passive,@"passive",uses,@"uses",lastUse,@"lastuse",firstUse,@"firstuse", nil];
            [appTotals setObject:data forKey:bid];
        }
        
    }];
}

-(void)counterLoop
{
    didLaunch = NO;
    [self getAppTotals];
    //[locationManager startUpdatingLocation];
    //[self performSelector:@selector(locationCheck) withObject:nil afterDelay:5];
    [self performSelector:@selector(updateAchievsProgress) withObject:nil afterDelay:60];
}


-(void)locationCheck
{
    if (location == nil)
    {
        [[NSAlert alertWithMessageText:@"You did not permit location access" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Location access is needed for achievements"] runModal];
    }
}


#pragma mark CLLocationManager delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"Location: %@", [newLocation description]);
    location = newLocation;
    [manager stopUpdatingLocation];
}

#pragma mark award

-(NSInteger)numberOfHoursPastMidnight
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:[NSDate date]];
    [components setHour:0];
    [components setMinute:0];
    NSDate *midnight = [[NSCalendar currentCalendar] dateFromComponents:components];
    NSDateComponents *diff = [[NSCalendar currentCalendar] components:NSHourCalendarUnit fromDate:midnight toDate:[NSDate date] options:0];
    return [diff hour];
}

-(void)factorTime:(NSString*)time
{
    if ([time isEqualToString:@"midnight"]) {
        
    }else if ([time isEqualToString:@"nye"]) {
        
    }else if ([time isEqualToString:@"wwdc"]) {
        
    }
}

-(NSDictionary*)usageForApp:(NSString*)bid withFactors:(NSDictionary*)achiev
{
    NSDictionary *ret = [appTotals objectForKey:bid];
    
    //factor time component
    NSString *time = [achiev objectForKey:@"time"];
    if ([time length] > 0)
    {
        return [customTotals objectForKey:time];
    }
    
    //factor with location component
    NSString *loc = [achiev objectForKey:@"location"];
    if ([loc length] > 0) {
        return [customTotals objectForKey:loc];
    }
    
    //factor with movement component
    NSInteger movement = [[achiev objectForKey:@"movement"] intValue];
    if (movement > 0) {
        return [customTotals objectForKey:[NSString stringWithFormat:@"%li km before",(long)movement]];
    }
    
    return ret;
}


-(float)achievementsProgressFor:(NSDictionary*)ac
{
    float ret = 0.0;
    float passiveTotal = 0.0;
    float activeTotal = 0.0;
    
    NSArray *apps = [[ac objectForKey:@"including"] componentsSeparatedByString:@", "];
    if ([[ac objectForKey:@"including"] isEqualToString:@""]) apps = [appTotals allKeys]; //any app achiev
    
    if ([[ac objectForKey:@"include count"] intValue] < 1 &&  [[ac objectForKey:@"count"] intValue] < 1)
    {
        NSLog(@"Achiev with neither count %@",[ac objectForKey:@"name"]);
        return 0.0;
    }
    
    //factor include count
    NSInteger includeCount = [[ac objectForKey:@"include count"] integerValue];
    if (includeCount > 0)
    {
        NSInteger count = 0;
        for (NSString *bid in apps) if ([[appTotals allKeys] containsObject:bid]) count++;
        if (count < includeCount) return 0.0; //under count
    }
    
    for (NSString *bid in apps)
    {
        //factor excluding
        if (![[ac objectForKey:@"excluding"] isEqualToString:@""])
        {
            NSArray *exclude = [[ac objectForKey:@"excluding"] componentsSeparatedByString:@", "];
            for (NSString *bid in exclude)
            {
                float active = [[[appTotals objectForKey:bid] objectForKey:@"active"] floatValue];
                if (active > 3600)  return 0.0; //found excluded with usage over 1 hour
            }
        }
        
        float minSeconds = [[ac objectForKey:@"count"] floatValue]*60*60;
        if (minSeconds == 0) return 1.0;
        
        NSDictionary *appData = [self usageForApp:bid withFactors:ac];
        
        if ([appData count] == 0) return 0.0;
        float passive = [[appData objectForKey:@"passive"] floatValue];
        float active = [[appData objectForKey:@"active"] floatValue];
        
        NSString *type = [ac objectForKey:@"type"];
        if ([type rangeOfString:@" AND" options:NSCaseInsensitiveSearch].location == NSNotFound)
        {
            if (passive > passiveTotal) passiveTotal = passive; //get the highest
            if (active > activeTotal) activeTotal = active; //get the highest
        }else{
            passiveTotal += passive;
            activeTotal += active;
        }
        
        if ([type isEqualToString:@"any"])
        {
            //return greatest of the two
            if (passiveTotal > activeTotal)
            {
                ret = passiveTotal/minSeconds;
            }else{
                ret = activeTotal/minSeconds;
            }
        }else if ([type rangeOfString:@"passive" options:NSCaseInsensitiveSearch].location != NSNotFound)
        {
            ret = passiveTotal/minSeconds;
        }else if ([type rangeOfString:@"active" options:NSCaseInsensitiveSearch].location != NSNotFound)
        {
            ret = activeTotal/minSeconds;
        }else{
            NSLog(@"ERROR unkonw type: %@",type);
        }
        
        if (ret > 1) return ret; //no need to factor all apps if we allready went over
        
    }
    
    return ret;
}

-(void)updateAchievsProgress
{
    //retroactively awards achievements for all apps as well as the ones from the last usageCounter tick

    NSURL *dbURL = [CloudFunctions getDocsPathFor:@"achievements.plist" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
    NSDictionary *submited = [CloudFunctions coordonatedReadURL:dbURL];
    
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:1];
    
    int delay = 0;
    for (NSDictionary *ac in achievements)
    {
        float completed = [[submited objectForKey:[ac objectForKey:@"id"]] floatValue];
        if (completed >= 100) continue; //allready completed
        float progress = [self achievementsProgressFor:ac];
        NSArray *arr = [NSArray arrayWithObjects:@"New achievement",[ac objectForKey:@"name"],[ac objectForKey:@"desc"], nil];
        [ret setObject:[NSNumber numberWithFloat:progress] forKey:[ac objectForKey:@"id"]];
        if (progress >= 1 )
        {
            [self performSelector:@selector(delayedNotif:) withObject:arr afterDelay:delay];
            delay += 10;
        }
    }
    
    [MiscFunctions stringToPasteboard:[MiscFunctions arrayToPlist:[NSArray arrayWithObjects:ret,achievements, nil]]];
    
}

-(void)delayedNotif:(NSArray*)arr
{
    if (!didLaunch) [MiscFunctions achievementNotification:[arr objectAtIndex:0] subtitle:[arr objectAtIndex:1] text:[arr objectAtIndex:2]];
}

@end
