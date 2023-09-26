//
//  AppDelegate.h
//  App Magic
//
//  Created by Vlad Alexa on 7/3/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate,NSOpenSavePanelDelegate>
{
    IBOutlet NSWindow *window;
    
    IBOutlet NSView *graphsView;
    IBOutlet NSScrollView *tableScroll;
    
    IBOutlet NSWindow *aboutWindow;
    IBOutlet NSWindow *exitWindow;
    
    IBOutlet NSToolbar *toolbar;
    IBOutlet NSButton *tweetButton;
    
    IBOutlet NSPopUpButton *machinesButton;    
    
    IBOutlet NSSegmentedControl *helperSegment;
    
    IBOutlet NSPopover *settingsPopOver;
    IBOutlet NSPopover *helperPopOver;

    IBOutlet NSButton *infoButton;
    
    IBOutlet NSView *tableSettingsView;
    IBOutlet NSView *graphSettingsView;
        
    NSUserDefaults  *defaults;
    BOOL enabledService;
}

-(IBAction)exitFromNag:(id)sender;

-(IBAction)showTable:(id)sender;
-(IBAction)showGraphs:(id)sender;
-(IBAction)showAchievs:(id)sender;

-(IBAction)openWebsite:(id)sender;
-(IBAction)showAbout:(id)sender;
-(IBAction)closeSheet:(id)sender;
-(IBAction)showSettings:(id)sender;
-(IBAction)tweetPush:(id)sender;
-(IBAction)exportCSV:(id)sender;

-(IBAction)helperToggle:(id)sender;

- (void)setAutostart:(BOOL)set;
- (BOOL) bundleIDExistsAsLoginItem:(NSString *)bundleID;

+(void)bounce:(id)sender;
+(void)squish:(id)sender;
+(void)spinOnPivot:(id)sender andBack:(BOOL)andBack;

@end
