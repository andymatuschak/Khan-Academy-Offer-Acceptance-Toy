//
//  AMPlane.m
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import "AMPlane.h"

@implementation AMPlane

- (instancetype)initWithBezierPath:(UIBezierPath *)path targetZPosition:(CGFloat)targetZPosition {
    if (!(self = [super init])) return nil;
    _path = path;
    _targetZPosition = targetZPosition;
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    AMPlane *newPlane = [[AMPlane alloc] initWithBezierPath:self.path targetZPosition:self.targetZPosition];
    newPlane.zPosition = self.zPosition;
    return newPlane;
}

@end
