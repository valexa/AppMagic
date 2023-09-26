//
//  GraphController.m
//  App Magic
//
//  Created by Vlad Alexa on 2/4/14.
//  Copyright (c) 2014 Next Design. All rights reserved.
//

#import "GraphController.h"

#import "CloudFunctions.h"

#import "DataFunctions.h"

#import "MiscFunctions.h"

@implementation GraphController

- (id)init
{
    self = [super init];
    if (self) {
        
        defaults = [NSUserDefaults standardUserDefaults];
        
        if ([defaults objectForKey:@"pieAlphaSort"] == nil) [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"pieAlphaSort"];
        if ([defaults objectForKey:@"multipleMonthsShow"] == nil) [defaults setObject:@"Data by month" forKey:@"multipleMonthsShow"];
        if ([defaults objectForKey:@"valuesShow"] == nil) [defaults setObject:@"On mouseover" forKey:@"valuesShow"];
        
        [defaults synchronize];
        
        previousTokens = [NSMutableArray arrayWithCapacity:1];
        
    }
    return self;
}

-(void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"GraphControllerEvent" object:nil];
    
    [tableController addObserver:self forKeyPath:@"filteredAppsList" options:NSKeyValueObservingOptionNew context:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(tokensCheck) userInfo:nil repeats:YES];//hack because we cant KVO tokenField.objectValue
    
    topPie.humanize = YES;
    botPie.humanize = NO;

    [topPie addConstraint:[NSLayoutConstraint constraintWithItem:topPie attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:topPie attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (![graphsView isHidden])
    {
        if (object == tableController)
        {
            [tokenField setObjectValue:nil];
            [self load];
        }
    }
}


-(void)theEvent:(NSNotification*)notif
{

	if ([[notif userInfo] isKindOfClass:[NSDictionary class]])
    {
		if ([[notif object] isKindOfClass:[NSString class]])
        {
            if ([[notif object] isEqualToString:@"add"])
            {
                NSMutableArray *tokens = [NSMutableArray arrayWithArray:[tokenField objectValue]];
                [tokens addObject:[[notif userInfo] objectForKey:@"bid"]];
                [previousTokens addObject:[[notif userInfo] objectForKey:@"bid"]];
                [tokenField setObjectValue:tokens];
            }
		}
	}
	if ([[notif object] isKindOfClass:[NSString class]])
    {
        if ([[notif object] isEqualToString:@"load"])
        {
            [self load];
        }
        if ([[notif object] isEqualToString:@"willResize"])
        {
         
        }
        if ([[notif object] isEqualToString:@"didResize"])
        {
            if (![topChart isHidden]) [topChart updateFrames];
            if (![botChart isHidden]) [botChart updateFrames];
            if (![topPie isHidden])   [topPie updateFrames];
            if (![botPie isHidden]) [botPie updateFrames];
        }
	}
}

-(IBAction)hardReload:(id)sender
{
    [topChart removeAllData];
    [botChart removeAllData];
    [topPie removeAllData];
    [botPie removeAllData];
    [self load];
}

-(IBAction)reload:(id)sender
{
    [self load];
}

#pragma mark NSTokenFieldDelegate


- (NSArray *)tokenField:(NSTokenField *)field shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    
    for (NSDictionary *app in tableController.appsList)
    {
        for (NSString *token in tokens)
        {
            if ([[app objectForKey:@"bid"] isEqualToString:token])
            {
                [ret addObject:token];
            }
        }
    }
    
    return ret;
}

- (BOOL)control:(NSControl *)control isValidObject:(id)token
{
    if ([control isKindOfClass:[NSTokenField class]] && [token isKindOfClass:[NSString class]])
    {
        if ([token rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]].location == NSNotFound) return YES;
        return NO;
    }
    return YES;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    
    if ([substring length] > 5 )
    {
        for (NSDictionary *app in tableController.appsList)
        {
            if ([[app objectForKey:@"bid"] rangeOfString:substring options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [ret addObject:[app objectForKey:@"bid"]];
            }
        }
    }

    return ret;
}

- (void)controlTextDidChange:(NSNotification *)obj
{
}

-(void)tokensCheck
{
    BOOL update = NO;
    
    for (NSString *token in [tokenField objectValue])
    {
        if (![previousTokens containsObject:token])
        {
            update = YES;
        }
    }
    
    for (NSString *token in previousTokens)
    {
        if (![[tokenField objectValue] containsObject:token])
        {
            update = YES;
        }
    }
    
    if (update)
    {
        [previousTokens setArray:[tokenField objectValue]];
        [self performSelector:@selector(load) withObject:nil afterDelay:1];
    }
    
}

#pragma mark core

-(void)load
{
    [topChart setHidden:NO];
    [botChart setHidden:NO];
    [topPie setHidden:NO];
    [botPie setHidden:NO];
    
    noColor = NO;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:@"d MMM"];
    if ([[dateFormatter stringFromDate:[NSDate date]] isEqualToString:@"5 Oct"]) noColor = YES;
    if ([defaults boolForKey:@"grayScale"]) noColor = YES;
    
    NSColor *activeColor = ORANGE_COLOR;
    NSColor *usesColor = DARK_ORANGE_COLOR;
    if (noColor) {
        activeColor = [NSColor grayColor];
        usesColor = [NSColor darkGrayColor];
    }
    
    NSURL *root = [CloudFunctions getDocsPathFor:@"" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
    [CloudFunctions scanDirectory:root completionHandler: ^(NSOrderedSet *foundFiles) {

        
        NSOrderedSet *filteredFiles = [tableController dataSetForSettingsFrom:foundFiles];
        NSArray *displayedApps = [self displayedApps];
        NSDictionary *data = nil;
        
        NSArray *items = [NSArray arrayWithObject:@"total"];
        NSArray *slices = [self makeSlicesBy:items from:data];
        NSArray *rainbowColors = [MiscFunctions rainbowColors:[slices count] reverse:NO grayscale:noColor];
        topPie.items = items;
        topPie.values = slices;
        topPie.colors = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:rainbowColors] forKeys:items];
        [topPie updateSlices];
        
        items = [NSArray arrayWithObject:@"uses"];
        slices = [self makeSlicesBy:items from:data];
        botPie.items = items;
        botPie.values = slices;
        botPie.colors = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:rainbowColors] forKeys:items];
        [botPie updateSlices];
        
        if ([filteredFiles count] > 1 && [[defaults objectForKey:@"multipleMonthsShow"] isEqualToString:@"Data by month"])
        {
            data = [self computeTotals:root files:filteredFiles displayedApps:displayedApps];
                        
            NSArray *tokens = [tokenField objectValue];
            if ([tokens count] > 0) {
                [settingsText setStringValue:[NSString stringWithFormat:@"Showing %lu months history for %lu apps.",(unsigned long)[filteredFiles count],(unsigned long)[[tokenField objectValue] count]]];
            }else{
                [settingsText setStringValue:[NSString stringWithFormat:@"Showing %lu months history for %lu apps.",(unsigned long)[filteredFiles count],(unsigned long)[displayedApps count]]];
            }

        }else if ([filteredFiles count] == 1 || [[defaults objectForKey:@"multipleMonthsShow"] isEqualToString:@"Data by app"])
        {
            
            NSArray *tokens = [tokenField objectValue];
            if ([tokens count] > 0) {
                [settingsText setStringValue:[NSString stringWithFormat:@"Showing %lu apps.",(unsigned long)[[tokenField objectValue] count]]];
            }else{
                [settingsText setStringValue:[NSString stringWithFormat:@"Showing %lu apps.",(unsigned long)[displayedApps count]]];
            }
        }

        items = [NSArray arrayWithObjects:@"active",@"passive", nil];
        slices = [self makeSlicesBy:items from:data];
        topChart.humanize = YES;
        topChart.items = items;
        topChart.values = [MiscFunctions reversedArray:slices];
        topChart.colors = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[MiscFunctions rainbowColors:[slices count] reverse:YES grayscale:noColor],[MiscFunctions rainbowColors:[slices count] reverse:NO grayscale:YES], nil] forKeys:items];
        if (data != nil) {
            topChart.colors = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[MiscFunctions alternatingColors:[slices count] fromColor:activeColor],[MiscFunctions alternatingColors:[slices count] fromColor:[NSColor lightGrayColor]], nil] forKeys:items];
            topChart.values = slices;
        }
        [topChart updateBars];
        
        items = [NSArray arrayWithObjects:@"uses", nil];
        slices = [self makeSlicesBy:items from:data];
        botChart.humanize = NO;
        botChart.items = items;
        botChart.values = [MiscFunctions reversedArray:slices];
        botChart.colors = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:[MiscFunctions rainbowColors:[slices count] reverse:YES grayscale:noColor]] forKeys:items];
        if (data != nil) {
            botChart.colors = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[MiscFunctions alternatingColors:[slices count] fromColor:usesColor], nil] forKeys:items];
            botChart.values = slices;
        }
        [botChart updateBars];
        

    }];
}


-(NSArray*)displayedApps
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    
    for (NSDictionary *app in tableController.filteredAppsList)
    {
        NSString *bid = [app objectForKey:@"bid"];
        if (bid) [ret addObject:bid];
    }
    return ret;
}

-(NSArray*)filteredTokenizedAppsList
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    
    NSArray *tokens = [tokenField objectValue];
    if ([tokens count] > 0)
    {
        for (NSDictionary *app in tableController.filteredAppsList)
        {
            if ([tokens containsObject:[app objectForKey:@"bid"]]) [ret addObject:app];
        }
    }else{
        [ret setArray:tableController.filteredAppsList];
    }
    
    return ret;
}

-(NSArray*)makeSlicesBy:(NSArray*)items from:(NSDictionary*)data
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    
    NSMutableOrderedSet *top = [NSMutableOrderedSet orderedSet];
    
    NSMutableOrderedSet *months = [data objectForKey:@"months"];
    
    if (months != nil)
    {
        top = months;
    }else{
        NSArray *computed = [self computeTopTenBy:[items objectAtIndex:0]];
        if ([computed count] == 0) return nil;
        
        if ([defaults boolForKey:@"pieAlphaSort"])
        {
            NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO selector:@selector(compare:)];
            [top addObjectsFromArray:[computed sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]]];
        }else{
            [top addObjectsFromArray:computed];
        }
        if ([top count] == 11) [top moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:[top count]-1] toIndex:0];//put Others last
    }

    for (NSDictionary *app in top)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
        for (NSString *item in items)
        {
            NSNumber *num = [app objectForKey:item];
            if (num) {
                [dict setObject:[num stringValue] forKey:item];
            }else{
                //NSLog(@"NIL %@ in %@",item,app);
            }
            [dict setObject:[app objectForKey:@"name"] forKey:@"name"];
        }
        [ret addObject:dict];
    }
    return ret;
}

-(NSMutableArray*)computeTopTenBy:(NSString*)by
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    
    NSMutableArray *sorted = [NSMutableArray arrayWithArray:[self filteredTokenizedAppsList]];
    
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:by ascending:NO selector:@selector(compare:)];
    [sorted sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
    
    NSMutableArray *others = [NSMutableArray arrayWithCapacity:1];;
    int count = 1;
    for (NSDictionary *app in sorted)
    {
        if (count < 11) {
            [ret insertObject:app atIndex:0];
        }else{
            [others addObject:app];
        }
        count++;
    }
    
    NSInteger othersTotal = 0;
    for (NSDictionary *app in others)
    {
        NSNumber *num = [app objectForKey:by];
        othersTotal += [num integerValue];
    }
    
    if ([others count] > 0 && [ret count] > 0) {
        [ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:othersTotal],by,[NSString stringWithFormat:@"%lu Others",(unsigned long)[others count]],@"name", nil]];
    }
    
    return ret;
}

-(NSDictionary*)computeTotals:(NSURL*)root files:(NSOrderedSet*)files displayedApps:(NSArray*)displayedApps
{
    NSMutableOrderedSet *months = [NSMutableOrderedSet orderedSet];

    for (NSString *file in files)
    {
        NSDictionary *machinesDict = [DataFunctions dataAtPath:root list:[NSOrderedSet orderedSetWithObject:file]];
        NSDictionary *apps = [DataFunctions appsForMachine:tableController.machine db:machinesDict];
        NSMutableDictionary *totals = [NSMutableDictionary dictionaryWithCapacity:1];
        for (NSString *bid in apps)
        {
            NSArray *tokens = [tokenField objectValue];
            if ([tokens count] > 0) {
                if (![tokens containsObject:bid]) continue;
            }else{
                if (![displayedApps containsObject:bid]) continue;
            }
            NSDictionary *app = [apps objectForKey:bid];
            for (NSString *item in app)
            {
                NSInteger t = [[app objectForKey:item] integerValue];
                NSInteger total = [[totals objectForKey:item] integerValue] + t;
                [totals setObject:[NSNumber numberWithInteger:total] forKey:item];
            }
        }
        [totals setObject:file forKey:@"name"];
        [months addObject:totals];
    }
    
    if ([files count] == 1)
    {
        return [NSDictionary dictionaryWithObjectsAndKeys:[months objectAtIndex:0],@"months", nil];
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:months,@"months", nil];
}


@end
