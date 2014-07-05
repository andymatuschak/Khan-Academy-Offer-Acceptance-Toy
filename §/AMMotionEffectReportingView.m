//
//  AMMotionEffectReportingView.m
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import "AMMotionEffectReportingView.h"

@interface AMWeakToStrongAdapter : NSObject
- (instancetype)initWithTarget:(id)target;
@property (readonly, nonatomic, weak) id target;
@end

@implementation AMWeakToStrongAdapter
- (instancetype)initWithTarget:(id)target {
    if (!(self = [super init])) return nil;
    _target = target;
    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return _target;
}
@end

@interface AMMotionEffectReportingView ()
@property (readonly, nonatomic) CADisplayLink *displayLink;
@end

@implementation AMMotionEffectReportingView

- (id)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    _displayLink = [CADisplayLink displayLinkWithTarget:[[AMWeakToStrongAdapter alloc] initWithTarget:self] selector:@selector(checkMotionEffectOutput:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    _displayLink.paused = YES;
    
    // Add motion effects for some arbitrary properties. We intentionally avoid "center" because it's quantized. We'll read back the presentation layer's values for these properties later.    
    UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"layer.zPosition" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(1);
    horizontalMotionEffect.maximumRelativeValue = @(-1);
    [self addMotionEffect:horizontalMotionEffect];

    UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"layer.anchorPointZ" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(1);
    verticalMotionEffect.maximumRelativeValue = @(-1);
    [self addMotionEffect:verticalMotionEffect];
    return self;
}

- (void)dealloc {
    [_displayLink invalidate];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    self.displayLink.paused = (newWindow == nil);
}

- (void)checkMotionEffectOutput:(CADisplayLink *)displayLink {
    CGPoint viewerOffset;
    viewerOffset.x = [self.layer.presentationLayer zPosition];
    viewerOffset.y = [self.layer.presentationLayer anchorPointZ];
    [self.observer motionEffectReportingView:self didObserverNewViewerOffset:viewerOffset];
}

@end
