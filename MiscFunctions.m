//
//  MiscFunctions.m
//  App Magic Helper
//
//  Created by Vlad Alexa on 2/11/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import "MiscFunctions.h"

@implementation MiscFunctions

+(void)checkPasteBoard:(NSPasteboard*)pboard
{
    for (NSPasteboardItem *item in [pboard pasteboardItems])
    {
        NSArray *types = [item types];
        NSString *type = [item availableTypeFromArray:types];
        NSString *string = [item stringForType:type];
        NSLog(@"%lu items %lu types, available %@ of count %lu",(unsigned long)[[pboard pasteboardItems] count],(unsigned long)[types count],type,(unsigned long)[string length]);
    }
}

+(void)pasteboardFilesToDir:(NSString*)dirPath
{
    NSPasteboard *namesPB = [NSPasteboard pasteboardWithName:@"com.vladalexa.appmagic.fileNames"];
    NSPasteboard *dataPB = [NSPasteboard pasteboardWithName:@"com.vladalexa.appmagic.fileData"];
    NSArray *fileNames = [namesPB readObjectsForClasses:[NSArray arrayWithObject:[NSString class]] options:nil];
    NSMutableArray *fileDatas = [NSMutableArray arrayWithArray:[dataPB pasteboardItems]];

    if ([fileDatas count] == [fileNames count]+1) [fileDatas removeObjectAtIndex:0]; //.DS_Store
    
    for (NSString *filename in fileNames)
    {
        NSInteger index = [fileNames indexOfObject:filename];
        NSPasteboardItem *filedata = [fileDatas objectAtIndex:index];
        NSString *fullPath = [dirPath stringByAppendingPathComponent:filename];
        BOOL success = [[filedata dataForType:@"public.plist"] writeToFile:fullPath atomically:YES];
        if (!success) {
            NSLog(@"Error writing %@",fullPath);
        }
    }
}

+(void)dirToPasteboard:(NSString*)dirPath
{
    NSPasteboard *dataPB = [NSPasteboard pasteboardWithName:@"com.vladalexa.appmagic.fileData"];
    [dataPB declareTypes:[NSArray arrayWithObject:@"public.plist"] owner:nil];
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:1];
    
    NSError *error;
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSArray *filelist = [filemgr contentsOfDirectoryAtPath:dirPath error:&error];
    NSMutableArray *files = [NSMutableArray arrayWithCapacity:1];
    
    if(!filelist)
    {
        NSLog(@"%@",error);
    }else{
        for (NSString *lastPathComponent in filelist)
        {
            if ([lastPathComponent hasPrefix:@"."]) continue; // Ignore file.
            NSString *fullPath = [dirPath stringByAppendingPathComponent:lastPathComponent];
            BOOL isDir;
            BOOL exists = [filemgr fileExistsAtPath:fullPath isDirectory:&isDir];
            if (exists && !isDir)
            {
                NSData *data = [NSData dataWithContentsOfFile:fullPath options:NSDataReadingMappedIfSafe error:&error];
                if (data) {
                    NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
                    [item setData:data forType:@"public.plist"];
                    [items addObject:item];
                    [files addObject:lastPathComponent];
                }else{
                    NSLog(@"%@",error);
                }
            }
        }
        [dataPB writeObjects:items];
        
        NSPasteboard *namesPB = [NSPasteboard pasteboardWithName:@"com.vladalexa.appmagic.fileNames"];
        [namesPB clearContents];
        [namesPB writeObjects:filelist];
    }
}

+(void)stringToPasteboard:(NSString*)string
{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:@"com.vladalexa.appmagic"];
    [pasteboard clearContents];
    [pasteboard writeObjects:[NSArray arrayWithObject:string]];
}

+(NSString*)stringFromPasteboard
{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:@"com.vladalexa.appmagic"];
    if ([pasteboard canReadObjectForClasses:[NSArray arrayWithObject:[NSString class]] options:nil]) {
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:[NSArray arrayWithObject:[NSString class]] options:nil];
        if ([objectsToPaste count] == 1)
        {
            return [objectsToPaste objectAtIndex:0];
        }else{
            NSLog(@"No data in pasteboard");
        }
        [pasteboard clearContents];        
    }
    return nil;
}

+(NSArray*)plistToArray:(NSString*)encoded
{
    //give determined people plenty of chances to hack the achievements
    NSArray *ret = nil;
    
    NSError *err = nil;
    NSString *temp = [NSString stringWithFormat:@"%@a",NSTemporaryDirectory()];
    [[MiscFunctions getString:encoded] writeToFile:temp atomically:YES encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        NSLog(@"%@",err);
    }else{
        ret = [NSArray arrayWithContentsOfFile:temp];
        [[NSFileManager defaultManager] removeItemAtPath:temp error:&err];
        if (err) NSLog(@"%@",err);
    }
    return ret;
}

+(NSString*)arrayToPlist:(NSArray*)array
{
    //give determined people plenty of chances to hack the achievements
    
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@a",NSTemporaryDirectory()]];
    [array writeToURL:url atomically:YES];
    
    NSError *err = nil;
    NSString *decoded = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        NSLog(@"%@",err);
        [[NSFileManager defaultManager] removeItemAtURL:url error:&err];
        if (err) NSLog(@"%@",err);
    }else{
        return [MiscFunctions setString:decoded];
    }
    return  nil;
}


+ (NSString *) getString:(NSString *)str
{
    if (([str length] % 2) != 0) return nil;
    
    NSMutableString *ret = [NSMutableString string];
    
    for (NSInteger i = 0; i < [str length]; i += 2)
    {
        NSString *character = [str substringWithRange: NSMakeRange(i, 2)];
        int value = 0;
        sscanf([character cStringUsingEncoding:NSASCIIStringEncoding], "%x", &value);
        [ret appendFormat:@"%c", (char)value];
    }
    
    return ret;
}

+ (NSString *) setString:(NSString *)str
{
    NSUInteger len = [str length];
    unichar *chars = malloc(len * sizeof(unichar));
    [str getCharacters:chars];
    
    NSMutableString *ret = [[NSMutableString alloc] init];
    
    for(NSUInteger i = 0; i < len; i++ )
    {
        [ret appendFormat:@"%02X", chars[i]];
    }
    free(chars);
    
    return ret;
}

+(BOOL)deliverNotification:(NSString*)title text:(NSString*)text
{
    NSUserNotification *notif = [[NSUserNotification alloc] init];
    if (notif) {
        //notif.contentImage = [NSImage imageNamed:@"achiev"];
        [notif setTitle:title];
        [notif setInformativeText:text];
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        [center deliverNotification:notif];
        return YES;
    }
    return NO;
}

+(BOOL)achievementNotification:(NSString*)title subtitle:(NSString*)subtitle text:(NSString*)text
{
    NSUserNotification *notif = [[NSUserNotification alloc] init];
    if (notif) {
        //notif.contentImage = [NSImage imageNamed:@"achiev"];
        notif.hasActionButton = YES;
        notif.actionButtonTitle = @"Show me";
        [notif setTitle:title];
        [notif setSubtitle:subtitle];
        [notif setInformativeText:text];
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        [center deliverNotification:notif];
        return YES;
    }
    return NO;
}

+(NSString *)humanizeSec:(NSNumber*)num
{
    double sec = [num doubleValue];
	int d = 0;
	int h = 0;
	int m = 0;
	NSString *ret = @"";
    
	if (sec == 1) return @"1 second";
	if (sec < 60) return [NSString stringWithFormat:@"%.0f seconds",sec];
	if (sec >= 86400)
    {
		d = floor(sec / 60 / 60 / 24);
		ret = [ret stringByAppendingFormat:@"%d day", d];
		if (d >= 2) ret = [ret stringByAppendingString:@"s"];
		ret = [ret stringByAppendingString:@", "];
	}
	if (sec >= 3600 ) {
		h = floor((sec-(d*86400)) / 60 / 60);
		ret = [ret stringByAppendingFormat:@"%d hour",h];
		if (h >= 2) ret = [ret stringByAppendingString:@"s"];
		ret = [ret stringByAppendingString:@", "];
	}
	if (sec >= 60) {
		m = floor((sec-(d*86400)-(h*3600)) / 60);
		ret = [ret stringByAppendingFormat:@"%d min",m];
		//if (m >= 2) ret = [ret stringByAppendingString:@"s"];
	}
	return ret;
}

+(NSArray *)alternatingColors:(float)count fromColor:(NSColor*)color
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    
    BOOL alternateColor = NO;
    for (int i = 0; i < count; i++)
    {
        if (alternateColor)
        {
            [ret addObject:[color colorWithAlphaComponent:0.85]];
            alternateColor = NO;
        }else{
            [ret addObject:color];
            alternateColor = YES;
        }
    }
    return ret;
}

+(NSArray *)rainbowColors:(float)count reverse:(BOOL)reverse grayscale:(BOOL)grayscale
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    
    for (float i = 0; i < count; i++)
    {
        float hue = (count-i)/count;
        NSColor *color = [NSColor colorWithDeviceHue:hue saturation:0.4 brightness:0.7 alpha:1.0];
        if (grayscale) color = [NSColor colorWithDeviceWhite:hue/1.5 alpha:0.5];
        [ret addObject:color];
    }
    
    if (reverse) return [MiscFunctions reversedArray:ret];
    return ret;
}

+ (NSArray *)reversedArray:(NSArray*)array
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:[array count]];
    NSEnumerator *enumerator = [array reverseObjectEnumerator];
    for (id element in enumerator) {
        [ret addObject:element];
    }
    return ret;
}

+(void) accountForLowerLeftAnchor:(CALayer*)layer
{
    CGRect frame = layer.frame;
    CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    layer.position = center;
    layer.anchorPoint = CGPointMake(0.5, 0.5);
}


@end
