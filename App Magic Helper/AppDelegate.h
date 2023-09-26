//
//  AppDelegate.h
//  App Magic Helper
//
//  Created by Vlad Alexa on 7/18/12.
//  Copyright (c) 2012 Vlad Alexa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "UsageCounter.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    UsageCounter *usageCounter;
}

@end
