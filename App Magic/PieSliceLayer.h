//
//  PieSliceLayer.h
//  PieChart
//
//  Created by Pavan Podila on 2/20/12.
//  Copyright (c) 2012 Pixel-in-Gene. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface PieSliceLayer : CALayer


@property (nonatomic) CGFloat startAngle;
@property (nonatomic) CGFloat endAngle;

@property (nonatomic, strong) NSColor *fillColor;
@property (nonatomic) CGFloat strokeWidth;
@property (nonatomic, strong) NSColor *strokeColor;

@end
