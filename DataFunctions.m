//
//  DataFunctions.m
//  App Magic
//
//  Created by Vlad Alexa on 2/9/14.
//  Copyright (c) 2014 Next Design. All rights reserved.
//

#import "DataFunctions.h"

#import "CloudFunctions.h"

@implementation DataFunctions

+(NSString*)currentDB
{
    return [[DataFunctions dateWithFormat:@"yyyyMM" date:[NSDate date]] stringByAppendingString:@".plist"];
}

+(NSDictionary*)appsForMachine:(NSString*)machine db:(NSDictionary*)db
{
    NSMutableDictionary *apps = [NSMutableDictionary dictionaryWithCapacity:1];
    
    if ([machine isEqualToString:@"All Machines"])
    {
        for (NSString *machine in db)
        {
            NSDictionary *m = [db objectForKey:machine];
            for (NSString *bid in m)
            {
                if (![apps objectForKey:bid]) {
                    [apps setObject:[m objectForKey:bid] forKey:bid];
                }else{
                    [apps setObject:[DataFunctions merge:[m objectForKey:bid] with:[apps objectForKey:bid]] forKey:bid];
                }
            }
        }
    }else{
        [apps setDictionary:[db objectForKey:machine]];
    }
    return apps;
}


+(NSDictionary*)dataAtPath:(NSURL*)root list:(NSOrderedSet*)fileList
{
    
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:1];
    for (NSString *file in fileList)
    {
        NSURL *url = [NSURL fileURLWithPath:[[root path] stringByAppendingPathComponent:file]];
        NSDictionary *month_machines = [CloudFunctions coordonatedReadURL:url];
        NSDictionary *month = [month_machines objectForKey:@"machines"];
        for (NSString *machine in month)
        {
            NSDictionary *this_machine = [month objectForKey:machine];
            NSMutableDictionary *ret_machine = [NSMutableDictionary dictionaryWithDictionary:[ret objectForKey:machine]];
            for (NSString *app in this_machine)
            {
                [ret_machine setObject:[DataFunctions merge:[ret_machine objectForKey:app] with:[this_machine objectForKey:app]] forKey:app];
            }
            [ret setObject:ret_machine forKey:machine];
        }
    }
    return ret;
}

+(NSDictionary*)mergedLastDataAtPath:(NSURL*)root
{
    NSString *previousDB = [[self stringFromDate:[self lastMonth] format:@"yyyyMM"] stringByAppendingString:@".plist"];
    NSString *currentDB = [[self stringFromDateWithFormat:@"yyyyMM"] stringByAppendingString:@".plist"];
    
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:1];
    NSURL *prevURL = [NSURL fileURLWithPath:[[root path] stringByAppendingPathComponent:previousDB]];
    NSURL *currURL = [NSURL fileURLWithPath:[[root path] stringByAppendingPathComponent:currentDB]];
    NSDictionary *prev = [CloudFunctions coordonatedReadURL:prevURL];
    NSDictionary *curr = [CloudFunctions coordonatedReadURL:currURL];
    for (NSString *machine in [curr objectForKey:@"machines"]) {
        NSMutableDictionary *ret_machine = [NSMutableDictionary dictionaryWithCapacity:1];
        NSDictionary *prev_m = [[prev objectForKey:@"machines"] objectForKey:machine];
        NSDictionary *curr_m = [[curr objectForKey:@"machines"] objectForKey:machine];
        for (NSString *app in curr_m) {
            NSDictionary *prev_a = [prev_m objectForKey:app];
            NSMutableDictionary *curr_a = [NSMutableDictionary dictionaryWithDictionary:[curr_m objectForKey:app]];
            NSInteger active = [[curr_a objectForKey:@"active"] integerValue] - [[prev_a objectForKey:@"active"] integerValue];
            NSInteger passive = [[curr_a objectForKey:@"passive"] integerValue] - [[prev_a objectForKey:@"passive"] integerValue];
            [curr_a setObject:[NSNumber numberWithInteger:active] forKey:@"active"];
            [curr_a setObject:[NSNumber numberWithInteger:passive] forKey:@"passive"];
            [ret_machine setObject:curr_a forKey:app];
        }
        [ret setObject:ret_machine forKey:machine];
    }
    return ret;
}

+(NSDictionary*)merge:(NSDictionary*)first with:(NSDictionary*)second
{
    
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithDictionary:second];
    
    NSInteger active = [[first objectForKey:@"active"] integerValue];
    NSInteger passive = [[first objectForKey:@"passive"] integerValue];
    NSInteger uses = [[first objectForKey:@"uses"] integerValue];
    
    NSInteger ret_active = [[ret objectForKey:@"active"] integerValue];
    NSInteger ret_passive = [[ret objectForKey:@"passive"] integerValue];
    NSInteger ret_uses = [[ret objectForKey:@"uses"] integerValue];
    
    [ret setObject:[NSNumber numberWithInteger:active+ret_active+passive+ret_passive] forKey:@"total"];
    [ret setObject:[NSNumber numberWithInteger:active+ret_active] forKey:@"active"];
    [ret setObject:[NSNumber numberWithInteger:passive+ret_passive] forKey:@"passive"];
    [ret setObject:[NSNumber numberWithInteger:uses+ret_uses] forKey:@"uses"];
    
    return ret;
}

#pragma mark dates

+(NSString *)dateWithFormat:(NSString*)format date:(NSDate*)date
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:format];
    return [formatter stringFromDate:date];
}

+(NSDate *)firstMonth
{
    NSURL *root = [CloudFunctions getDocsPathFor:@"" containerID:@"N7N53EAPBD.com.vladalexa.appmagic"];
    NSError *error = nil;
    NSArray *filelist = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:root includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    
    if (error) {
        NSLog(@"%@",error);
    }else{
        if ([filelist count] > 0)
        {
            NSURL *url = [filelist objectAtIndex:0];
            NSString *dateString = [[url lastPathComponent] stringByReplacingOccurrencesOfString:@".plist" withString:@""];
            return [self dateFromString:dateString format:@"yyyyMM"];
        }
    }
    
    return [NSDate date];
}

+(NSDate *)monthBefore:(NSDate*)date
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSMonthCalendarUnit | NSYearCalendarUnit ) fromDate:date];
    [components setMonth:([components month] - 1)];
    return [cal dateFromComponents:components];
}

+(NSDate *)monthAfter:(NSDate*)date
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSMonthCalendarUnit | NSYearCalendarUnit ) fromDate:date];
    [components setMonth:([components month] + 1)];
    return [cal dateFromComponents:components];
}

+(NSDate *)lastMonth
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSMonthCalendarUnit | NSYearCalendarUnit ) fromDate:[NSDate date]];
    [components setMonth:([components month] - 1)];
    return [cal dateFromComponents:components];
}

+(NSDate *)dateFromString:(NSString*)string format:(NSString*)format
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:format];
    return [formatter dateFromString:string];
}

+(NSString *)stringFromDate:(NSDate*)date format:(NSString*)format
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:format];
    return [formatter stringFromDate:date];
}

+(NSString *)stringFromDateWithFormat:(NSString*)format
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:format];
    return [formatter stringFromDate:[NSDate date]];
}

@end
