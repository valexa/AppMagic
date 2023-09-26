//
//  TableController.h
//  App Magic
//
//  Created by Vlad Alexa on 8/9/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VATableView.h"

@interface TableController : NSObject <NSTextFieldDelegate,VATableViewDelegate>{

    NSUserDefaults *defaults;
    NSTimer *searchTimer;
    NSMutableString *searchString;
    
    IBOutlet NSTextField *noDataText;    
    
    IBOutlet NSTableView *appsTable;
    
    IBOutlet NSSegmentedControl *timeControl;
    
    IBOutlet NSButton *refreshButton;
    
    IBOutlet NSButton *activeButton;
    IBOutlet NSButton *passiveButton;
    
    IBOutlet NSButton *existingButton;
    IBOutlet NSButton *nonExistingButton;
    
    IBOutlet NSWindow *window;
    IBOutlet NSPopUpButton *machinesButton;
    
    IBOutlet NSTextField *settingsText;
    
    IBOutlet NSDatePicker *startDatePicker;
    IBOutlet NSDatePicker *endDatePicker;
    IBOutlet NSButton *dateButton;
    IBOutlet NSWindow *dateWindow;
}

@property (retain)  NSMutableArray *filteredAppsList;
@property (retain)  NSMutableArray *appsList;
@property (retain)  NSMutableString *machine;

-(IBAction)earliestDate:(id)sender;
-(IBAction)latestDate:(id)sender;
-(IBAction)doneDate:(id)sender;

-(IBAction)machineChange:(id)sender;
-(IBAction)timeChange:(id)sender;

-(IBAction)activeClick:(id)sender;
-(IBAction)passiveClick:(id)sender;

-(IBAction)existingClick:(id)sender;
-(IBAction)nonExistingClick:(id)sender;

-(IBAction)refreshClick:(id)sender;

-(NSOrderedSet*)dataSetForSettingsFrom:(NSOrderedSet*)allFiles;

-(NSDictionary*)metadataFor:(NSString*)file;


@end
