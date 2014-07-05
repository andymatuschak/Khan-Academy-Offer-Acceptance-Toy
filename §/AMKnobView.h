//
//  AMKnobView.h
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AMKnobView : UIView
@property (nonatomic) UIColor *color;

@property (nonatomic, assign, getter=isHighlighted) BOOL highlighted;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;
@end
