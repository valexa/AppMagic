//
//  RemoteListener.m
//  Applications
//
//  Created by Vlad Alexa on 6/28/12.
//  Copyright (c) 2012 Next Design. All rights reserved.
//

#import "RemoteListener.h"

//#include <IOKit/hid/IOHIDUsageTables.h>
//kHIDUsage_Csmr_PlayOrPause

#import <IOKit/IOKitLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/hid/IOHIDKeys.h>

@implementation RemoteListener


static void QueueCallbackFunction(void* target,  IOReturn result, void* refcon, void* sender) {	
	
	if (target == NULL) {
		NSLog(@"QueueCallbackFunction called with invalid target!");
		return;
	}
    
	RemoteListener* remote = (__bridge RemoteListener*)target;
	IOHIDEventStruct event;	   
	AbsoluteTime 	 zeroTime = {0,0};    
	while (result == kIOReturnSuccess)	{
		result = (*[remote queue])->getNextEvent([remote queue], &event, zeroTime, 0);		
		if ( result != kIOReturnSuccess )continue;
    }    

	[remote handleEvent];
	
}


- (id)init
{
    self = [super init];
    if (self) {
        
		hidDeviceInterface = NULL;
        eventSource = NULL;
   		queue = NULL;
        
        if ([self isRemoteAvailable]) [self openRemoteControlDevice];
        
    }
    return self;
}

- (void)setMonitor:(dispatch_block_t)aBlock
{
    monitor = [aBlock copy];
}

- (void) dealloc { 
	[self closeRemoteControlDevice];
}

-(void)handleEvent
{
    monitor();
}

- (void)addMonitorForRemoteEvents:(void (^)(void))block
{
    [self setMonitor:block];
}

- (IOHIDQueueInterface**) queue {
	return queue;
}

- (BOOL) isRemoteAvailable {	
	io_object_t hidDevice = [self newRemoteDevice];
	if (hidDevice != 0) {
		IOObjectRelease(hidDevice);
		return YES;
	} else {
		return NO;		
	}
}

- (io_object_t) newRemoteDevice {
	CFMutableDictionaryRef hidMatchDictionary = NULL;
	IOReturn ioReturnValue = kIOReturnSuccess;	
	io_iterator_t hidObjectIterator = 0;
	io_object_t	hidDevice = 0;
	
	// Set up a matching dictionary to search the I/O Registry by class
	// name for all HID class devices
	hidMatchDictionary = IOServiceMatching("AppleIRController");
	
	// Now search I/O Registry for matching devices.
	ioReturnValue = IOServiceGetMatchingServices(kIOMasterPortDefault, hidMatchDictionary, &hidObjectIterator);
	
	if (hidObjectIterator != 0) {
		if (ioReturnValue == kIOReturnSuccess) {
			hidDevice = IOIteratorNext(hidObjectIterator);
		}
		// release the iterator
		IOObjectRelease(hidObjectIterator);
	}
	
	// Returned value must be released by the caller when it is finished
	return hidDevice;
}


- (BOOL) isListeningToRemote {
	return (hidDeviceInterface != NULL && queue != NULL);	
}


- (void) openRemoteControlDevice 
{
	if (hidDeviceInterface != NULL) return;    
    
	io_object_t hidDevice = [self newRemoteDevice];
	if (hidDevice == 0) return;
	
	if ([self createInterfaceForDevice:hidDevice] == NULL) {
		goto error;
	}
	
	if ([self openDevice]) {
        //NSLog(@"Opened AppleIRController remote device");
	}else {
		goto error;        
    }
	goto cleanup;
	
error:
	[self closeRemoteControlDevice];
	
cleanup:	
	IOObjectRelease(hidDevice);	
}

- (void) closeRemoteControlDevice 
{
	if (hidDeviceInterface == NULL) return;    
	
	if (eventSource != NULL) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), eventSource, kCFRunLoopDefaultMode);
		CFRelease(eventSource);
		eventSource = NULL;
	}
    
	if (queue != NULL) {
		(*queue)->stop(queue);		
		
		//dispose of queue
		(*queue)->dispose(queue);		
		
		//release the queue we allocated
		(*queue)->Release(queue);	
		
		queue = NULL;
	}    

	if (hidDeviceInterface != NULL) {
		//close the device
		(*hidDeviceInterface)->close(hidDeviceInterface);
		
		//release the interface	
		(*hidDeviceInterface)->Release(hidDeviceInterface);
		
		hidDeviceInterface = NULL;
	}
	
}

- (IOHIDDeviceInterface**) createInterfaceForDevice: (io_object_t) hidDevice {
	io_name_t				className;
	IOCFPlugInInterface**   plugInInterface = NULL;
	HRESULT					plugInResult = S_OK;
	SInt32					score = 0;
	IOReturn				ioReturnValue = kIOReturnSuccess;
	
	hidDeviceInterface = NULL;
	
	ioReturnValue = IOObjectGetClass(hidDevice, className);
	
	if (ioReturnValue != kIOReturnSuccess) {
		NSLog(@"Error: Failed to get class name.");
		return NULL;
	}
	
	ioReturnValue = IOCreatePlugInInterfaceForService(hidDevice,
													  kIOHIDDeviceUserClientTypeID,
													  kIOCFPlugInInterfaceID,
													  &plugInInterface,
													  &score);
	if (ioReturnValue == kIOReturnSuccess)
	{
		//Call a method of the intermediate plug-in to create the device interface
		plugInResult = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOHIDDeviceInterfaceID), (LPVOID) &hidDeviceInterface);
		
		if (plugInResult != S_OK) {
			NSLog(@"Error: Couldn't create HID class device interface");
		}
		// Release
		if (plugInInterface) (*plugInInterface)->Release(plugInInterface);
	}
	return hidDeviceInterface;
}

- (BOOL) openDevice {
	
	IOHIDOptionsType openMode = kIOHIDOptionsTypeNone;
	IOReturn ioReturnValue = (*hidDeviceInterface)->open(hidDeviceInterface, openMode);	
	
	if (ioReturnValue == KERN_SUCCESS) {	        
		queue = (*hidDeviceInterface)->allocQueue(hidDeviceInterface);
		if (queue) {
            HRESULT	result = (*queue)->create(queue, 0, 12);	//depth: maximum number of elements in queue before oldest elements in queue begin to be lost.
			if (result == kIOReturnSuccess) {
                //add element
                for (int i = 1; i < 30; i++) {
                    (*queue)->addElement(queue, (IOHIDElementCookie)i, 0);                                    
                }
				// add callback for async events			
				ioReturnValue = (*queue)->createAsyncEventSource(queue, &eventSource);			
				if (ioReturnValue == KERN_SUCCESS) {
					ioReturnValue = (*queue)->setEventCallout(queue,QueueCallbackFunction, (__bridge void *)(self), NULL);
					if (ioReturnValue == KERN_SUCCESS) {
						CFRunLoopAddSource(CFRunLoopGetCurrent(), eventSource, kCFRunLoopDefaultMode);
						//start data delivery to queue
						(*queue)->start(queue);	
						return YES;
					} else {
						NSLog(@"Error when setting event callback");
					}
				} else {
					NSLog(@"Error when creating async event source");
				}
			} else {
				NSLog(@"Error when creating queue");
			}
		} else {
			NSLog(@"Error when allocing queue");
		}   
	} else if (ioReturnValue == kIOReturnExclusiveAccess) {        
        NSLog(@"the remote device is used exclusively by another application");		
		NSDistributedNotificationCenter* defaultCenter = [NSDistributedNotificationCenter defaultCenter];
		[defaultCenter addObserver:self selector:@selector(remoteControlAvailable:) name:@"mac.remotecontrols.FinishedUsingRemoteControl" object:nil];
    } else {
        NSLog(@"Error when opening device");    
    }
    
	return NO;				
}

-(void)remoteControlAvailable:(NSNotification*)notif
{
    NSLog(@"the remote device is now vailable");	
    if ([self isRemoteAvailable] && ![self isListeningToRemote]) [self openRemoteControlDevice];    

}


@end
