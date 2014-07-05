//
//  AMWorldBackgroundView.m
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import "AMWorldBackgroundView.h"

@implementation AMWorldBackgroundView

static UIImage *AMWorldBackgroundImage() {
    CGSize size = CGSizeMake(25, 25);
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    [[UIColor whiteColor] set];
    CGRect bounds = (CGRect){CGPointZero, size};
    UIRectFill(bounds);
    [[UIColor colorWithWhite:0.95 alpha:1.0] set];
    [[UIBezierPath bezierPathWithOvalInRect:CGRectInset(bounds, 9, 9)] fill];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (id)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    self.backgroundColor = [UIColor colorWithPatternImage:AMWorldBackgroundImage()];
    return self;
}

@end
