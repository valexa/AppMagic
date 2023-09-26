//
//  BarView.h
//  BarChart
//
//  Created by Pavan Podila on 2/21/12.
//  Copyright (c) 2012 Pixel-in-Gene. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface BarView : NSView
{
    CALayer *textLayer;
	CALayer *containerLayer;
    BOOL mouseIN;
    NSTimer *timer;
}

@property BOOL humanize;
@property (nonatomic, strong) NSDictionary *colors;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSArray *items;

-(void)updateFrames;
-(void)updateBars;
-(void)removeAllLayers;
-(void)removeAllData;

@end

