//
//  RemoteListener.h
//  Applications
//
//  Created by Vlad Alexa on 6/28/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <IOKit/hid/IOHIDLib.h>

@interface RemoteListener : NSObject{
    
	IOHIDDeviceInterface** hidDeviceInterface;
	IOHIDQueueInterface**  queue;    
	CFRunLoopSourceRef	 eventSource;
    dispatch_block_t monitor;    
}

- (void)setMonitor:(dispatch_block_t)aBlock;
-(void)handleEvent;
- (void)addMonitorForRemoteEvents:(void (^)(void))block;
- (IOHIDQueueInterface**) queue;
- (BOOL) isRemoteAvailable;
- (io_object_t) newRemoteDevice;
- (BOOL) isListeningToRemote;
- (void) openRemoteControlDevice;
- (void) closeRemoteControlDevice;
- (IOHIDDeviceInterface**) createInterfaceForDevice: (io_object_t) hidDevice;
- (BOOL) openDevice;
-(void)remoteControlAvailable:(NSNotification*)notif;

@end
