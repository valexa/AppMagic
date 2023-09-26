//
//  PieView.m
//  PieChart
//
//  Created by Pavan Podila on 2/21/12.
//  Copyright (c) 2012 Pixel-in-Gene. All rights reserved.
//

#import "PieView.h"
#import "PieSliceLayer.h"

#import "MiscFunctions.h"

@implementation PieView

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
        timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateSlices) userInfo:nil repeats:NO];
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
        timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateSlices) userInfo:nil repeats:NO];
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
    [self updateSlices];
}

-(void)updateFrames
{
    [self removeAllLayers];
    [self updateSlices];
}

-(void)updateSlices {
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"valuesShow"] isEqualToString:@"Always show"]) mouseIN = YES;
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"valuesShow"] isEqualToString:@"Never show"]) mouseIN = NO;
    
    [timer invalidate];
    timer = nil;
    
    //add/remove circle
    [circleLayer removeFromSuperlayer];
    circleLayer = nil;
    if ([_values count] > 0)
    {
        circleLayer = [CAShapeLayer layer];
        float widthScale = (self.frame.size.width/1.40);
        float heightScale = (self.frame.size.height/1.40);
        NSBezierPath *piePath = [NSBezierPath bezierPath];
        [piePath appendBezierPathWithOvalInRect:CGRectMake(((self.frame.size.width-widthScale)/2.0), (self.frame.size.height-heightScale)/2.0, widthScale, heightScale)];
        circleLayer.path = [piePath quartzPath];
        circleLayer.fillColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.1].CGColor;
        [self.layer addSublayer:circleLayer];
    }

    //add/remove text
    CGSize textSize = NSMakeSize(140, 140);
    [textLayer removeFromSuperlayer];
    textLayer = nil;
    if ([_values count] > 0)
    {
        textLayer = [CALayer layer];
        [textLayer setFrame:CGRectMake(self.frame.size.width/2-(textSize.width/2), self.frame.size.height/2-(textSize.height/2), textSize.width, textSize.height+12)];
        [self.layer addSublayer:textLayer];
    }
    
    //add/remove slice layers
    if ([[containerLayer sublayers] count] < [_values count])
    {
        for (NSNumber *num in _values)
        {
            PieSliceLayer *slice = [PieSliceLayer layer];
            slice.frame = self.bounds;
            [slice setContentsScale:[self pixelScaling]];
            [containerLayer addSublayer:slice];
        }
    }
    else if  ([[containerLayer sublayers] count] > [_values count])
    {
		NSUInteger count = containerLayer.sublayers.count - _values.count;
        
		for (int i = 0; i < count; i++) {
			[[containerLayer.sublayers objectAtIndex:0] removeFromSuperlayer];
		}
    }

	containerLayer.frame = self.bounds;
    
    if ([_items count] < 1)
    {
        NSLog(@"Not enough pie items");
        return;
    }
    
    NSString *item = [_items objectAtIndex:0];
    
    //set the slices
	CGFloat endAngle = DEG2RAD(90.0);
	int index = 0;
    
    float total = [self getTotal];
    
	for (NSDictionary *dict in _values)
    {
		PieSliceLayer *slice = [containerLayer.sublayers objectAtIndex:index];
        slice.fillColor = [[_colors objectForKey:item] objectAtIndex:index];
        slice.strokeWidth = 0;
    
        NSString *value = [dict objectForKey:item];
        
		CGFloat angle = ([value floatValue]/total) * 2 * M_PI;
        slice.startAngle = endAngle + angle;
        slice.endAngle = endAngle;
        endAngle += angle;
        index++;
    }
    
    //add the text
    index = 0;
	for (NSDictionary *dict in _values)
    {
        NSColor *color = [[_colors objectForKey:item] objectAtIndex:index];
        NSString *name = [dict objectForKey:@"name"];
        CATextLayer *text = [self layerForString:name color:color];
        NSString *value = [dict objectForKey:item];
        if (mouseIN) text = [self layerForString:value color:color];
        if (_humanize && mouseIN) text = [self layerForString:[MiscFunctions humanizeSec:[NSNumber numberWithInteger:[value integerValue]]] color:color];
        [text setFrame:CGRectMake(0 , index*13, textSize.width, 13)];
        [textLayer addSublayer:text];
        index++;
    }
    
}

-(float)getTotal
{
    float ret = 0.0;
	for (NSDictionary *dict in _values)
    {
        for (NSString *item in _items)
        {
            float n = [[dict objectForKey:item] floatValue];
            ret += n;
        }
    }
    return ret;
}


-(CATextLayer*)layerForString:(NSString*)string color:(NSColor*)color
{
    CATextLayer *ret = [CATextLayer layer];
    [ret setForegroundColor:color.CGColor];
    [ret setFontSize:12.0];
    [ret setFont:@"Helvetica-Bold"];
    [ret setString:string];
    [ret setAlignmentMode:kCAAlignmentCenter];
    //[ret setAutoresizingMask:kCALayerHeightSizable | kCALayerWidthSizable];
    return ret;
}

-(CGFloat)pixelScaling
{
    NSRect pixelBounds = [self convertRectToBacking:self.bounds];
    return pixelBounds.size.width/self.bounds.size.width;
}

@end


@implementation NSBezierPath (BezierPathQuartzUtilities)
// This method works only in OS X v10.2 and later.
- (CGPathRef)quartzPath
{
    NSInteger i, numElements;
    
    // Need to begin a path here.
    CGPathRef           immutablePath = NULL;
    
    // Then draw the path elements.
    numElements = [self elementCount];
    if (numElements > 0)
    {
        CGMutablePathRef    path = CGPathCreateMutable();
        NSPoint             points[3];
        BOOL                didClosePath = YES;
        
        for (i = 0; i < numElements; i++)
        {
            switch ([self elementAtIndex:i associatedPoints:points])
            {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;
                    
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    didClosePath = NO;
                    break;
                    
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                          points[1].x, points[1].y,
                                          points[2].x, points[2].y);
                    didClosePath = NO;
                    break;
                    
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }
        
        // Be sure the path is closed or Quartz may not do valid hit detection.
        if (!didClosePath)
            CGPathCloseSubpath(path);
        
        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
    
    return immutablePath;
}
@end
