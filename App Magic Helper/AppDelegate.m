//
//  AppDelegate.m
//  App Magic Helper
//
//  Created by Vlad Alexa on 7/18/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application

    usageCounter = [[UsageCounter alloc] init];
    
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    NSLog(@"LOGME willTerminate");    
    //does not fire from force quits, xcode or launchd quits
    [usageCounter terminate];
}

@end
