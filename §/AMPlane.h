//
//  AMPlane.h
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AMPlane : NSObject <NSCopying>
- (instancetype)initWithBezierPath:(UIBezierPath *)path targetZPosition:(CGFloat)targetZPosition;
@property (readonly, nonatomic) UIBezierPath *path;
@property (readonly, nonatomic) CGFloat targetZPosition;
@property (nonatomic) CGFloat zPosition;
@end
