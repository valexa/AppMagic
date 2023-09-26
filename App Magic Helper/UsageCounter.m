//
//  UsageCounter.m
//  App Magic
//
//  Created by Vlad Alexa on 7/18/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "UsageCounter.h"

#import "RemoteListener.h"

#import "AchievementsTracker.h"

#import "DataFunctions.h"

#import "CloudFunctions.h"

#import "MiscFunctions.h"

@implementation UsageCounter

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        
        activeList = [[NSMutableDictionary alloc] init];
        
        passiveList = [[NSMutableDictionary alloc] init];
        
        usesList = [[NSMutableDictionary alloc] init];
        
        lastUseDateList = [[NSMutableDictionary alloc] init];
        
        tracking = [[NSMutableString alloc] init];
        
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(willPoweroff:) name: NSWorkspaceWillPowerOffNotification object: NULL];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(willSleep:) name: NSWorkspaceWillSleepNotification object: NULL];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(didWake:) name: NSWorkspaceDidWakeNotification object: NULL];
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(workspaceDidTerminateApplicationNotification:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
        
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(workspaceDidActivateApplicationNotification:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
        
        NSURL *dbURL = [CloudFunctions getDocsPathFor:[DataFunctions currentDB] containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];

        //check conflicts        
        NSArray *conflicts = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:dbURL];
        for (NSFileVersion *conflict in conflicts) {
            NSString *message = [NSString stringWithFormat:@"Conflict from %@ at %@ in %@ of %@",[conflict localizedNameOfSavingComputer],[conflict modificationDate],[conflict URL],[dbURL path]];
            NSLog(@"%@",message);
            [MiscFunctions deliverNotification:@"iCloud conflict" text:message];
            [conflict setResolved:YES];            
        }
        
        [NSEvent addGlobalMonitorForEventsMatchingMask:NSMouseMovedMask | NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask | NSKeyDownMask handler:^(NSEvent *theEvent) {
            lastEventDate = [NSDate date];
        }];
        
        remoteListener = [[RemoteListener alloc] init];
        [remoteListener addMonitorForRemoteEvents:^{
            lastEventDate = [NSDate date];
        }];
        
        //schedule run
        loopTimer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(timerLoop:) userInfo:nil repeats:YES];
                
        //achievementsTracker = [[AchievementsTracker alloc] init];
        
        //copy data saved locally after bug introduced with ATS SSL requirement
        [self moveBuggedData];

        
    }
    
    return self;
}

-(void)moveBuggedData
{
    
    NSURL *readURL = [[[[NSURL URLWithString:@"/Users"] URLByAppendingPathComponent:NSUserName()] URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:@"App Magic"];
    NSError *error = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *fileURLs = [fileManager contentsOfDirectoryAtURL:readURL includingPropertiesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] options:0 error:&error];
    if (error) NSLog(@"%@",error);
    if (!fileURLs) {
        NSLog(@"No files under %@",[readURL path]);
    }else{
        NSURL *root = [CloudFunctions getDocsPathFor:@"" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
        for (NSURL *file in fileURLs) {
            NSURL *fileDestination = [root URLByAppendingPathComponent:[file lastPathComponent]];
            if ([fileManager moveItemAtURL:file toURL:fileDestination error:&error]){
                NSLog(@"Moved %@ to %@",file, fileDestination);
            }else{
                NSLog(@"%@",error);
            }
        }
    }

}

-(void)timerLoop:(NSTimer*)timer
{
    [self performSelector:@selector(saveUsage) withObject:nil afterDelay:0.5];
    [self performSelector:@selector(saveDates) withObject:nil afterDelay:5.5];
    [achievementsTracker performSelector:@selector(counterLoop) withObject:nil afterDelay:15.5];
    [self performSelector:@selector(putFilesInPasteboard) withObject:nil afterDelay:25.5];
}

-(void)putFilesInPasteboard
{
    id token = [[NSFileManager defaultManager] ubiquityIdentityToken];
    if (token != nil) return; //using iCloud
    NSURL *localURL = [CloudFunctions getDocsPathFor:@"" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
    [MiscFunctions dirToPasteboard:[localURL path]];
}

- (void) willSleep: (NSNotification*) notif
{
    [loopTimer invalidate];
    [self addTime];
}


- (void) didWake: (NSNotification*) notif
{
    [loopTimer invalidate];
    loopTimer = nil;
    loopTimer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(timerLoop:) userInfo:nil repeats:YES];
}

- (void) willPoweroff: (NSNotification*) notif
{
    NSLog(@"LOGME willPoweroff");
    [self terminate];
}

-(void)terminate
{
    [self saveUsage];
    [self saveDates];
}

#pragma mark usage

-(void)saveUsage
{
    if ([lastEventDate timeIntervalSinceNow] < -60) {
        [self addTime];
    }else{
        trackingPassiveSince = [NSDate date];
    }
    
    NSURL *dbURL = [CloudFunctions getDocsPathFor:[DataFunctions currentDB] containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:[dbURL path]]) [CloudFunctions coordonatedWrite:[NSDictionary dictionary] at:dbURL]; //new month
    
    NSDictionary *d = [CloudFunctions coordonatedReadURL:dbURL];
    if (!d)
    {
        NSLog(@"Will not save usage, can't read previous data because of iCloud error");
        return;
    }
    NSMutableDictionary *db = [NSMutableDictionary dictionaryWithDictionary:d];
    NSMutableDictionary *machines = [NSMutableDictionary dictionaryWithDictionary:[db objectForKey:@"machines"]];
    NSMutableDictionary *apps = [NSMutableDictionary dictionaryWithDictionary:[machines objectForKey:[self machineSerial]]];
    
    for (NSString *bid in activeList)
    {
        NSMutableDictionary *app = [NSMutableDictionary dictionaryWithDictionary:[apps objectForKey:bid]];
        NSNumber *now = [activeList objectForKey:bid];
        NSNumber *past = [app objectForKey:@"active"];
        [app setObject:[NSNumber numberWithInteger:[now integerValue]+[past integerValue]] forKey:@"active"];
        [apps setObject:app forKey:bid];
    }
    
    for (NSString *bid in passiveList)
    {
        NSMutableDictionary *app = [NSMutableDictionary dictionaryWithDictionary:[apps objectForKey:bid]];
        NSNumber *now = [passiveList objectForKey:bid];
        NSNumber *past = [app objectForKey:@"passive"];
        [app setObject:[NSNumber numberWithInteger:[now integerValue]+[past integerValue]] forKey:@"passive"];
        [apps setObject:app forKey:bid];
    }
    
    for (NSString *bid in usesList)
    {
        NSMutableDictionary *app = [NSMutableDictionary dictionaryWithDictionary:[apps objectForKey:bid]];
        NSNumber *now = [usesList objectForKey:bid];
        NSNumber *past = [app objectForKey:@"uses"];
        [app setObject:[NSNumber numberWithInteger:[now integerValue]+[past integerValue]] forKey:@"uses"];
        [apps setObject:app forKey:bid];
    }
    
    [machines setObject:apps forKey:[self machineSerial]];
    [db setObject:machines forKey:@"machines"];
    //save
    if ([CloudFunctions coordonatedWrite:db at:dbURL])
    {
        [activeList removeAllObjects];
        [passiveList removeAllObjects];
        [usesList removeAllObjects];
    }
}

-(void)workspaceDidActivateApplicationNotification:(NSNotification*)notif
{
    NSRunningApplication *runningApp = [[notif userInfo] objectForKey:@"NSWorkspaceApplicationKey"];
    if (runningApp) {
        NSString *bid = [runningApp bundleIdentifier];
        if (!bid || [bid length] < 1)
        {
            if ([runningApp executableURL]) bid = [[runningApp executableURL] lastPathComponent];
            if ([runningApp bundleURL]) bid = [[runningApp bundleURL] lastPathComponent];
        }
        if (bid && [bid length] > 0)
        {
            if ([bid isEqualToString:tracking]) return; //switched apps with diff names but same bid
            [self addTime];
            trackingActiveSince = [NSDate date];
            [tracking setString:bid];
        }else {
            trackingActiveSince = nil;
            trackingPassiveSince = nil;
            NSLog(@"No bid for %@ %@,",[runningApp localizedName],runningApp);
        }
    }
}

-(void)addTime
{
    if (trackingActiveSince) {
        int newSeconds = [[NSDate date] timeIntervalSinceDate:trackingActiveSince];
        int oldSeconds = [[activeList objectForKey:tracking] intValue];
        [activeList setObject:[NSNumber numberWithInt:oldSeconds+newSeconds] forKey:tracking];
        trackingActiveSince = nil;
    }
    if (trackingPassiveSince) {
        int newSeconds = [[NSDate date] timeIntervalSinceDate:trackingPassiveSince];
        int oldSeconds = [[passiveList objectForKey:tracking] intValue];
        [passiveList setObject:[NSNumber numberWithInt:oldSeconds+newSeconds] forKey:tracking];
        trackingPassiveSince = nil;
    }
}

#pragma mark terminations

-(void)saveDates
{
    //save times and human machine names
    NSURL *databaseURL = [CloudFunctions getDocsPathFor:@"database.plist" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
    NSDictionary *db = [CloudFunctions coordonatedReadURL:databaseURL];
    if (!db)
    {
        NSLog(@"Will not save dates, can't read previous data because of iCloud error");
        return;
    }
    NSMutableDictionary *database = [NSMutableDictionary dictionaryWithDictionary:db];
    
    //names
    NSMutableDictionary *names = [NSMutableDictionary dictionaryWithDictionary:[database objectForKey:@"machineNames"]];
    [names setObject:[[NSHost currentHost] localizedName] forKey:[self machineSerial]];
    [database setObject:names forKey:@"machineNames"];
    
    //and dates
    NSMutableDictionary *appsdb = [NSMutableDictionary dictionaryWithDictionary:[database objectForKey:@"appsdb"]];
    for (NSString *bid in lastUseDateList)
    {
        NSDate *date = [lastUseDateList objectForKey:bid];
        NSMutableDictionary *adb = [NSMutableDictionary dictionaryWithDictionary:[appsdb objectForKey:bid]];
        if (![adb objectForKey:@"firstuse"])[adb setObject:date forKey:@"firstuse"];
        [adb setObject:date forKey:@"lastuse"];
        [appsdb setObject:adb forKey:bid];
    }
    [database setObject:appsdb forKey:@"appsdb"];
    [lastUseDateList removeAllObjects];//this is no increment counter like the others, we dont need old dates
    
    //save
    [CloudFunctions coordonatedWrite:database at:databaseURL];
}

-(void)workspaceDidTerminateApplicationNotification:(NSNotification*)notification
{
    //increment terminations
    NSRunningApplication *runningApp = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
    if (runningApp)
    {
        NSString *bid = [runningApp bundleIdentifier];
        if (bid && [bid length] > 0)
        {
            NSInteger cachedCount = [[usesList objectForKey:bid] integerValue];
            [usesList setObject:[NSNumber numberWithInteger:cachedCount+1] forKey:bid];
            [lastUseDateList setObject:[NSDate date] forKey:bid];
        }
    }
}

#pragma mark tools

-(NSString *)machineSerial
{
	NSString *ret = nil;
	io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));
	if (platformExpert) {
		CFTypeRef cfstring = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformSerialNumberKey),kCFAllocatorDefault, 0);
        if (cfstring) {
            ret = [NSString stringWithFormat:@"%@",cfstring];
            CFRelease(cfstring);
        }
		IOObjectRelease(platformExpert);
	}
    return ret;
}


@end
