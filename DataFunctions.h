//
//  DataFunctions.h
//  App Magic
//
//  Created by Vlad Alexa on 2/9/14.
//  Copyright (c) 2014 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataFunctions : NSObject

+(NSString*)currentDB;
+(NSDictionary*)appsForMachine:(NSString*)machine db:(NSDictionary*)db;
+(NSDictionary*)dataAtPath:(NSURL*)root list:(NSOrderedSet*)fileList;
+(NSDictionary*)mergedLastDataAtPath:(NSURL*)root;
+(NSDictionary*)merge:(NSDictionary*)first with:(NSDictionary*)second;

+(NSString *)dateWithFormat:(NSString*)format date:(NSDate*)date;
+(NSDate *)firstMonth;
+(NSDate *)monthBefore:(NSDate*)date;
+(NSDate *)monthAfter:(NSDate*)date;
+(NSDate *)lastMonth;
+(NSDate *)dateFromString:(NSString*)string format:(NSString*)format;
+(NSString *)stringFromDate:(NSDate*)date format:(NSString*)format;
+(NSString *)stringFromDateWithFormat:(NSString*)format;

@end
