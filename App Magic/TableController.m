//
//  TableController.m
//  App Magic
//
//  Created by Vlad Alexa on 8/9/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "TableController.h"

#import "NSWindow+AccessoryView.h"

#import "AppDelegate.h"

#import "CloudFunctions.h"

#import "DataFunctions.h"

#import "MiscFunctions.h"

@implementation TableController

- (id)init
{
    self = [super init];
    if (self) {
        
        defaults = [NSUserDefaults standardUserDefaults];
        
        if ([defaults objectForKey:@"showActiveCount"] == nil) [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"showActiveCount"];
        if ([defaults objectForKey:@"showPassiveCount"] == nil) [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"showPassiveCount"];
        if ([defaults objectForKey:@"showExisting"] == nil) [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"showExisting"];
        if ([defaults objectForKey:@"showNonExisting"] == nil) [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"showNonExisting"];
        if ([defaults objectForKey:@"timePeriod"] == nil) [defaults setObject:@"This Month" forKey:@"timePeriod"];
        
        [defaults synchronize];
        
        self.filteredAppsList = [NSMutableArray arrayWithCapacity:1];        
        self.appsList = [NSMutableArray arrayWithCapacity:1];
        self.machine = [NSMutableString stringWithCapacity:1];
        searchString = [NSMutableString stringWithCapacity:1];
        searchTimer = nil;
        
    }
    return self;
}

-(void)awakeFromNib
{
    NSDate *now = [NSDate date];
    NSDate *firstMonth = [DataFunctions firstMonth];
    [startDatePicker setMinDate:firstMonth];
    [startDatePicker setMaxDate:now];
    [endDatePicker setMinDate:[DataFunctions monthAfter:firstMonth]];
    [endDatePicker setMaxDate:now];
    [self earliestDate:self];
    [self latestDate:self];
    
    if ([[defaults objectForKey:@"timePeriod"] isEqualToString:@"This Month"])
    {
        [timeControl setSelectedSegment:1];
    }else{
        [timeControl setSelectedSegment:0];
    }
    
    [window setTitle:@"All Machines"];
    [self.machine setString:window.title];
        
    [appsTable setRowHeight:23];
    [self performSelector:@selector(refreshClick:) withObject:refreshButton afterDelay:5];
    
}

-(IBAction)earliestDate:(id)sender
{
    [startDatePicker setDateValue:[startDatePicker minDate]];
}
-(IBAction)latestDate:(id)sender
{
    [endDatePicker setDateValue:[endDatePicker maxDate]];
}

-(IBAction)doneDate:(id)sender
{
	[NSApp endSheet:[sender window]];
	[[sender window] orderOut:self];
    [self refreshClick:refreshButton];    
}

-(IBAction)timeChange:(id)sender
{
    if ([timeControl selectedSegment] == 0) [defaults setObject:@"All Time" forKey:@"timePeriod"];
    if ([timeControl selectedSegment] == 1) [defaults setObject:@"This Month" forKey:@"timePeriod"];
    if ([timeControl selectedSegment] == 2)
    {
        [NSApp beginSheet:dateWindow modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
        return;
    }
    [defaults synchronize];
    [self refreshClick:refreshButton];
}

-(void)makeMachinesMenu:(NSDictionary*)dict
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"machines"];
    
    NSURL *dbURL = [CloudFunctions getDocsPathFor:@"database.plist" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
    NSDictionary *database = [NSDictionary dictionaryWithContentsOfURL:dbURL];

    [menu addItem:[NSMenuItem separatorItem]];
    for (NSString *machine in dict)
    {
        NSString *machineName = [[database objectForKey:@"machineNames"] objectForKey:machine];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
        [item setToolTip:machine];
        if (machineName)
        {
            [item setTitle:machineName];
        }else{
            [item setTitle:machine];
        }
        [menu addItem:item];
    }
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *item = [menu addItemWithTitle:@"All Machines" action:nil keyEquivalent:@""];
    [item setToolTip:@"All Machines"];
    
    [machinesButton setMenu:menu];
    [[machinesButton.menu itemWithTitle:window.title] setState:1];
}

-(IBAction)machineChange:(id)sender
{
    for (NSMenuItem *item in [machinesButton.menu itemArray]) {
        [item setState:0];
    }
    NSString *title = [machinesButton titleOfSelectedItem];
    NSMenuItem *item = [machinesButton.menu itemWithTitle:title];
    [item setState:1];
    [window setTitle:title];
    [self.machine setString:[item toolTip]];
    
    [machinesButton removeFromSuperview];
    NSSize titleSize = [window.title sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont titleBarFontOfSize:13.0] forKey: NSFontAttributeName]];
    [machinesButton setFrame:NSMakeRect(window.frame.size.width/2 + titleSize.width/2, machinesButton.frame.origin.y, machinesButton.frame.size.width, machinesButton.frame.size.height)];
    [window addViewToTitleBar:machinesButton atXPosition:window.frame.size.width/2 + titleSize.width/2];
    
    [self refreshClick:refreshButton];
}


-(IBAction)existingClick:(id)sender
{
    if ([defaults boolForKey:@"showExisting"] == YES)
    {
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"showExisting"];
        if (nonExistingButton.state == NSOffState)
        {
            [nonExistingButton setState:NSOnState];
            [self nonExistingClick:nonExistingButton];
        }
    }else{
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"showExisting"];
    }
    [defaults synchronize];
    [self refreshClick:refreshButton];
}

-(IBAction)nonExistingClick:(id)sender
{
    if ([defaults boolForKey:@"showNonExisting"] == YES)
    {
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"showNonExisting"];
        if (existingButton.state == NSOffState)
        {
            [existingButton setState:NSOnState];
            [self existingClick:existingButton];
        }
    }else {
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"showNonExisting"];
    }
    [defaults synchronize];
    [self refreshClick:refreshButton];
}

-(IBAction)activeClick:(id)sender
{
    if ([defaults boolForKey:@"showActiveCount"] == YES)
    {
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"showActiveCount"];
        if (passiveButton.state == NSOffState)
        {
            [passiveButton setState:NSOnState];
            [self passiveClick:passiveButton];
        }
    }else{
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"showActiveCount"];
    }
    [defaults synchronize];
    [self refreshClick:refreshButton];
}

-(IBAction)passiveClick:(id)sender
{
    if ([defaults boolForKey:@"showPassiveCount"] == YES)
    {
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"showPassiveCount"];
        if (activeButton.state == NSOffState)
        {
            [activeButton setState:NSOnState];
            [self activeClick:activeButton];
        }
    }else {
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"showPassiveCount"];
    }
    [defaults synchronize];
    [self refreshClick:refreshButton];
}

-(IBAction)refreshClick:(id)sender
{
    id token = [[NSFileManager defaultManager] ubiquityIdentityToken];
    if (token == nil)
    {
        NSURL *localURL = [CloudFunctions getDocsPathFor:@"" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
        [MiscFunctions pasteboardFilesToDir:[localURL path]];
    }
    [sender setEnabled:NO];
    [AppDelegate spinOnPivot:sender andBack:NO];
    [self performSelector:@selector(enableRefresh:) withObject:sender afterDelay:1];
    [self syncUI];
}

-(void)enableRefresh:(NSButton*)item
{
    [item setEnabled:YES];
}

#pragma mark core

-(void)syncUI
{
    
    if ([defaults boolForKey:@"showActiveCount"] == YES) [activeButton setState:NSOnState];
    if ([defaults boolForKey:@"showPassiveCount"] == YES) [passiveButton setState:NSOnState];
    if ([defaults boolForKey:@"showExisting"] == YES) [existingButton setState:NSOnState];
    if ([defaults boolForKey:@"showNonExisting"] == YES) [nonExistingButton setState:NSOnState];
    
    NSURL *root = [CloudFunctions getDocsPathFor:@"" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
    [CloudFunctions scanDirectory:root completionHandler: ^(NSOrderedSet *foundFiles)
    {
        if (!foundFiles || [foundFiles count] == 0)
        {
            [noDataText setHidden:NO];
            return;
        }else{
            [noDataText setHidden:YES];
        }
        
        [self.appsList removeAllObjects];
        
        NSDictionary *db = [DataFunctions dataAtPath:root list:[self dataSetForSettingsFrom:foundFiles]];
        
        [self makeMachinesMenu:db];

        NSDictionary *apps = [DataFunctions appsForMachine:_machine db:db];
       
        NSDictionary *database = [NSDictionary dictionaryWithContentsOfFile:[[root path] stringByAppendingPathComponent:@"database.plist"]];
        
        for (NSString *bid in apps)
        {
            NSNumber *uses = [[apps objectForKey:bid] objectForKey:@"uses"];
            if (uses == nil) uses = [NSNumber numberWithInt:0];
            NSNumber *active = [[apps objectForKey:bid] objectForKey:@"active"];
            if (active == nil) active = [NSNumber numberWithInt:0];
            NSNumber *passive = [[apps objectForKey:bid] objectForKey:@"passive"];
            if (passive == nil) passive = [NSNumber numberWithInt:0];
            NSNumber *total = [[apps objectForKey:bid] objectForKey:@"total"];
            if (total == nil) total = [NSNumber numberWithInt:0];
            
            NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bid];
            NSString *name = [[path lastPathComponent] stringByReplacingOccurrencesOfString:@".app" withString:@""];
            NSImage *img = [NSImage imageNamed:@"NSMultipleDocuments"];
            NSDictionary *meta = [self metadataFor:path];
            
            if (!name) name = [[bid componentsSeparatedByString:@"."] lastObject];
            
            if (path)
            {
                if ([defaults boolForKey:@"showExisting"] == NO) continue;
                img = [[NSWorkspace sharedWorkspace] iconForFile:path];
            }else{
                if ([defaults boolForKey:@"showNonExisting"] == NO) continue;
                path = @"";
            }
            
            NSDate *lastUse = [meta objectForKey:NSURLContentAccessDateKey];
            NSDate *dbLastUse = [[[database objectForKey:@"appsdb"] objectForKey:bid] objectForKey:@"lastuse"];
            if (dbLastUse) lastUse = dbLastUse;
            NSDate *dbFirstUse = [[[database objectForKey:@"appsdb"] objectForKey:bid] objectForKey:@"firstuse"];//will be nil many times

            [self.appsList addObject:[NSDictionary dictionaryWithObjectsAndKeys:name,@"name",bid,@"bid",passive,@"passive",active,@"active",total,@"total",img,@"icon",path,@"path",uses,@"uses",lastUse,@"lastuse",[meta objectForKey:NSURLCreationDateKey],@"creation",dbFirstUse,@"firstuse", nil]];

        }
        
        [self willChangeValueForKey:@"filteredAppsList"];
        [self.filteredAppsList setArray:[self filterList:_appsList forString:searchString]];
        NSArray *tableSort = [appsTable sortDescriptors];
        if (tableSort) [self.filteredAppsList sortUsingDescriptors:tableSort];
        [appsTable reloadData];
        [self didChangeValueForKey:@"filteredAppsList"];
    }];
    
}

-(NSOrderedSet*)dataSetForSettingsFrom:(NSOrderedSet*)allFiles
{

    if ([timeControl selectedSegment] == 0)
    {
        return allFiles;
    }
    else if ([timeControl selectedSegment] == 1)
    {
        NSString *currentDB = [[DataFunctions stringFromDateWithFormat:@"yyyyMM"] stringByAppendingString:@".plist"];
        return [NSOrderedSet orderedSetWithObject:currentDB];
    }
    else if ([timeControl selectedSegment] == 2)
    {
        if ([[endDatePicker dateValue] isEqualToDate:[startDatePicker dateValue]])
        {
            //1 month only
            NSString *currentDB = [[DataFunctions stringFromDate:[startDatePicker dateValue] format:@"yyyyMM"] stringByAppendingString:@".plist"];
            return [NSOrderedSet orderedSetWithObject:currentDB];
        }else{
            //more than one month
            NSMutableOrderedSet *matchingFiles = [NSMutableOrderedSet orderedSetWithCapacity:1];
            for (NSString *file in allFiles)
            {
                NSDate *fileDate = [DataFunctions dateFromString:[file stringByReplacingOccurrencesOfString:@".plist" withString:@""] format:@"yyyyMM"];
                if ( ([fileDate compare:[startDatePicker dateValue]] == NSOrderedDescending || [fileDate compare:[startDatePicker dateValue]] == NSOrderedSame)
                    && ([fileDate compare:[endDatePicker dateValue]] == NSOrderedAscending || [fileDate compare:[endDatePicker dateValue]] == NSOrderedSame)  )
                {
                    [matchingFiles addObject:file];
                }
            }
            return matchingFiles;
        }
    }
    return nil;
}


#pragma mark tools


-(NSDictionary*)metadataFor:(NSString*)file
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:1];
    if (file) {
        NSURL *url = [NSURL fileURLWithPath:file];
        NSError *error = nil;
        NSNumber *rsrc = nil;

        [url getResourceValue:&rsrc forKey:NSURLCreationDateKey error:&error];
        if (rsrc)[ret setObject:rsrc forKey:NSURLCreationDateKey];
        
        [url getResourceValue:&rsrc forKey:NSURLContentAccessDateKey error:&error];
        if (rsrc)[ret setObject:rsrc forKey:NSURLContentAccessDateKey];
        
        [url getResourceValue:&rsrc forKey:@"kMDItemUseCount" error:&error];
        if (rsrc)[ret setObject:rsrc forKey:@"kMDItemUseCount"];
        
    }
    return ret;
}



#pragma mark NSTableView datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView {
    return [_filteredAppsList count];
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex
{
	NSString *ident = [theColumn identifier];
    
    //if we have no sort descriptor for this column create one based on it's identifier (instead of setting it for each in IB,saves time and prevents errors)
    NSSortDescriptor *desc = [theColumn sortDescriptorPrototype];
    if ([desc key] == nil && ![ident isEqualToString:@"icon"])
    {
        if ([ident isEqualToString:@"total"] || [ident isEqualToString:@"firstuse"] || [ident isEqualToString:@"lastuse"] || [ident isEqualToString:@"creation"] || [ident isEqualToString:@"uses"])
        {
            NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:[theColumn identifier] ascending:NO selector:@selector(compare:)];
            [theColumn setSortDescriptorPrototype:sorter];
        }else{
            NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:[theColumn identifier] ascending:NO selector:@selector(caseInsensitiveCompare:)];
            [theColumn setSortDescriptorPrototype:sorter];
        }
    }
    
    //we need this man in the middle substitution for sorting to work properly if total was changed to active or passive
    if ([ident isEqualToString:@"total"])
    {
        NSString *key = @"total";
        if ([defaults boolForKey:@"showActiveCount"] != YES || [defaults boolForKey:@"showPassiveCount"] != YES)
        {
            if ([defaults boolForKey:@"showActiveCount"] == YES) key = @"active";
            if ([defaults boolForKey:@"showPassiveCount"] == YES)  key = @"passive";
        }
        NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:key ascending:NO selector:@selector(compare:)];
        [theColumn setSortDescriptorPrototype:sorter];
        //BUG, need a subsequent click
    }
    
    //return data
    NSDictionary *item = [_filteredAppsList objectAtIndex:rowIndex];
    
    if ([ident isEqualToString:@"icon"] && ![[item objectForKey:ident] isKindOfClass:[NSImage class]])
    {
        return nil;
    }
    
    if ([ident isEqualToString:@"total"])
    {
        if ([defaults boolForKey:@"showActiveCount"] != YES || [defaults boolForKey:@"showPassiveCount"] != YES)
        {
            if ([defaults boolForKey:@"showActiveCount"] == YES) return [MiscFunctions humanizeSec:[item objectForKey:@"active"]];
            if ([defaults boolForKey:@"showPassiveCount"] == YES) return [MiscFunctions humanizeSec:[item objectForKey:@"passive"]];
        }
        
        return [MiscFunctions humanizeSec:[item objectForKey:ident]];
    }
    
    if ([[item objectForKey:ident] isKindOfClass:[NSDate class]])
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
        return [formatter stringFromDate:[item objectForKey:ident]];
    }
    
    return [item objectForKey:ident];
}

- (void)tableView:(NSTableView *)theTableView didClickTableColumn:(NSTableColumn *)theColumn
{
    //NSLog(@"Sorting by %@",[theColumn identifier]);
}

- (void)tableView:(NSTableView *)theTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSArray *tableSort = [theTableView sortDescriptors];
    if (tableSort)
    {
        [self willChangeValueForKey:@"filteredAppsList"];
        [self.filteredAppsList sortUsingDescriptors:tableSort];
        [theTableView reloadData];
        [theTableView deselectAll:self];
        //NSLog(@"Sorted by %@",[tableSort description]);
        [self didChangeValueForKey:@"filteredAppsList"];
    }
}

#pragma mark NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    NSString *string = [[aNotification object] stringValue];
    if ([searchTimer isValid]) {
        [searchTimer invalidate];
        searchTimer = nil;
    }
    searchTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(searchStart:) userInfo:string repeats:NO];
}

-(void)searchStart:(NSTimer*)timer
{
    [self willChangeValueForKey:@"filteredAppsList"];
    NSString *string = [timer userInfo];
    if ([string length] > 0) {
        [self.filteredAppsList setArray:[self filterList:_appsList forString:string]];
    }else{
        [self.filteredAppsList setArray:_appsList];
    }
    NSArray *tableSort = [appsTable sortDescriptors];
    [self.filteredAppsList sortUsingDescriptors:tableSort];
    [searchString setString:string];
    searchTimer = nil;
    [appsTable reloadData];
    [self didChangeValueForKey:@"filteredAppsList"];
}

-(NSArray*)filterList:(NSArray*)source forString:(NSString*)query
{
    
    NSInteger countTotal = 0;
    NSInteger launchTotal = 0;
    
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary *dict in source)
    {
        if ([query length] < 2 ||
            [[dict objectForKey:@"bid"] rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [[dict objectForKey:@"name"] rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [[dict objectForKey:@"path"] rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound
            ) {
            countTotal += [[dict objectForKey:@"total"] integerValue];
            launchTotal += [[dict objectForKey:@"uses"] integerValue];
            [ret addObject:dict];
        }
    }
    
    [settingsText setStringValue:[NSString stringWithFormat:@"Showing %lu of %lu apps with total %@ and %lu uses.",(unsigned long)[ret count],(unsigned long)[_appsList count],[MiscFunctions humanizeSec:[NSNumber numberWithInteger:countTotal]],launchTotal]];
    
    return ret;
}

#pragma mark VATableViewDelegate

- (NSMenu *)menuForClickedRow:(NSInteger)row inTable:(NSTableView *)theTableView
{
    
    NSMenu *ret = nil;
    
    if ([_filteredAppsList count] <= row) return nil;
    NSDictionary *item = [_filteredAppsList objectAtIndex:row];
    
    NSString *name = [item objectForKey:@"name"];
    NSString *path = [item objectForKey:@"path"];
    NSString *bid = [item objectForKey:@"bid"];
    if (name) {
        ret = [[NSMenu alloc] initWithTitle:name];
        
        NSMenuItem *menuItem = [ret addItemWithTitle:@"Graph" action:@selector(graph:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setToolTip:bid];
        
        if ([path length] > 0) {
            NSMenuItem *menuItem = [ret addItemWithTitle:@"Reveal in Finder" action:@selector(revealInFinder:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [menuItem setToolTip:path];
        }

    }
    
    //NSLog(@"Right clicked %ld",row);
    return ret;
}

-(void)revealInFinder:(NSMenuItem*)sender
{
    NSString *path = [sender toolTip];
    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
}

-(void)graph:(NSMenuItem*)sender
{
    NSString *bid = [sender toolTip];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GraphControllerEvent" object:@"add" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:bid,@"bid", nil]];
}

@end

