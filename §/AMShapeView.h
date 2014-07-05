//
//  AMShapeView.h
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AMShapeView : UIView
@property (nonatomic) UIBezierPath *path;
- (void)setPath:(UIBezierPath *)path animated:(BOOL)animated;

@property (nonatomic) UIColor *fillColor;   // defaults to black
@property (nonatomic) UIColor *strokeColor; // defaults to clear
@end
