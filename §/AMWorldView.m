//
//  AMWorldView.m
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import "AMArcballCamera.h"
#import "AMMotionEffectReportingView.h"
#import "AMPlane.h"
#import "AMShapeView.h"
#import "AMTransformView.h"
#import "AMWorldBackgroundView.h"
#import "AMWorldView.h"
#import "AMZSlider.h"
#import "FBTweakInline.h"
#import "SceneKitTypes.h"

@interface AMWorldView () <UIGestureRecognizerDelegate, AMZSliderDelegate, AMZSliderDataSource, AMMotionEffectObserver>
@property (nonatomic, readonly) AMTransformView *planeTransformView;
@property (nonatomic, readonly) NSMutableArray *planeViews;
@property (nonatomic) CGSize largestPlaneSize;

@property (nonatomic, readonly) AMZSlider *leftSlider;
@property (nonatomic, readonly) AMZSlider *rightSlider;

@property (nonatomic, readonly) AMWorldBackgroundView *backgroundView;

@property (nonatomic, readonly) AMShapeView *completePlane;
@property (nonatomic) UIView *completeDotView;
@property (nonatomic) UIButton *restartButton;

@property (nonatomic, readonly) AMMotionEffectReportingView *motionEffectReportingView;
@property (nonatomic) CGPoint viewerOffset;
@property (nonatomic) BOOL hasSetViewerOffsetBefore;
@end

@implementation AMWorldView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Background:
        // We want the background to have a perspective transform, but it needs to be in a different rendering group from the planes to avoid being xored.
        AMTransformView *backgroundTransformView = [[AMTransformView alloc] initWithFrame:self.bounds];
        backgroundTransformView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        backgroundTransformView.layer.transform = [self perspectiveTransform];
        [self addSubview:backgroundTransformView];
        
        _backgroundView = [[AMWorldBackgroundView alloc] initWithFrame:CGRectInset(self.bounds, -2000, -2000)];
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _backgroundView.layer.zPosition = -500;
        [backgroundTransformView addSubview:_backgroundView];
        
        // Sliders:
        _leftSlider = [[AMZSlider alloc] initWithFrame:self.bounds];
        _leftSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _leftSlider.zeroIntersectionPoint = CGPointMake(FBTweakValue(@"Slider", @"World Sliders", @"Left X", 220.0),
                                                        FBTweakValue(@"Slider", @"World Sliders", @"Y", 550.0));
        _leftSlider.maximumZValue = FBTweakValue(@"Slider", @"World Sliders", @"Maximum Z", 500);
        _leftSlider.minimumZValue = FBTweakValue(@"Slider", @"World Sliders", @"Minimum Z", -500);
        _leftSlider.GLKTransform = GLKMatrix4FromCATransform3D([self perspectiveTransform]);
        _leftSlider.dataSource = self;
        _leftSlider.delegate = self;
        [self addSubview:_leftSlider];
        
        _rightSlider = [[AMZSlider alloc] initWithFrame:_leftSlider.frame];
        _rightSlider.autoresizingMask = _leftSlider.autoresizingMask;
        _rightSlider.zeroIntersectionPoint = CGPointMake(FBTweakValue(@"Slider", @"World Sliders", @"Right X", 804.0),
                                                         _leftSlider.zeroIntersectionPoint.y);
        _rightSlider.maximumZValue = _leftSlider.maximumZValue;
        _rightSlider.minimumZValue = _leftSlider.minimumZValue;
        _rightSlider.GLKTransform = _leftSlider.GLKTransform;
        _rightSlider.dataSource = self;
        _rightSlider.delegate = self;
        [self addSubview:_rightSlider];
        
        // Planes:
        UIView *renderingGroupContainer = [[UIView alloc] initWithFrame:self.bounds];
        renderingGroupContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        renderingGroupContainer.userInteractionEnabled = NO;
        [self addSubview:renderingGroupContainer];
        
        _planeTransformView = [[AMTransformView alloc] initWithFrame:self.bounds];
        _planeTransformView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _planeTransformView.layer.transform = [self perspectiveTransform];
        _planeTransformView.userInteractionEnabled = NO;
        [renderingGroupContainer addSubview:_planeTransformView];
        _planeViews = [NSMutableArray array];
        
        // Camera control:
#if DEVELOPMENT
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        pan.delegate = self;
        [self addGestureRecognizer:pan];
#endif
        _motionEffectReportingView = [[AMMotionEffectReportingView alloc] init];
        _motionEffectReportingView.observer = self;
        [self addSubview:_motionEffectReportingView];
        
        // Extra plane for the completion state:
        _completePlane = [self newPlane];
        _completePlane.hidden = YES;
        _completePlane.fillColor = [UIColor colorWithWhite:0.3 alpha:1.0];
        [self.planeTransformView addSubview:_completePlane];
        
        // And setup the initial state of the game:
        self.viewerOffset = CGPointZero;
        self.gameState = AMWorldViewGameStateActive;
    }
    return self;
}

- (void)setGameState:(AMWorldViewGameState)gameState {
    if (_gameState == AMWorldViewGameStateActive && gameState == AMWorldViewGameStateComplete) {
        self.completePlane.hidden = NO;
        self.completePlane.alpha = 0;
        
        [UIView animateWithDuration:1.0 animations:^{
            self.completePlane.alpha = 1;
            for (UIView *planeView in self.planeViews) {
                planeView.alpha = 0;
            }
            self.leftSlider.alpha = 0;
            self.rightSlider.alpha = 0;
        }];
        
        CGRect dotFrame;
        CGFloat dotWidth = FBTweakValue(@"Planes", @"Completion Dot", @"Size", 20);
        dotFrame.origin.x = CGRectGetMaxX(self.completePlane.frame) + 20;
        dotFrame.origin.y = CGRectGetMaxY(self.completePlane.frame) - dotWidth * 3.0/4.0;
        dotFrame.size.width = dotWidth;
        dotFrame.size.height = dotWidth;
        
        self.completeDotView = [[UIView alloc] initWithFrame:dotFrame];
        self.completeDotView.layer.cornerRadius = dotWidth / 2.0;
        self.completeDotView.layer.zPosition = self.completePlane.layer.zPosition;
        self.completeDotView.backgroundColor = [UIColor colorWithRed:141.0/255.0 green:181.0/255.0 blue:48.0/255.0 alpha:1.0];
        [self.planeTransformView addSubview:self.completeDotView];
        self.completeDotView.transform = CGAffineTransformMakeScale(0.001, 0.001);
        
        [UIView animateWithDuration:1.5 delay:0.7 usingSpringWithDamping:0.4 initialSpringVelocity:30 options:0 animations:^{
            self.completeDotView.transform = CGAffineTransformIdentity;
        } completion:nil];
        
        self.restartButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.restartButton.tintColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        CGFloat restartButtonWidth = 50;
        self.restartButton.frame = CGRectMake(CGRectGetMidX(self.bounds) - restartButtonWidth / 2.0, self.bounds.size.height * 3.0/4.0, restartButtonWidth, restartButtonWidth);
        [self.restartButton setImage:[UIImage imageNamed:@"Restart"] forState:UIControlStateNormal];
        [self.restartButton addTarget:self action:@selector(handleRestartButton) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.restartButton];
        
    } else if (_gameState == AMWorldViewGameStateComplete && gameState == AMWorldViewGameStateActive) {
        [UIView animateWithDuration:1.0 delay:0 usingSpringWithDamping:1.0 initialSpringVelocity:0 options:0 animations:^{
            self.completeDotView.transform = CGAffineTransformMakeScale(0.001, 0.001);
            self.completeDotView.alpha = 0;
            self.completePlane.transform = CGAffineTransformMakeScale(0.001, 0.001);
            self.completePlane.alpha = 0;
        } completion:^(BOOL finished){
            self.completePlane.hidden = YES;
            self.completePlane.transform = CGAffineTransformIdentity;
            [self.completeDotView removeFromSuperview];
            self.completeDotView = nil;
        }];
        
        [UIView animateWithDuration:0.5 delay:0 options:0 animations:^{
            self.restartButton.alpha = 0;
        } completion:^(BOOL finished) {
            [self.restartButton removeFromSuperview];
            self.restartButton = nil;
        }];
        
        [UIView animateWithDuration:1.5 delay:0.7 options:0 animations:^{
            for (UIView *planeView in self.planeViews) {
                planeView.alpha = 1;
            }
            self.leftSlider.alpha = 1;
            self.rightSlider.alpha = 1;
        } completion:nil];
    }
    _gameState = gameState;
}

- (void)handleRestartButton {
    if ([self.delegate respondsToSelector:@selector(worldViewDidReceiveRestartAction:)]) {
        [self.delegate worldViewDidReceiveRestartAction:self];
    }
}

#pragma mark Planes

- (NSUInteger)planeIndexForKnobIndex:(NSUInteger)knobIndex ofZSlider:(AMZSlider *)zSlider {
    return knobIndex * 2 + (zSlider == self.leftSlider ? 0 : 1);
}

- (NSUInteger)numberOfPlanes {
    return [self.dataSource numberOfPlanesInWorldView:self];
}

- (AMShapeView *)newPlane {
    AMShapeView *planeView = [[AMShapeView alloc] init];
    planeView.userInteractionEnabled = NO;
    planeView.layer.compositingFilter = @"xor"; // Cheating a bit here. I'd write my own shader if this were something real, but this is a one-off. Don't ever ever do this in a shipping app; just suck it up and write the shader yourself.
    return planeView;
}

- (void)reloadPlanes {
    NSInteger newNumberOfPlanes = [self numberOfPlanes];
    NSInteger oldNumberOfPlanes = [self.planeViews count];
    if (oldNumberOfPlanes < newNumberOfPlanes) {
        for (NSInteger planeIndex = oldNumberOfPlanes; planeIndex < newNumberOfPlanes; planeIndex++) {
            AMShapeView *planeView = [self newPlane];
            [self.planeViews addObject:planeView];
            [self.planeTransformView addSubview:planeView];
            
            planeView.alpha = 0;
            [UIView animateWithDuration:2.0 delay:((planeIndex - oldNumberOfPlanes) * 0.2) options:0 animations:^{
                planeView.alpha = 1;
            } completion:nil];
        }
    } else {
        for (NSInteger planeIndex = oldNumberOfPlanes - 1; planeIndex >= newNumberOfPlanes; planeIndex--) {
            AMShapeView *planeView = self.planeViews[planeIndex];
            [planeView removeFromSuperview];
            [self.planeViews removeObjectAtIndex:planeIndex];
        }
    }
    
    __block CGSize largestSize = CGSizeZero;
    [self.planeViews enumerateObjectsUsingBlock:^(AMShapeView *planeView, NSUInteger planeIndex, BOOL *_) {
        planeView.path = [self.dataSource worldView:self planeAtIndex:planeIndex].path;
        CGRect bounds = planeView.path.bounds;
        if (bounds.size.width > largestSize.width) largestSize.width = bounds.size.width;
        if (bounds.size.height > largestSize.height) largestSize.height = bounds.size.height;
    }];
    self.completePlane.path = [self.dataSource completeMessageForWorldView:self];
    self.largestPlaneSize = largestSize;
    
    [self.leftSlider reloadKnobs];
    [self.rightSlider reloadKnobs];
    
    [self updatePlaneColors];
    [self setNeedsLayout];
}

- (void)setDataSource:(id<AMWorldViewDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        [self reloadPlanes];
    }
}

- (void)layoutSubviews {
    void (^centerPlane)(AMShapeView *planeView) = ^(AMShapeView *planeView) {
        planeView.bounds = (CGRect){CGPointZero, self.largestPlaneSize};
        planeView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    };
    
    [super layoutSubviews];
    __block CGFloat averageZPosition = 0;
    [self.planeViews enumerateObjectsUsingBlock:^(AMShapeView *planeView, NSUInteger planeIndex, BOOL *_) {
        centerPlane(planeView);
        
        // The plane has some target Z position; we'll actually set z=0 at that target position so that all the planes will line up.
        AMPlane *plane = [self.dataSource worldView:self planeAtIndex:planeIndex];
        planeView.layer.zPosition = plane.zPosition - plane.targetZPosition;
        averageZPosition += planeView.layer.zPosition;
    }];
    self.completePlane.layer.zPosition = averageZPosition / [self.planeViews count];
    
    centerPlane(self.completePlane);
}

- (void)updatePlaneColors {
    [self.planeViews enumerateObjectsUsingBlock:^(AMShapeView *planeView, NSUInteger planeIndex, BOOL *_) {
        planeView.fillColor = [self colorOfPlane:planeIndex];
    }];
}

- (UIColor *)colorOfPlane:(NSUInteger)planeIndex {
    CGFloat hue = fmod(planeIndex * 0.2 + (_viewerOffset.y / 4.0), 1.0);
    return [UIColor colorWithHue:hue saturation:0.7 brightness:(0.9 + fabs(_viewerOffset.x) / 4.0) alpha:1.0];
}

#pragma mark Sliders

- (NSUInteger)numberOfKnobsInZSlider:(AMZSlider *)zSlider {
    if (zSlider == self.leftSlider) {
        return ceil([self numberOfPlanes] / 2.0);
    } else if (zSlider == self.rightSlider) {
        return floor([self numberOfPlanes] / 2.0);
    } else {
        [NSException raise:NSInvalidArgumentException format:@"invalid slider"];
        return 0;
    }
}

- (CGFloat)zSlider:(AMZSlider *)zSlider zPositionOfKnob:(NSUInteger)knobIndex {
    return [self.dataSource worldView:self planeAtIndex:[self planeIndexForKnobIndex:knobIndex ofZSlider:zSlider]].zPosition;
}

- (void)zSlider:(AMZSlider *)zSlider didMoveKnob:(NSUInteger)knobIndex toZPosition:(CGFloat)zPosition {
    if ([self.delegate respondsToSelector:@selector(worldView:didMovePlane:toZPosition:)]) {
        [self.delegate worldView:self didMovePlane:[self planeIndexForKnobIndex:knobIndex ofZSlider:zSlider] toZPosition:zPosition];
    }
    [self layoutSubviews];
}

- (UIColor *)zSlider:(AMZSlider *)zSlider colorOfKnob:(NSUInteger)knobIndex {
    return [self colorOfPlane:[self planeIndexForKnobIndex:knobIndex ofZSlider:zSlider]];
}

#pragma mark Camera

- (void)motionEffectReportingView:(AMMotionEffectReportingView *)reportingView didObserverNewViewerOffset:(CGPoint)viewerOffset {
    self.viewerOffset = viewerOffset;
}

- (void)setViewerOffset:(CGPoint)viewerOffset {
    _viewerOffset = viewerOffset;
    
    CGFloat maximumAngle = FBTweakValue(@"Drawing", @"Camera", @"Maximum Angle", 20.0);
    
    CGFloat horizontalAngle = _viewerOffset.x * M_PI / 180.0 * maximumAngle;
    CGFloat verticalAngle = _viewerOffset.y * M_PI / 180.0 * maximumAngle;
    
    // Background, which rotates in a special way to suggest that it's mounted on a sphere.
    CGFloat backgroundRotationDistance = FBTweakValue(@"Background", @"Rotation", @"Arcball Radius", 3000);
    CATransform3D backgroundTransform = CATransform3DMakeTranslation(0, 0, backgroundRotationDistance);
    CGFloat backgroundHorizontalAngle = -horizontalAngle * FBTweakValue(@"Background", @"Rotation", @"Horizontal Scale Factor", 1.0 / 3.0);
    CGFloat backgroundVerticalAngle = verticalAngle * FBTweakValue(@"Background", @"Rotation", @"Vertical Scale Factor", 1.0 / 1.5);
    backgroundTransform = CATransform3DRotate(backgroundTransform, backgroundHorizontalAngle, 0, 1.0, 0);
    backgroundTransform = CATransform3DRotate(backgroundTransform, backgroundVerticalAngle, cos(backgroundHorizontalAngle), 0, sin(backgroundHorizontalAngle));
    backgroundTransform = CATransform3DTranslate(backgroundTransform, 0, 0, -backgroundRotationDistance);
    
    // We animate to the new position to smooth over parallax hitches.
    CABasicAnimation *backgroundAnimation = nil;
    if (self.hasSetViewerOffsetBefore) {
        backgroundAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        backgroundAnimation.fromValue = [NSValue valueWithCATransform3D:[(CALayer *)self.backgroundView.layer.presentationLayer transform]];
        backgroundAnimation.duration = 0.1;
        backgroundAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        [self.backgroundView.layer addAnimation:backgroundAnimation forKey:@"transform"];
    }
    self.backgroundView.layer.transform = backgroundTransform;
    
    // Planes, which start from a weird initial position to befuddle.
    CGFloat planeHorizontalAngle = horizontalAngle + FBTweakValue(@"Planes", @"Befuddlement", @"Horizontal Befuddlement", 5) * M_PI / 180.0;
    CGFloat planeVerticalAngle = verticalAngle + FBTweakValue(@"Planes", @"Befuddlement", @"Vertical Befuddlement", -5) * M_PI / 180.0;
    CATransform3D planeWorldTransform = [AMArcballCamera arcballTransformForHorizontalAngle:planeHorizontalAngle
                                                                              verticalAngle:planeVerticalAngle
                                                                                     radius:FBTweakValue(@"Drawing", @"Camera", @"Arcball Radius", 10.0)];
    CATransform3D projectedPlaneTransform = CATransform3DConcat([self perspectiveTransform], planeWorldTransform);
    if (self.hasSetViewerOffsetBefore ) {
        CABasicAnimation *planeTransformAnimation = [backgroundAnimation copy];
        planeTransformAnimation.fromValue = [NSValue valueWithCATransform3D:[(CALayer *)self.planeTransformView.layer.presentationLayer transform]];
        [self.planeTransformView.layer addAnimation:planeTransformAnimation forKey:@"transform"];
    }
    self.planeTransformView.layer.transform = projectedPlaneTransform;
    
    // Sliders
    CATransform3D sliderWorldTransform = [AMArcballCamera arcballTransformForHorizontalAngle:horizontalAngle
                                                                               verticalAngle:verticalAngle
                                                                                      radius:FBTweakValue(@"Drawing", @"Camera", @"Arcball Radius", 10.0)];
    CATransform3D projectedSliderTransform = CATransform3DConcat([self perspectiveTransform], sliderWorldTransform);
    self.leftSlider.GLKTransform = GLKMatrix4FromCATransform3D(projectedSliderTransform);
    self.rightSlider.GLKTransform = self.leftSlider.GLKTransform;
    
    [self updatePlaneColors];
    self.hasSetViewerOffsetBefore = YES;
}

- (CATransform3D)perspectiveTransform {
    CATransform3D perspectiveTransform = CATransform3DIdentity;
    perspectiveTransform.m34 = -1.0 / FBTweakValue(@"Drawing", @"Camera", @"EyeZ", 1000.0);
    return perspectiveTransform;
}

#if DEVELOPMENT

- (void)handlePan:(UIGestureRecognizer *)recognizer
{
    CGFloat panToViewerOffsetScaleFactor = FBTweakValue(@"Drawing", @"Camera", @"Panning Scale Factor", 1.0 / 50.0);
    
    assert([recognizer isKindOfClass:[UIPanGestureRecognizer class]]);
    UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)recognizer;
    switch ([panGesture state]) {
        case UIGestureRecognizerStateBegan: {
            [self.motionEffectReportingView removeFromSuperview]; // will stop reporting motion events
            CGPoint scaledOffset = CGPointMake(self.viewerOffset.x / panToViewerOffsetScaleFactor, self.viewerOffset.y / panToViewerOffsetScaleFactor);
            [panGesture setTranslation:scaledOffset inView:self];
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            [self addSubview:self.motionEffectReportingView];
            // fall through
        case UIGestureRecognizerStateChanged: {
            CGPoint panOffset = [panGesture translationInView:self];
            self.viewerOffset = CGPointMake(panOffset.x * panToViewerOffsetScaleFactor, panOffset.y * panToViewerOffsetScaleFactor);
            break;
        }
        default: break;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // Only let the camera pan gesture receive touches which aren't hitting a slider knob.
    return ![self.leftSlider hitTest:[touch locationInView:self.leftSlider] withEvent:nil] &&
           ![self.rightSlider hitTest:[touch locationInView:self.rightSlider] withEvent:nil];
}

#endif

@end
