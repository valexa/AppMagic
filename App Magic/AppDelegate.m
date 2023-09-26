//
//  AppDelegate.m
//  App Magic
//
//  Created by Vlad Alexa on 7/3/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "AppDelegate.h"

#import <ServiceManagement/ServiceManagement.h>

#import <QuartzCore/QuartzCore.h>

#import "MiscFunctions.h"

#import "NSWindow+AccessoryView.h"

#import "CloudFunctions.h"

#import "DataFunctions.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    defaults = [NSUserDefaults standardUserDefaults];

}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    NSArray *arr = [MiscFunctions plistToArray:[MiscFunctions stringFromPasteboard]];
    NSError *err = nil;
    [[NSFileManager defaultManager] removeItemAtPath:filename error:&err];
    if (err) NSLog(@"%@",err);
    
    if ([arr count] > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AchievmentsControllerEvent" object:@"process" userInfo:[arr objectAtIndex:0]];
    }else{
        NSLog(@"Empty array");
    }
        
    return YES;
}

-(void)awakeFromNib
{

    [graphsView setHidden:YES];
    
    [toolbar setSelectedItemIdentifier:@"table"];
    
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(setHelper) userInfo:nil repeats:NO];
    
    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    if ([service canPerformWithItems:nil]) {
        [tweetButton setHidden:NO];
    }
  
    //[_window addViewToTitleBar:[NSWindow standardWindowButton:NSWindowDocumentIconButton forStyleMask:_window.styleMask] atXPosition:_window.frame.size.width/2];
    [self performSelector:@selector(positionMachinesArrow) withObject:nil afterDelay:0.1];    
    
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    if (enabledService && [defaults boolForKey:@"skipExitNag"] == NO)
    {
        [NSApp beginSheet:exitWindow modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
        return NO;
    }
    
	return YES;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	if(!flag){
        [window makeKeyAndOrderFront:self];
		[NSApp arrangeInFront:window];
    }else {
        [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(setHelper) userInfo:nil repeats:NO];
    }
	return YES;
}

-(void) setHelper
{
    if ([self bundleIDExistsAsLoginItem:@"com.vladalexa.appmagichelper"])
    {
        [helperSegment setSelectedSegment:1];
    }else {
        [helperSegment setSelectedSegment:0];
        [helperPopOver showRelativeToRect:infoButton.frame ofView:infoButton preferredEdge:NSMinYEdge];
    }
}

#pragma mark actions

- (IBAction)exitFromNag:(id)sender
{
	[NSApp endSheet:exitWindow];
	[exitWindow orderOut:self];
    [NSApp terminate:self];
}

-(IBAction) helperToggle:(id)sender
{
	if ([sender selectedSegment] == 1){
		[self setAutostart:YES];
        enabledService = YES;
		//NSLog(@"autostart on");
	}else {
		[self setAutostart:NO];
        enabledService = NO;
		//NSLog(@"autostart off");
	}
    if (sender != helperSegment) {
        [helperSegment setSelectedSegment:[sender selectedSegment]];
    }
}

- (IBAction) openWebsite:(id)sender
{
    [self closeSheet:sender];
	NSURL *url = [NSURL URLWithString:@"http://vladalexa.com/apps/osx/appmagic"];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

-(IBAction) showAbout:(id)sender
{
	[NSApp beginSheet:aboutWindow modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(IBAction)showTable:(id)sender
{
    [graphsView setHidden:YES];
    [tableScroll setHidden:NO];
}

-(IBAction)showGraphs:(id)sender
{
    [tableScroll setHidden:YES];
    [graphsView setHidden:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GraphControllerEvent" object:@"load"];
}

-(IBAction)showAchievs:(id)sender
{
    [sender setEnabled:NO];    
    [AppDelegate squish:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AchievmentsControllerEvent" object:@"load"];
    [[[NSApplication sharedApplication] dockTile] setBadgeLabel:nil];
}

-(IBAction)closeSheet:(id)sender
{
	[NSApp endSheet:[sender window]];
	[[sender window] orderOut:self];
}

-(IBAction)showSettings:(id)sender
{
    NSButton *button = sender;
    [AppDelegate spinOnPivot:button andBack:YES];
    NSView *view = settingsPopOver.contentViewController.view;
    [tableSettingsView removeFromSuperview];
    [graphSettingsView removeFromSuperview];
    if (![tableScroll isHidden]) [view addSubview:tableSettingsView];
    if (![graphsView isHidden]) [view addSubview:graphSettingsView];
    [settingsPopOver showRelativeToRect:button.frame ofView:button preferredEdge:NSMinYEdge];
}

-(IBAction)tweetPush:(id)sender
{
    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    NSArray * shareItems = [NSArray arrayWithObjects:@"@vadesigneu ", nil];
    [service performWithItems:shareItems];
}

-(IBAction)exportCSV:(id)sender
{
    [self closeSheet:sender];
    
    NSURL *dbURL = [CloudFunctions getDocsPathFor:@"database.plist" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
    NSDictionary *database = [NSDictionary dictionaryWithContentsOfURL:dbURL];
    
    NSURL *root = [CloudFunctions getDocsPathFor:@"" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
    [CloudFunctions scanDirectory:root completionHandler: ^(NSOrderedSet *foundFiles)
     {
         if (foundFiles && [foundFiles count] != 0)
         {
             NSSavePanel *save = [NSSavePanel savePanel];
             [save setDelegate:self];
             [save setShowsHiddenFiles:YES];
             [save setTreatsFilePackagesAsDirectories:YES];
             [save setNameFieldStringValue:@"appmagic.csv"];
             [save setTitle:@"Export CSV"];
             [save beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
                 if(result==NSOKButton)
                 {
                     NSMutableString *csv = [NSMutableString stringWithCapacity:1];
                     [csv appendString:@"Month,Machine,App,Active usage seconds,Passive usage seconds,Uses count\n"];
                     for (NSString *file in foundFiles)
                     {
                         NSDictionary *machinesDict = [DataFunctions dataAtPath:root list:[NSOrderedSet orderedSetWithObject:file]];
                         for (NSString *machine in machinesDict)
                         {
                             NSString *machineName = [[database objectForKey:@"machineNames"] objectForKey:machine];
                             NSDictionary *monthForMachine = [machinesDict objectForKey:machine];
                             for (NSString *bid in monthForMachine)
                             {
                                 NSDictionary *app = [monthForMachine objectForKey:bid];
                                 NSMutableString *month = [NSMutableString stringWithString:[file stringByReplacingOccurrencesOfString:@".plist" withString:@""]];
                                 [month insertString:@"-" atIndex:4];
                                 [month appendString:@"-01 00:00:00 +0000"];
                                 NSDate *date = [NSDate dateWithString:month];
                                 NSString *line = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@\n",[DataFunctions dateWithFormat:@"yyyy MMMM" date:date],machineName,bid,[app objectForKey:@"active"],[app objectForKey:@"passive"],[app objectForKey:@"uses"]];
                                 [csv appendString:line];
                             }
                         }
                     }
                     NSError *err;
                     [csv writeToURL:[save URL] atomically:YES encoding:NSUTF8StringEncoding error:&err];
                     if (err) {
                         NSLog(@"%@",[err localizedFailureReason]);
                         [[NSAlert alertWithError:err] runModal];
                     }
                 }
             }];
         }
     }];
}

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError
{
    
    if ([[url path] rangeOfString:@"N7N53EAPBD~com~vladalexa~appmagic"].location != NSNotFound)
    {
        *outError = [NSError errorWithDomain:@"com.vladalexa.appmagic" code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Invalid export location", NSLocalizedDescriptionKey,@"Select a local location for CSV export",NSLocalizedRecoverySuggestionErrorKey, nil]];
        return NO;
    }
    
    return YES;

}

#pragma mark version

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
    if ([key isEqualToString: @"versionString"]) return YES;
    return NO;
}

- (NSString *)versionString
{
	NSString *sv = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *v = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	return [NSString stringWithFormat:@"version %@ (%@)",sv,v];
}

#pragma mark autostart

- (void)setAutostart:(BOOL)set
{
	NSURL *theURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Library/LoginItems/app magic helper.app"];
    NSString *theBID = @"com.vladalexa.appmagichelper";
    
    Boolean success = SMLoginItemSetEnabled((__bridge CFStringRef)theBID, set);
    if (!success) {
        NSLog(@"Failed to SMLoginItemSetEnabled %@ %@",[theURL path],theBID);
    }
}

- (BOOL) bundleIDExistsAsLoginItem:(NSString *)bundleID
{
    
    NSArray * jobDicts = nil;
    jobDicts = (__bridge_transfer NSArray *)SMCopyAllJobDictionaries( kSMDomainUserLaunchd );
    // Note: Sandbox issue when using SMJobCopyDictionary()
    
    if ( (jobDicts != nil) && [jobDicts count] > 0 ) {
        
        BOOL bOnDemand = NO;
        for ( NSDictionary * job in jobDicts ) {
            if ( [bundleID isEqualToString:[job objectForKey:@"Label"]] ) {
                bOnDemand = [[job objectForKey:@"OnDemand"] boolValue];
                break;
            }
        }
        
        jobDicts = nil;
        return bOnDemand;
        
    }
    return NO;
}

#pragma mark NSWindowDelegate

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GraphControllerEvent" object:@"willResize"];
    return frameSize;
}

- (void)windowDidResize:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GraphControllerEvent" object:@"didResize"];    
    [machinesButton removeFromSuperview];
    [self performSelector:@selector(positionMachinesArrow) withObject:nil afterDelay:0.1];
}

-(void)positionMachinesArrow
{
    if (([window styleMask] & NSFullScreenWindowMask) != NSFullScreenWindowMask)
    {
        NSSize titleSize = [window.title sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont titleBarFontOfSize:13.0] forKey: NSFontAttributeName]];
        [machinesButton setFrame:NSMakeRect(window.frame.size.width/2 + titleSize.width/2, machinesButton.frame.origin.y, machinesButton.frame.size.width, machinesButton.frame.size.height)];
        [window addViewToTitleBar:machinesButton atXPosition:window.frame.size.width/2 + titleSize.width/2];
    }
}

#pragma mark tools

+(void)bounce:(id)sender
{
    NSView *view =  (NSView *)sender;
    
    [sender setWantsLayer:YES];
    [[sender layer] removeAllAnimations];
    
    CGFloat factors[32] = {0, 32, 60, 83, 100, 114, 124, 128, 128, 124, 114, 100, 83, 60, 32,
        0, 24, 42, 54, 62, 64, 62, 54, 42, 24, 0, 18, 28, 32, 28, 18, 0};
    
    NSMutableArray *values = [NSMutableArray array];
    
    for (int i=0; i<32; i++)
    {
        CGFloat positionOffset = factors[i]/640.0f * view.frame.size.height;
        
        CATransform3D transform = CATransform3DMakeTranslation(0, positionOffset, 0);
        [values addObject:[NSValue valueWithCATransform3D:transform]];
    }
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.repeatCount = MAXFLOAT;
    animation.duration = 32.0f/30.0f;
    animation.fillMode = kCAFillModeForwards;
    animation.values = values;
    animation.removedOnCompletion = YES; // final stage is equal to starting stage
    animation.autoreverses = NO;
    
	animation.duration = 1;
	animation.delegate = sender;
	[[sender layer] addAnimation:animation forKey:@"transform"];
}

+(void)squish:(id)sender
{
    [sender setWantsLayer:YES];
    [[sender layer] removeAllAnimations];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    CATransform3D forward = CATransform3DMakeScale(1.3, 1.3, 1);
    CATransform3D back = CATransform3DMakeScale(0.7, 0.7, 1);
    CATransform3D forward2 = CATransform3DMakeScale(1.2, 1.2, 1);
    CATransform3D back2 = CATransform3DMakeScale(0.9, 0.9, 1);
    [animation setValues:[NSArray arrayWithObjects:
                       [NSValue valueWithCATransform3D:CATransform3DIdentity],
                       [NSValue valueWithCATransform3D:forward],
                       [NSValue valueWithCATransform3D:back],
                       [NSValue valueWithCATransform3D:forward2],
                       [NSValue valueWithCATransform3D:back2],
                       [NSValue valueWithCATransform3D:CATransform3DIdentity],
                       nil]];
    
	animation.duration = 1;
	animation.delegate = sender;
	[[sender layer] addAnimation:animation forKey:@"transform"];
}

+(void)spinOnPivot:(id)sender andBack:(BOOL)andBack
{
    [sender setWantsLayer:YES];
    [[sender layer] removeAllAnimations];
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    if (andBack == YES) {
        animation.values = [NSArray arrayWithObjects:
                           [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0f, 0.0f, 0.0f, 1.0f)],
                           [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f)],
                           [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI * 2, 0.0f, 0.0f, 1.0f)],
                           nil];
    }else{
        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = 1.0 / -50;
        [sender layer].transform = transform;
        animation.values = [NSArray arrayWithObjects:
                           [NSValue valueWithCATransform3D:CATransform3DRotate(transform, 4 * M_PI / 2, 0, 1, 100)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(transform, 3 * M_PI / 2, 0, 1, 100)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(transform, 2 * M_PI / 2, 0, 1, 100)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(transform, 1 * M_PI / 2, 0, 1, 100)],
                           [NSValue valueWithCATransform3D:CATransform3DRotate(transform, 0 * M_PI / 2, 0, 1, 100)],
                           nil];
        
    }
	animation.duration = 1;
	[[sender layer] addAnimation:animation forKey:@"transform"];
    
    [MiscFunctions accountForLowerLeftAnchor:[sender layer]];
    
}

@end
