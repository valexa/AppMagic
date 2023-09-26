//
//  AchievmentsController.m
//  App Magic
//
//  Created by Vlad Alexa on 2/7/14.
//  Copyright (c) 2014 Next Design. All rights reserved.
//

#import "MiscFunctions.h"

#import "CloudFunctions.h"

#import "AppDelegate.h"

#import "AchievementsController.h"

@implementation AchievementsController

- (id)init
{
    self = [super init];
    if (self) {
        
        cloudProgress = [NSMutableDictionary dictionaryWithCapacity:1];
        localProgress = [NSMutableDictionary dictionaryWithCapacity:1];
        
    }
    return self;
}

-(void)awakeFromNib
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"AchievmentsControllerEvent" object:nil];
    
    if ([GKLocalPlayer localPlayer].authenticated == NO)
    {
        //[self authenticateLocalPlayer];
    }
    
}

-(void)theEvent:(NSNotification*)notif
{
	if ([[notif object] isKindOfClass:[NSString class]])
    {
        if ([notif userInfo])
        {
            if ([[notif object] isEqualToString:@"process"])
            {
                [localProgress setDictionary:[notif userInfo]];
                userInitiated = NO;
                if ([GKLocalPlayer localPlayer].authenticated == NO)
                {
                    [AppDelegate squish:achievButton];
                    [achievButton setEnabled:NO];
                    [self authenticateLocalPlayer];
                }else{
                    [achievButton setEnabled:YES];                    
                    [self loadAchievements];
                }
            }
        }else{
            if ([[notif object] isEqualToString:@"load"])
            {
                userInitiated = YES;
                if ([GKLocalPlayer localPlayer].authenticated == NO)
                {
                    [self authenticateLocalPlayer];
                }else{
                    [achievButton setEnabled:YES];
                    [self showGameCenter];
                }
            }
        }
	}
}

#pragma mark GKAchievementViewControllerDelegate

- (void) showGameCenter
{
    GKAchievementViewController *controller = [[GKAchievementViewController alloc] init];
    controller.achievementDelegate = self;
    if (controller != nil)
    {
        GKDialogController *sdc = [GKDialogController sharedDialogController];
        sdc.parentWindow = window;
        [sdc presentViewController:controller];
    }
}

- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
    GKDialogController *sdc = [GKDialogController sharedDialogController];
    [sdc dismiss:self];
}

#pragma mark GKLocalPlayer

- (void) authenticateLocalPlayer
{
    
    [[GKLocalPlayer localPlayer] setAuthenticateHandler:(^(NSViewController* viewController, NSError *error) {
        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        if (viewController != nil)
        {
            [self showAuthenticationDialogWhenReasonable:viewController];
        }
        else if (localPlayer.isAuthenticated)
        {
            [self authenticatedPlayer:localPlayer];
        } else {
            [self disableGameCenter];
        }
        
        if (error)
        {
            NSLog(@"%@",error);
        }
    })];
}

-(void)showAuthenticationDialogWhenReasonable:(NSViewController*) viewController
{
    //never fires
    //[authWindow setContentView:viewController.view];
  	//[NSApp beginSheet:authWindow modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(void)disableGameCenter
{
}

-(void)authenticatedPlayer:(GKLocalPlayer*)localPlayer
{
    //NSLog(@"%@",localPlayer);
    [achievButton setEnabled:YES];
    if (userInitiated)
    {
        if ([localProgress count] > 0)
        {
            NSLog(@"Submitting old progress");
            [self performSelector:@selector(loadAchievements) withObject:nil afterDelay:6];
        }else{
            NSArray *arr = [MiscFunctions plistToArray:[MiscFunctions stringFromPasteboard]];
            if ([arr count] > 0) {
                NSLog(@"Updating progress");                
                [localProgress setDictionary:[arr objectAtIndex:0]];
                [self performSelector:@selector(loadAchievements) withObject:nil afterDelay:6];
            }
        }
        [self showGameCenter];
    }else{
        [self loadAchievements];
    }

}

-(void)didLoadAchievs
{
    
    NSMutableDictionary * newAchievs = [NSMutableDictionary dictionaryWithCapacity:1];
    
    for (NSString *identifier in localProgress)
    {
        double percent = [[localProgress objectForKey:identifier] doubleValue]*100.0;
        if (percent > 100) percent = 100.0;
        if (percent > 1)
        {
            if ([[cloudProgress objectForKey:identifier] doubleValue]-percent >= 1)
            {
                [newAchievs setObject:[NSNumber numberWithDouble:percent] forKey:identifier];
                //[self reportAchievementIdentifier:identifier percentComplete:percent];
            }
        }
    }
    
    [localProgress removeAllObjects];
    
    if ([newAchievs count] == 0) return;
    
    NSLog(@"Setting progress for %lu achievements",(unsigned long)[newAchievs count]);
    
    [GKAchievement reportAchievements:[self getAchievementForIdentifiers:newAchievs] withCompletionHandler:^(NSError *error)
     {
         if (error != nil)
         {
             NSLog(@"Error in reporting achievements: %@", error);
         }else{
             int new = 0;
             for (NSString *a in newAchievs)
             {
                 double percent = [[newAchievs objectForKey:a] doubleValue];
                 if (percent == 100)
                 {
                     NSLog(@"New achiev completed (%.2f->%.2f): %@",[[cloudProgress objectForKey:a] doubleValue],percent,a);
                     new++;
                 }else{
                     NSLog(@"Achiev progress (%.2f->%.2f): %@",[[cloudProgress objectForKey:a] doubleValue],percent,a);
                 }
             }
             if (new > 0)
             {
                 [AppDelegate performSelector:@selector(bounce:) withObject:achievButton afterDelay:1];
                 [[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%i",new]];
             }
            [self performSelector:@selector(loadAchievements) withObject:nil afterDelay:6]; //update achievements.plist
         }
     }];
    
}

- (void) loadAchievements
{
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error)
     {
         if (error == nil)
         {
             for (GKAchievement* achievement in achievements)
             {
                 [cloudProgress setObject:[NSNumber numberWithDouble:achievement.percentComplete] forKey:achievement.identifier];
             }
             NSURL *dbURL = [CloudFunctions getDocsPathFor:@"achievements.plist" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
             [CloudFunctions coordonatedWrite:cloudProgress at:dbURL];
             [self performSelector:@selector(didLoadAchievs) withObject:nil afterDelay:1];
             //NSLog(@"Loaded %lu achievements in progress",(unsigned long)[cloudProgress count]);
         }else{
             NSLog(@"Error in loading achievements: %@", error);
             [[NSAlert alertWithError:error] beginSheetModalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
         }
     }];
}

#pragma mark tools


- (void) reportAchievementIdentifier: (NSString*) identifier percentComplete: (double) percent
{
    GKAchievement *achievement = [self getAchievementForIdentifier:identifier percent:percent];
    if (achievement)
    {
        [achievement reportAchievementWithCompletionHandler:^(NSError *error)
         {
             if (error != nil)
             {
                 NSLog(@"Error in reporting achievements: %@", error);
             }else if (percent >= 100)
             {
                 NSLog(@"+ %@",achievement.identifier);
             }
         }];
    }
}

- (GKAchievement*) getAchievementForIdentifier: (NSString*) identifier percent:(double)percent
{
    GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
    achievement.percentComplete = percent;
    if (percent >= 100) achievement.showsCompletionBanner = YES;

    if (achievement == nil) NSLog(@"Error making GKAchievement for %@",identifier);
    return achievement;
}

-(NSArray *) getAchievementForIdentifiers: (NSDictionary*) achievs
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    
    for (NSString *identifier in achievs)
    {
        double percent = [[achievs objectForKey:identifier] doubleValue];
        [ret addObject:[self getAchievementForIdentifier:identifier percent:percent]];
    }

    return ret;
}


- (void)resetAchievements
{
	[GKAchievement resetAchievementsWithCompletionHandler: ^(NSError *error)
     {
         if (!error)
         {
             [cloudProgress removeAllObjects];
             NSURL *dbURL = [CloudFunctions getDocsPathFor:@"achievements.plist" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
             [CloudFunctions coordonatedWrite:cloudProgress at:dbURL];
         } else {
             NSLog(@"Error clearing achievements: %@", error);
         }
     }];
}


@end
