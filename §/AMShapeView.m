//
//  AMShapeView.m
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import "AMShapeView.h"

@interface AMShapeView ()
@property (readonly) CAShapeLayer *shapeLayer;
@end

@implementation AMShapeView

+ (Class)layerClass { return [CAShapeLayer class]; }

- (CAShapeLayer *)shapeLayer {
    return (CAShapeLayer *)self.layer;
}

- (UIBezierPath *)path {
    return self.shapeLayer.path ? [UIBezierPath bezierPathWithCGPath:self.shapeLayer.path] : nil;
}

- (void)setPath:(UIBezierPath *)path {
    [self setPath:path animated:NO];
}

- (void)setPath:(UIBezierPath *)path animated:(BOOL)animated {
    if (animated) {
        CGPathRef oldPath = [self.shapeLayer.presentationLayer path];
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        pathAnimation.fromValue = (__bridge id)oldPath;
        pathAnimation.duration = 0.2;
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        [self.shapeLayer addAnimation:pathAnimation forKey:nil];
    }
    self.shapeLayer.path = path.CGPath;
    self.shapeLayer.lineWidth = path.lineWidth;
}

- (UIColor *)fillColor {
    return [UIColor colorWithCGColor:self.shapeLayer.fillColor];
}

- (void)setFillColor:(UIColor *)fillColor {
    self.shapeLayer.fillColor = fillColor.CGColor;
}

- (UIColor *)strokeColor {
    return [UIColor colorWithCGColor:self.shapeLayer.strokeColor];
}

- (void)setStrokeColor:(UIColor *)strokeColor {
    self.shapeLayer.strokeColor = strokeColor.CGColor;
}

@end
