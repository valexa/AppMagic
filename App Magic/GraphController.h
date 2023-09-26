//
//  GraphController.h
//  App Magic
//
//  Created by Vlad Alexa on 2/4/14.
//  Copyright (c) 2014 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TableController.h"
#import "PieView.h"
#import "BarView.h"

@interface GraphController : NSObject <NSTokenFieldDelegate>
{
    
    BOOL noColor;
    
    NSUserDefaults *defaults;    
    
    IBOutlet TableController *tableController;
    
    IBOutlet NSTokenField *tokenField;
    NSMutableArray *previousTokens;
    
    IBOutlet NSView *graphsView;    
    IBOutlet BarView *topChart;
    IBOutlet BarView *botChart;
    IBOutlet PieView *topPie;
    IBOutlet PieView *botPie;
    
    IBOutlet NSTextField *settingsText;
    
    NSImage *topImg;
    NSImage *topImgAlt;
    NSImage *botImg;
    NSImage *botImgAlt;
}

-(IBAction)hardReload:(id)sender;
-(IBAction)reload:(id)sender;

@end
