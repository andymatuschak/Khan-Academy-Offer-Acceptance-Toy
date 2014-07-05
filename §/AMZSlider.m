//
//  AMZSlider.m
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import "AMKnobView.h"
#import "AMShapeView.h"
#import "AMZSlider.h"
#import "FBTweakInline.h"

@interface AMZSliderKnobTouchTrackingInfo : NSObject
- (instancetype)initWithKnobIndex:(NSInteger)knobIndex initialWorldTouchPosition:(CGPoint)initialWorldTouchPosition;
@property (readonly) NSInteger knobIndex;
@property (readonly) CGPoint initialWorldTouchPosition;
@end

@implementation AMZSliderKnobTouchTrackingInfo
- (instancetype)initWithKnobIndex:(NSInteger)knobIndex initialWorldTouchPosition:(CGPoint)initialWorldTouchPosition {
    if (!(self = [super init])) return nil;
    _knobIndex = knobIndex;
    _initialWorldTouchPosition = initialWorldTouchPosition;
    return self;
}
@end


#pragma mark -

@interface AMZSlider ()
@property (readonly) AMShapeView *trackView;
@property NSMutableArray *knobViews;

@property NSMapTable *touchesToKnobTouchTrackingInfos;
@end

@implementation AMZSlider

#pragma mark Lifecycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _trackView = [[AMShapeView alloc] init];
        _trackView.strokeColor = [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:0.75];
        [self addSubview:_trackView];
        
        _GLKTransform = GLKMatrix4Identity;
        _touchesToKnobTouchTrackingInfos = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality | NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsObjectPersonality | NSPointerFunctionsStrongMemory];
        _knobViews = [NSMutableArray array];
        
        self.multipleTouchEnabled = YES;
    }
    return self;
}

#pragma mark Projection

- (void)setGLKTransform:(GLKMatrix4)GLKTransform {
    _GLKTransform = GLKTransform;
    [self setNeedsLayout];
}

- (void)setZeroIntersectionPoint:(CGPoint)zeroIntersectionPoint {
    _zeroIntersectionPoint = zeroIntersectionPoint;
    [self setNeedsLayout];
}

#pragma mark Track

- (void)setMinimumZValue:(CGFloat)minimumZValue {
    _minimumZValue = minimumZValue;
    [self setNeedsLayout];
}

- (void)setMaximumZValue:(CGFloat)maximumZValue {
    _maximumZValue = maximumZValue;
    [self setNeedsLayout];
}

- (CGPoint)projectedMinimumTrackPoint {
    return [self projectPoint:self.zeroIntersectionPoint zPosition:self.minimumZValue];
}

- (CGPoint)projectedMaximumTrackPoint {
    return [self projectPoint:self.zeroIntersectionPoint zPosition:self.maximumZValue];
}

#pragma mark Knobs

static CGFloat AMZSliderKnobDiameter() { return FBTweakValue(@"Slider", @"Knob", @"Diameter", 45.0); }

- (void)reloadKnobs {
    NSInteger newNumberOfKnobs = [self numberOfKnobs];
    NSInteger oldNumberOfKnobs = [self.knobViews count];
    if (oldNumberOfKnobs < newNumberOfKnobs) {
        for (NSInteger i = oldNumberOfKnobs; i < newNumberOfKnobs; i++) {
            AMKnobView *knobView = [[AMKnobView alloc] init];
            [self.knobViews addObject:knobView];
            [self addSubview:knobView];
            
            knobView.alpha = 0;
            [UIView animateWithDuration:2.0 delay:((i - oldNumberOfKnobs) * 0.2) options:UIViewAnimationOptionAllowUserInteraction animations:^{
                knobView.alpha = 1;
            } completion:nil];
        }
    } else {
        for (NSInteger i = oldNumberOfKnobs - 1; i >= newNumberOfKnobs; i--) {
            AMKnobView *knobView = self.knobViews[i];
            [knobView removeFromSuperview];
            [self.knobViews removeObjectAtIndex:i];
        }
    }
    [self setNeedsLayout];
}

- (NSUInteger)numberOfKnobs {
    return [self.dataSource numberOfKnobsInZSlider:self];
}

- (CGFloat)zPositionOfKnob:(NSUInteger)knobIndex {
    return [self.dataSource zSlider:self zPositionOfKnob:knobIndex];
}

- (void)setDataSource:(id<AMZSliderDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        [self reloadKnobs];
    }
}

#pragma mark Layout

- (CGPoint)projectPoint:(CGPoint)boundsRelativeWorldPoint zPosition:(CGFloat)zPosition {
    CGPoint boundsMidPoint = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGPoint anchoredWorldPoint = CGPointMake(boundsRelativeWorldPoint.x - boundsMidPoint.x, boundsRelativeWorldPoint.y - boundsMidPoint.y);
    GLKVector4 anchoredWorldVector = GLKVector4Make(anchoredWorldPoint.x, anchoredWorldPoint.y, zPosition, 1);
    GLKVector4 projectedHomogeneousVector = GLKMatrix4MultiplyVector4(_GLKTransform, anchoredWorldVector);
    CGPoint projectedAnchoredPoint = CGPointMake(projectedHomogeneousVector.x / projectedHomogeneousVector.w, projectedHomogeneousVector.y / projectedHomogeneousVector.w);
    CGPoint boundsRelativeProjectedPoint = CGPointMake(projectedAnchoredPoint.x + boundsMidPoint.x, projectedAnchoredPoint.y + boundsMidPoint.y);
    return boundsRelativeProjectedPoint;
}

- (CGFloat)unprojectZGivenWorldPoint:(CGPoint)boundsRelativeWorldPoint projectedPoint:(CGPoint)boundsRelativeProjectedPoint {
    // Too late at night for writing a simplex solver. Instead: binary search. Well, sorta. It's hard for us to make a direct ordering, so we do a sort of lazy gradient descent.
    CGFloat low = self.minimumZValue, high = self.maximumZValue;
    GLKVector2 boundsRelativeProjectedVector = GLKVector2Make(boundsRelativeProjectedPoint.x, boundsRelativeProjectedPoint.y);
    while (high > low) {
        if (fabs(high - low) < 1) break;
        CGFloat mid = (high + low) / 2.0;
        CGFloat highMid = (high + mid) / 2.0;
        CGFloat lowMid = (mid + low) / 2.0;
        CGPoint projectedHighMidPoint = [self projectPoint:boundsRelativeWorldPoint zPosition:highMid];
        CGPoint projectedLowMidPoint = [self projectPoint:boundsRelativeWorldPoint zPosition:lowMid];
        CGFloat highMidDistance = GLKVector2Distance(GLKVector2Make(projectedHighMidPoint.x, projectedHighMidPoint.y), boundsRelativeProjectedVector);
        CGFloat lowMidDistance = GLKVector2Distance(GLKVector2Make(projectedLowMidPoint.x, projectedLowMidPoint.y), boundsRelativeProjectedVector);
        if (highMidDistance < lowMidDistance) {
            low = lowMid;
        } else {
            high = highMid;
        }
    }
    return high;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGPoint minimumTrackPoint = [self projectedMinimumTrackPoint];
    CGPoint maximumTrackPoint = [self projectPoint:self.zeroIntersectionPoint zPosition:self.maximumZValue];
    _trackView.frame = CGRectUnion(CGRectMake(minimumTrackPoint.x, minimumTrackPoint.y, 1, 1),
                                   CGRectMake(maximumTrackPoint.x, maximumTrackPoint.y, 1, 1));
    
    UIBezierPath *trackPath = [UIBezierPath bezierPath];
    [trackPath moveToPoint:[_trackView convertPoint:minimumTrackPoint fromView:self]];
    [trackPath addLineToPoint:[_trackView convertPoint:maximumTrackPoint fromView:self]];
    trackPath.lineWidth = FBTweakValue(@"Slider", @"Track", @"Width", 1.0);
    _trackView.path = trackPath;
    _trackView.layer.zPosition = self.minimumZValue - 1;
    
    for (NSInteger knobIndex = 0; knobIndex < self.numberOfKnobs; knobIndex++) {
        AMKnobView *knobView = self.knobViews[knobIndex];
        CGFloat knobDiameter = AMZSliderKnobDiameter();
        CGFloat zPosition = [self zPositionOfKnob:knobIndex];
        CGPoint leftSide = [self projectPoint:CGPointMake(self.zeroIntersectionPoint.x - knobDiameter / 2.0, self.zeroIntersectionPoint.y)
                                    zPosition:zPosition];
        CGPoint rightSide = [self projectPoint:CGPointMake(self.zeroIntersectionPoint.x + knobDiameter / 2.0, self.zeroIntersectionPoint.y)
                                    zPosition:zPosition];
        CGFloat projectedDiameter = rightSide.x - leftSide.x;
        CGPoint center = CGPointMake(leftSide.x + projectedDiameter / 2.0, leftSide.y);
        knobView.center = center;
        knobView.bounds = CGRectMake(0, 0, projectedDiameter, projectedDiameter);
        knobView.color = [self.dataSource zSlider:self colorOfKnob:knobIndex];
        
        knobView.layer.zPosition = zPosition;
    }
}

#pragma mark Input

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // We're only opaque if you hit a knob.
    UIView *superHitTest = [super hitTest:point withEvent:event];
    if ([self.knobViews containsObject:superHitTest]) {
        return superHitTest;
    } else {
        return nil;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        AMKnobView *hitKnob = (AMKnobView *)[self hitTest:[touch locationInView:self] withEvent:event];
        NSInteger knobIndex = [self.knobViews indexOfObject:hitKnob];
        assert(knobIndex != NSNotFound);
        
        // Cheaply undo the projection into world space: easy because we know how the knob's bounds scale.
        // We need to record where the touch initially landed in the knob so that we can track its z position relative to that initial point.
        CGPoint positionInProjectedKnob = [touch locationInView:hitKnob];
        CGFloat projectionToWorldScaleFactor = AMZSliderKnobDiameter() / hitKnob.bounds.size.width;
        CGPoint positionInWorldKnob = CGPointMake(positionInProjectedKnob.x * projectionToWorldScaleFactor, positionInProjectedKnob.y * projectionToWorldScaleFactor);
        CGPoint worldPosition = CGPointMake(positionInWorldKnob.x - AMZSliderKnobDiameter()/2.0 + self.zeroIntersectionPoint.x, positionInWorldKnob.y - AMZSliderKnobDiameter()/2.0 + self.zeroIntersectionPoint.y);
        
        AMZSliderKnobTouchTrackingInfo *touchTrackingInfo = [[AMZSliderKnobTouchTrackingInfo alloc] initWithKnobIndex:knobIndex initialWorldTouchPosition:worldPosition];
        [self.touchesToKnobTouchTrackingInfos setObject:touchTrackingInfo forKey:touch];
        
        [hitKnob setHighlighted:YES animated:YES];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    // We've got to do a bunch of math to a) snap this touch to the track and then b) figure out what z position on the track corresponds to the snapped projected position.
    CGPoint projectedMinimumTrackPoint = [self projectedMinimumTrackPoint];
    GLKVector2 projectedMinimumTrackVector = GLKVector2Make(projectedMinimumTrackPoint.x, projectedMinimumTrackPoint.y);
    CGPoint projectedMaximumTrackPoint = [self projectedMaximumTrackPoint];
    GLKVector2 projectedMaximumTrackVector = GLKVector2Make(projectedMaximumTrackPoint.x, projectedMaximumTrackPoint.y);
    GLKVector2 trackVector = GLKVector2Subtract(projectedMaximumTrackVector, projectedMinimumTrackVector);
    
    for (UITouch *touch in touches) {
        AMZSliderKnobTouchTrackingInfo *touchTrackingInfo = [self.touchesToKnobTouchTrackingInfos objectForKey:touch];
        assert(touchTrackingInfo);
        
        CGPoint touchLocation = [touch locationInView:self];
        GLKVector2 touchVector = GLKVector2Make(touchLocation.x, touchLocation.y);
        GLKVector2 minToTouchVector = GLKVector2Subtract(touchVector, projectedMinimumTrackVector);
        GLKVector2 touchVectorProjectedOntoTrackVector = GLKVector2Project(minToTouchVector, trackVector);
        GLKVector2 touchVectorInProjectedSpace = GLKVector2Add(projectedMinimumTrackVector, touchVectorProjectedOntoTrackVector);
        CGFloat newZPosition = [self unprojectZGivenWorldPoint:touchTrackingInfo.initialWorldTouchPosition projectedPoint:CGPointMake(touchVectorInProjectedSpace.x, touchVectorInProjectedSpace.y)];
        
        if ([self.delegate respondsToSelector:@selector(zSlider:didMoveKnob:toZPosition:)]) {
            [self.delegate zSlider:self didMoveKnob:touchTrackingInfo.knobIndex toZPosition:newZPosition];
        }
    }
    [self setNeedsLayout];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesMoved:touches withEvent:event];
    for (UITouch *touch in touches) {
        AMZSliderKnobTouchTrackingInfo *touchTrackingInfo = [self.touchesToKnobTouchTrackingInfos objectForKey:touch];
        [self.knobViews[touchTrackingInfo.knobIndex] setHighlighted:NO animated:YES];
        [self.touchesToKnobTouchTrackingInfos removeObjectForKey:touch];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

@end
