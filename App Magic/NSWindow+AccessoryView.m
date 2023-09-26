//
//  NSWindow+AccessoryView.m
//  NSWindowButtons
//
//  Created by Randall Brown on 9/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSWindow+AccessoryView.h"

@implementation NSWindow (NSWindow_AccessoryView)

-(void)addViewToTitleBar:(NSView*)viewToAdd atXPosition:(CGFloat)x
{
       
   viewToAdd.frame = NSMakeRect(x, [[self contentView] frame].size.height+[self heightOfToolBar], viewToAdd.frame.size.width, 22);
   
   //[viewToAdd setAutoresizingMask: NSViewMinXMargin | NSViewMinYMargin];

   //[viewToAdd setTranslatesAutoresizingMaskIntoConstraints:NO];
        
   [[[self contentView] superview] addSubview:viewToAdd];
    
    //NSView *title = [[[[self contentView] superview] subviews] objectAtIndex:2];
    //[viewToAdd addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[title]-[viewToAdd]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(title, viewToAdd)]];
   
}

-(CGFloat)heightOfToolBar
{
   NSRect outerFrame = [[[self contentView] superview] frame];
   NSRect innerFrame = [[self contentView] frame];
   
   return outerFrame.size.height - innerFrame.size.height - 22;
}

@end
