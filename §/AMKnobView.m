//
//  AMKnobView.m
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import "AMKnobView.h"
#import "AMShapeView.h"
#import "FBTweakInline.h"

@interface AMKnobView ()
@property (readonly, nonatomic) AMShapeView *shapeView;
@property (nonatomic, assign) CGFloat unhighlightedWidth;
@property (nonatomic, assign) CGFloat strokeWidth;
@property (readonly, nonatomic) UIBezierPath *unhighlightedPath;
@property (readonly, nonatomic) UIBezierPath *highlightedPath;
@end

@implementation AMKnobView
{
    UIBezierPath *_highlightedPath;
    UIBezierPath *_unhighlightedPath;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _shapeView = [[AMShapeView alloc] initWithFrame:self.bounds];
        _shapeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _shapeView.userInteractionEnabled = NO;
        [self addSubview:_shapeView];
        
        FBTweakBind(self, unhighlightedWidth, @"Slider", @"Knob", @"Unhighlighted Donut Width", 2.5);
        FBTweakBind(self, strokeWidth, @"Slider", @"Knob", @"Unhighlighted Stroke Width", 1.0);
    }
    return self;
}

- (void)setColor:(UIColor *)color {
    CGFloat hue, saturation, brightness, alpha;
    [color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    self.shapeView.fillColor = color;
    self.shapeView.strokeColor = [UIColor colorWithHue:hue
                                            saturation:saturation * FBTweakValue(@"Slider", @"Knob", @"Stroke Saturation Scale", 0.95)
                                            brightness:brightness * FBTweakValue(@"Slider", @"Knob", @"Stroke Brightness Scale", 1.6)
                                                 alpha:alpha];
}

- (UIBezierPath *)currentPath {
    return self.highlighted ? self.highlightedPath : self.unhighlightedPath;
}

- (UIBezierPath *)highlightedPath {
    CGRect bounds = self.shapeView.bounds;
    if (!_highlightedPath && !CGRectEqualToRect(bounds, CGRectZero)) {
        _highlightedPath = [UIBezierPath bezierPathWithOvalInRect:bounds];
        UIBezierPath *reversePath = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(bounds, bounds.size.width / 2.0, bounds.size.height / 2.0)];
        [_highlightedPath appendPath:[reversePath bezierPathByReversingPath]];
        _highlightedPath.lineWidth = 1.5;
    }
    return _highlightedPath;
}

- (UIBezierPath *)unhighlightedPath {
    CGRect bounds = self.shapeView.bounds;
    if (!_unhighlightedPath && !CGRectEqualToRect(bounds, CGRectZero)) {
        _unhighlightedPath = [UIBezierPath bezierPathWithOvalInRect:bounds];
        UIBezierPath *reversePath = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(bounds, self.unhighlightedWidth, self.unhighlightedWidth)];
        [_unhighlightedPath appendPath:[reversePath bezierPathByReversingPath]];
        _unhighlightedPath.lineWidth = 1.5;
    }
    return _unhighlightedPath;
}

- (void)setUnhighlightedWidth:(CGFloat)unhighlightedWidth {
    _unhighlightedWidth = unhighlightedWidth;
    _unhighlightedPath = nil;
    [self.shapeView setPath:[self currentPath] animated:NO];
}

- (void)setStrokeWidth:(CGFloat)strokeWidth {
    _strokeWidth = strokeWidth;
    _unhighlightedPath = nil;
    [self.shapeView setPath:[self currentPath] animated:NO];
}

- (void)setHighlighted:(BOOL)highlighted {
    [self setHighlighted:highlighted animated:NO];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (_highlighted != highlighted) {
        _highlighted = !_highlighted;
        [self.shapeView setPath:[self currentPath] animated:YES];
        [UIView animateWithDuration:FBTweakValue(@"Slider", @"Knob", @"Highlight Duration", 0.7)
                              delay:0
             usingSpringWithDamping:FBTweakValue(@"Slider", @"Knob", @"Highlight Damping", 0.5)
              initialSpringVelocity:0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            CGFloat scaleFactor = self.highlighted ? FBTweakValue(@"Slider", @"Knob", @"Highlight Scale Factor", 1.5) : 1.0;
            self.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
        } completion:nil];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGRectEqualToRect(self.shapeView.bounds, self.shapeView.path.bounds)) {
        _highlightedPath = nil;
        _unhighlightedPath = nil;
        self.shapeView.path = [self currentPath];
    }
}

@end
