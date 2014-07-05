//
//  AMArcballCamera.m
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "AMArcballCamera.h"
#import "SceneKitTypes.h"

@implementation AMArcballCamera

+ (CATransform3D)arcballTransformForHorizontalAngle:(CGFloat)horizontalAngle verticalAngle:(CGFloat)verticalAngle radius:(CGFloat)radius {
    CGFloat x = sin(horizontalAngle) * radius;
    CGFloat y = sin(verticalAngle) * radius;
    // x^2 + y^2 + z^2 = radius^2
    CGFloat z = sqrt(radius*radius - x*x - y*y);
    return GLKMatrix4ToCATransform3D(GLKMatrix4MakeLookAt(x, y, z, 0, 0, 0, 0, 1, 0));
}

@end
