//
//  AMArcballCamera.h
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMArcballCamera : NSObject
// Yeah, yeah, Euler angles. Moving quickly, here...
+ (CATransform3D)arcballTransformForHorizontalAngle:(CGFloat)horizontalAngle verticalAngle:(CGFloat)verticalAngle radius:(CGFloat)radius;
@end
