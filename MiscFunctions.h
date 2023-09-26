//
//  MiscFunctions.h
//  App Magic Helper
//
//  Created by Vlad Alexa on 2/11/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MiscFunctions : NSObject

+(void)checkPasteBoard:(NSPasteboard*)pboard;
+(void)pasteboardFilesToDir:(NSString*)dirPath;
+(void)dirToPasteboard:(NSString*)dirPath;
+(void) stringToPasteboard:(NSString*)string;
+(NSString*) stringFromPasteboard;
+(NSArray*) plistToArray:(NSString*)encoded;
+(NSString*) arrayToPlist:(NSArray*)array;
+(NSString *) getString:(NSString *)str;
+(NSString *) setString:(NSString *)str;
+(BOOL)deliverNotification:(NSString*)title text:(NSString*)text;
+(BOOL)achievementNotification:(NSString*)title subtitle:(NSString*)subtitle text:(NSString*)text;
+(NSString *)humanizeSec:(NSNumber*)num;
+(NSArray *)alternatingColors:(float)count fromColor:(NSColor*)color;
+(NSArray *)rainbowColors:(float)count reverse:(BOOL)reverse grayscale:(BOOL)grayscale;
+ (NSArray *)reversedArray:(NSArray*)array;
+(void) accountForLowerLeftAnchor:(CALayer*)layer;

@end
