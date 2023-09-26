//
//  BarSliceLayer.m
//  BarChart
//
//  Created by Pavan Podila on 2/20/12.
//  Copyright (c) 2012 Pixel-in-Gene. All rights reserved.
//

#import "BarSliceLayer.h"

#import "BarView.h"

@implementation BarSliceLayer

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
	if ([key isEqualToString:@"frame"]) {
		return YES;
	}	
	return [super needsDisplayForKey:key];
}

-(id<CAAction>)actionForKey:(NSString *)event
{
	if ([event isEqualToString:@"frame"]) {
		return [self makeAnimationForKey:event];
	}	
	return [super actionForKey:event];
}

#pragma mark init

- (id)init {
    self = [super init];
    if (self) {
		
		[self setNeedsDisplay];
    }
	
    return self;
}

- (id)initWithLayer:(id)layer
{
	if (self = [super initWithLayer:layer]) {
		if ([layer isKindOfClass:[BarSliceLayer class]])
        {
			BarSliceLayer *other = (BarSliceLayer *)layer;
            self.frame = other.frame;
		}
	}
	
	return self;
}


@end
