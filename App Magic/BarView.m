//
//  BarView.m
//  BarChart
//
//  Created by Pavan Podila on 2/21/12.
//  Copyright (c) 2012 Pixel-in-Gene. All rights reserved.
//

#import "BarView.h"
#import "BarSliceLayer.h"

#import "MiscFunctions.h"

@implementation BarView

-(void)doInitialSetup
{
    [self setWantsLayer:YES];//important
	containerLayer = [CALayer layer];
	[self.layer addSublayer:containerLayer];
    
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[self frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:nil];
    [self addTrackingArea:area];
    
    timer = nil;
    
}

-(void)mouseEntered:(NSEvent *)theEvent
{
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"valuesShow"] isEqualToString:@"On mouseover"]) return;
    
    mouseIN = YES;
    
    if (timer != nil)
    {
        [timer invalidate];
        timer = nil;
    }else{
        timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateBars) userInfo:nil repeats:NO];
    }
}

-(void)mouseExited:(NSEvent *)theEvent
{
   if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"valuesShow"] isEqualToString:@"On mouseover"]) return;
    
    mouseIN = NO;
    
    if (timer != nil)
    {
        [timer invalidate];
        timer = nil;
    }else{
        timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateBars) userInfo:nil repeats:NO];
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[self doInitialSetup];
    }
	
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		[self doInitialSetup];
	}
	
	return self;
}

-(void)removeAllLayers
{
    NSUInteger count = containerLayer.sublayers.count;
    
    for (int i = 0; i < count; i++) {
        [[containerLayer.sublayers objectAtIndex:0] removeFromSuperlayer];
    }
}

-(void)removeAllData
{
    self.values = nil;
    self.colors = nil;
    [self removeAllLayers];
    [self updateBars];
}

-(void)updateFrames
{
    [self removeAllLayers];
    [self updateBars];
}

-(void)updateBars
{
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"valuesShow"] isEqualToString:@"Always show"]) mouseIN = YES;
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"valuesShow"] isEqualToString:@"Never show"]) mouseIN = NO;
    
    [timer invalidate];
    timer = nil;
    
    CGFloat valuesTotal = [self valuesCount];
    
    //add/remove text
    [textLayer removeFromSuperlayer];
    textLayer = nil;
    if (valuesTotal > 0)
    {
        textLayer = [CALayer layer];
        textLayer.frame = self.bounds;
        [self.layer addSublayer:textLayer];
    }
    
    //add/remove slice layers
    if ([[containerLayer sublayers] count] < valuesTotal)
    {
        for (NSDictionary *dict in _values)
        {
            for (NSString *item in _items)
            {
                BarSliceLayer *slice = [BarSliceLayer layer];
                [slice setContentsScale:[self pixelScaling]];
                slice.cornerRadius = 2;
                [containerLayer addSublayer:slice];
            }
        }
    }
    else if  ([[containerLayer sublayers] count] > valuesTotal)
    {
		NSUInteger count = containerLayer.sublayers.count - valuesTotal;
        
		for (int i = 0; i < count; i++) {
			[[containerLayer.sublayers objectAtIndex:0] removeFromSuperlayer];
		}
    }
	containerLayer.frame = self.bounds;
    
    if ([_items count] < 1)
    {
        NSLog(@"Not enough bar items");
        return;
    }
    
    float barWidth = self.frame.size.width/[_values count];
    if (barWidth < 1 ) barWidth = 1.0;
    int index = 0;
    int sublayerIndex = 0;
    for (NSDictionary *dict in _values)
    {
        float ybottom = 0.0;
        for (NSString *item in _items)
        {
            NSColor *color = [[_colors objectForKey:item] objectAtIndex:index];
            NSString *value = [dict objectForKey:item];
            float barHeight = ( [value floatValue] / ([self getMaximum]*1.1) ) * self.frame.size.height;
            if (barHeight < 1) barHeight = 1.0;
            
            BarSliceLayer *slice = [containerLayer.sublayers objectAtIndex:sublayerIndex];
            slice.backgroundColor = color.CGColor;
            [slice setFrame:NSMakeRect(barWidth*index, ybottom, barWidth, barHeight)];
            
            NSString *str = [dict objectForKey:@"name"];
            if (mouseIN) str = value;
            CATextLayer *text = [self layerForString:str color:[color shadowWithLevel:0.5] center:YES multiLine:YES];
            if (_humanize && mouseIN) text = [self layerForString:[MiscFunctions humanizeSec:[NSNumber numberWithInteger:[str integerValue]]] color:[color shadowWithLevel:0.5] center:YES multiLine:YES];
            [text setFrame:CGRectMake(barWidth*index+2 , ybottom+3, barWidth-4, 27)];
            if (ybottom > 0)
            {
                if (ybottom > 37 && mouseIN) [textLayer addSublayer:text];
            }else{
                [textLayer addSublayer:text];
            }
            
            ybottom += barHeight;
            sublayerIndex++;
        }
        index++;
    }
    
    if (!mouseIN) [self makeLegendTop:YES];
    
}

-(void)makeLegendTop:(BOOL)topLabels
{
    //use all ints for text positioning so its on whole pixels and never blurred
    int width = self.frame.size.width/2;
    int height = 16;
    int spacing = height/1.6;
    int y = spacing;
    if (topLabels) y = self.frame.size.height-height-spacing;
    
    for (NSString *item in _items)
    {
        id colors = [_colors objectForKey:item];
        NSColor *firstColor = [colors firstObject];
        //NSColor *midColor = [colors objectAtIndex:[colors count]/2];
        NSColor *lastColor = [colors lastObject];
        CAGradientLayer *square = [CAGradientLayer layer];
        [square setFrame:NSMakeRect(4, y, height, height)];
        [square setColors:[NSArray arrayWithObjects:(id)[firstColor CGColor], (id)[lastColor CGColor], nil]];
        [square setStartPoint:NSMakePoint(0 , 0.5)];
        [square setEndPoint:NSMakePoint(1 , 0.5)];
        [square setLocations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.2],[NSNumber numberWithFloat:1], nil]];
        [square setCornerRadius:4];
        [square setBorderColor:[NSColor whiteColor].CGColor];
        [square setBorderWidth:0.5];
        [textLayer addSublayer:square];
        
        //totals
        int total = 0.0;
        for (NSDictionary *dict in _values) {
            total += [[dict objectForKey:item] intValue];
        }
        
        NSString *str = [NSString stringWithFormat:@"%@ %i",item,total];
        if (_humanize) str = [NSString stringWithFormat:@"%@ %@",item,[MiscFunctions humanizeSec:[NSNumber numberWithInteger:total]]];
        
        CATextLayer *text = [self layerForString:str color:[[NSColor blackColor] colorWithAlphaComponent:0.5] center:NO multiLine:NO];
        [text setFrame:NSMakeRect(height+spacing, y-2, width, height)];
        [textLayer addSublayer:text];
        
        if (!topLabels) y += height+(spacing/2.0);
        if (topLabels) y -= height+(spacing/2.0);
    }
}

-(float)getMaximum
{
    float ret = 0.0;
	for (NSDictionary *dict in _values)
    {
        float all = 0.0;
        for (NSString *item in _items)
        {
            float n = [[dict objectForKey:item] floatValue];
            all += n;
        }
        if (all > ret) ret = all;
    }
    if (ret == 0) ret = 0.0001;//prevent divisions by zero
    return ret;
}

-(NSInteger)valuesCount
{
    NSInteger ret = 0;
	for (NSDictionary *dict in _values)
    {
        for (NSString *item in _items)
        {
            ret++;
        }
    }
    return ret;
}

-(CATextLayer*)layerForString:(NSString*)string color:(NSColor*)color center:(BOOL)center multiLine:(BOOL)multiLine
{
    if (!string) string = @"";        
    
    if ([string rangeOfString:@".plist"].location != NSNotFound)
    {
        string = [string stringByReplacingOccurrencesOfString:@".plist" withString:@""];
        string = [NSString stringWithFormat:@"%@\n%@",[string substringFromIndex:4],[string substringToIndex:4]];
    }
    if (multiLine) {
        string = [string stringByReplacingOccurrencesOfString:@"," withString:@"\n"];
    }else {
        string = [string capitalizedString];
    }
    
    CATextLayer *ret = [CATextLayer layer];
    [ret setWrapped:YES];
    [ret setForegroundColor:color.CGColor];
    [ret setFontSize:11.0];
    [ret setFont:@"Helvetica-Bold"];
    [ret setString:string];
    if (center) [ret setAlignmentMode:kCAAlignmentCenter];
    //[ret setAutoresizingMask:kCALayerHeightSizable | kCALayerWidthSizable];
    return ret;
}

-(CGFloat)pixelScaling
{
    NSRect pixelBounds = [self convertRectToBacking:self.bounds];
    return pixelBounds.size.width/self.bounds.size.width;
}

@end



