//
//  CloudFunctions.m
//  App Magic
//
//  Created by Vlad Alexa on 2/9/14.
//  Copyright (c) 2014 Next Design. All rights reserved.
//

#import "CloudFunctions.h"

#import "MiscFunctions.h"

@implementation CloudFunctions


+ (NSURL*)getDocsPathFor:(NSString*)fileName containerID:(NSString*)containerID
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSURL *documents = [[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    NSURL *localURL = [[documents URLByResolvingSymlinksInPath] URLByAppendingPathComponent:@"App Magic"];
    if (![fm fileExistsAtPath:[localURL path]]) {
        NSError *error;
        if (![fm createDirectoryAtURL:localURL withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSLog(@"%@",error);
        }else{
            NSLog(@"Created %@",[localURL path]);
        }
    }
    localURL =  [localURL URLByAppendingPathComponent:fileName]; //no cloud
    
    if (![fm respondsToSelector:@selector(URLForUbiquityContainerIdentifier:)]) return localURL; //not Lion
    
    NSURL *rootURL = [fm URLForUbiquityContainerIdentifier:containerID];
    if (rootURL)
    {
        NSURL *directoryURL = [rootURL URLByAppendingPathComponent:@"Documents"];
        [fm createDirectoryAtURL:directoryURL withIntermediateDirectories:NO attributes:nil error:nil];
        NSURL *cloudURL = [directoryURL URLByAppendingPathComponent:fileName];
        if ([fileName length] > 0)
        {
            if ([fm fileExistsAtPath:[localURL path]])
            {
                if ([fm fileExistsAtPath:[cloudURL path]])
                {
                    NSError *error;
                    if (![fm removeItemAtURL:localURL error:&error])
                    {
                        NSLog(@"Error deleting %@",[localURL path]);
                    }else{
                        NSLog(@"Deleted %@",[localURL path]);
                        [MiscFunctions deliverNotification:@"iCloud enabled" text:@"App Magic is now using iCloud to store data"];                                            
                    }
                }else{
                    //migrate file to iCloud once it was turned on and the file is still local
                    NSError *error;
                    if(![fm setUbiquitous:YES itemAtURL:localURL destinationURL:cloudURL error:&error])
                    {
                        NSLog(@"Error making %@ ubiquituous at %@ (%@)",[localURL path],[cloudURL path],[error description]);
                        return  localURL;
                    }else{
                        NSLog(@"Made %@ ubiquituous at %@",[localURL lastPathComponent],[cloudURL path]);
                        [MiscFunctions deliverNotification:@"iCloud enabled" text:@"Data for App Magic was migrated to iCloud"];
                    }
                }
            }
        }
        return cloudURL;
    }
    return  localURL;
}


+ (void)scanDirectory:(NSURL *)directory completionHandler:(void(^)(NSOrderedSet *foundFiles))completionHandler
{
    
    NSMutableOrderedSet *foundFiles = [NSMutableOrderedSet orderedSet];
    
    // create file coordinator to request folder read access
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    NSError *readError = nil;
    
    [coordinator coordinateReadingItemAtURL:directory options:NSFileCoordinatorReadingWithoutChanges error:&readError byAccessor: ^(NSURL *readURL){
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSError *error = nil;
        NSArray *fileURLs = [fileManager contentsOfDirectoryAtURL:readURL includingPropertiesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] options:0 error:&error];
        if (!fileURLs) {
            NSLog(@"No files under %@",[readURL path]);
            return;
        }
        
        for (NSURL *currentFileURL in fileURLs) {
            if ([[currentFileURL pathExtension] isEqualToString:@"plist"])
            {
                if ([[currentFileURL lastPathComponent] isEqualToString:@"database.plist"]) continue;//its gonna be a problem if the Documents forlder contains plists with a machines array that are not logs
                if ([[currentFileURL lastPathComponent] isEqualToString:@"achievements.plist"]) continue;//its gonna be a problem if the Documents forlder contains plists with a machines array that are not logs
                [foundFiles addObject:[currentFileURL lastPathComponent]];
            }
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        if (readError) {
            completionHandler(nil);
        }
        completionHandler(foundFiles);
    });
    
}

+(BOOL)coordonatedWrite:(NSDictionary*)dict at:(NSURL*)url
{
    if (![CloudFunctions isObjectValidForPlist:dict])
    {
        NSLog(@"Not serializable to plist %@",dict);
        return NO;
    }
    
    NSError *writeError = nil;
    __block BOOL success = NO;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForReplacing error:&writeError byAccessor:^(NSURL* dbURL)
     {
         success = [dict writeToURL:url atomically:YES];
     }];
    
    if (!success) {
        if (writeError) {
            NSLog(@"NSFileCoordinator Error writing %@",[url path]);
        }else{
            NSLog(@"writeToURL Error writing %@",[url path]);
        }
    }else{
        //NSLog(@"writeToURL SUCCESS writing %@",[url path]);
    }
    
    return success;
    
}

+(NSDictionary*)coordonatedReadURL:(NSURL*)url
{
    NSError *readError = nil;
    __block NSDictionary *ret = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges error:&readError byAccessor:^(NSURL* dbURL)
     {
         ret = [NSDictionary dictionaryWithContentsOfURL:url];
     }];
    
    if (!ret) {
        if (readError) {
            NSLog(@"NSFileCoordinator Error reading %@",[url path]);
            [MiscFunctions deliverNotification:@"iCloud ERROR" text:[readError localizedFailureReason]];
        }else{
            NSLog(@"dictionaryWithContentsOfURL Error reading %@",[url path]);
        }
    }else{
        //NSLog(@"dictionaryWithContentsOfURL SUCCESS reading %@",[url path]);
    }
    
    return ret;
    
}

+(BOOL)isObjectValidForPlist:(id)object
{
    NSString *err;
    NSData *dataRep = [NSPropertyListSerialization dataFromPropertyList:object format:NSPropertyListXMLFormat_v1_0 errorDescription:&err];
    if (!dataRep)
    {
        NSLog(@"%@",err);
        return NO;
    }
    return YES;
}

@end
