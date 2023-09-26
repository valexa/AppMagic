//
//  PieSliceLayer.m
//  PieChart
//
//  Created by Pavan Podila on 2/20/12.
//  Copyright (c) 2012 Pixel-in-Gene. All rights reserved.
//

#import "PieSliceLayer.h"

#import "PieView.h"

@implementation PieSliceLayer

@dynamic startAngle, endAngle;
@synthesize fillColor, strokeColor, strokeWidth;

#pragma mark animate

-(CABasicAnimation *)makeAnimationForKey:(NSString *)key
{
	CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:key];
	anim.fromValue = [[self presentationLayer] valueForKey:key];
	anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	anim.duration = 1.0;
    
	return anim;
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
	if ([key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"]) {
		return YES;
	}	
	return [super needsDisplayForKey:key];
}

-(id<CAAction>)actionForKey:(NSString *)event
{
	if ([event isEqualToString:@"startAngle"] || [event isEqualToString:@"endAngle"]) {
		return [self makeAnimationForKey:event];
	}	
	return [super actionForKey:event];
}

#pragma mark init

- (id)init {
    self = [super init];
    if (self) {
		self.fillColor = [NSColor clearColor];
        self.strokeColor = [NSColor clearColor];
		self.strokeWidth = 0.0;
        
		[self setNeedsDisplay];
    }
	
    return self;
}

- (id)initWithLayer:(id)layer
{
	if (self = [super initWithLayer:layer]) {
		if ([layer isKindOfClass:[PieSliceLayer class]])
        {
			PieSliceLayer *other = (PieSliceLayer *)layer;
			self.startAngle = other.startAngle;
			self.endAngle = other.endAngle;
			self.fillColor = other.fillColor;            
			self.strokeColor = other.strokeColor;
			self.strokeWidth = other.strokeWidth;
            
		}
	}
	
	return self;
}

#pragma mark draw

-(void)drawInContext:(CGContextRef)context
{
	CGPoint center = CGPointMake(self.frame.size.width/2.0, self.frame.size.height/2.0);
	CGFloat radius = MIN(center.x, center.y);
    
    CGContextMoveToPoint(context, center.x, center.y);
    int clockwise = self.startAngle > self.endAngle;
    CGContextAddArc(context, center.x, center.y, radius, self.startAngle, self.endAngle, clockwise);
    
	// Color it
	CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
	CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor);
	CGContextSetLineWidth(context, self.strokeWidth);
    
	CGContextDrawPath(context, self.strokeWidth);
    
    if (!CGContextIsPathEmpty(context)) CGContextClip(context);
    
    CGContextSetFillColorWithColor( context, [NSColor redColor].CGColor );
    CGContextSetBlendMode(context, kCGBlendModeClear);
    float widthScale = self.frame.size.width/1.55;
    float heightScale = self.frame.size.height/1.55;
    CGRect holeRect = CGRectMake((self.frame.size.width-widthScale)/2, (self.frame.size.height-heightScale)/2, widthScale, heightScale);
    CGContextFillEllipseInRect( context, holeRect );

}

@end
