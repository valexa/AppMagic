//
//  CloudFunctions.h
//  App Magic
//
//  Created by Vlad Alexa on 2/9/14.
//  Copyright (c) 2014 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CloudFunctions : NSObject

+(NSURL*)getDocsPathFor:(NSString*)fileName containerID:(NSString*)containerID;
+(void)scanDirectory:(NSURL *)directory completionHandler:(void(^)(NSOrderedSet *foundFiles))completionHandler;
+(BOOL)coordonatedWrite:(NSDictionary*)dict at:(NSURL*)url;
+(NSDictionary*)coordonatedReadURL:(NSURL*)url;
+(BOOL)isObjectValidForPlist:(id)object;

@end
