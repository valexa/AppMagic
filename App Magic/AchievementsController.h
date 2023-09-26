//
//  AchievmentsController.h
//  App Magic
//
//  Created by Vlad Alexa on 2/7/14.
//  Copyright (c) 2014 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GameKit/GameKit.h>

@interface AchievementsController : NSObject <GKAchievementViewControllerDelegate> {
    
    IBOutlet NSWindow *window;
    IBOutlet NSButton *achievButton;
    NSMutableDictionary *localProgress;
    NSMutableDictionary *cloudProgress;
    BOOL userInitiated;
}

@end
