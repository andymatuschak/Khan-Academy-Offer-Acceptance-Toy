//
//  AMMotionEffectReportingView.h
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AMMotionEffectObserver;
/// Motion effects only work directly with animatable layer properties. We'll run a display link to bridge the declarative to the procedural.
@interface AMMotionEffectReportingView : UIView
@property (nonatomic, weak) id <AMMotionEffectObserver> observer;
@end

@protocol AMMotionEffectObserver <NSObject>
- (void)motionEffectReportingView:(AMMotionEffectReportingView *)reportingView didObserverNewViewerOffset:(CGPoint)viewerOffset;
@end
