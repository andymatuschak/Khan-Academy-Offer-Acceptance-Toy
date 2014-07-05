//
//  AMTransformView.m
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import "AMTransformView.h"

@interface AMTransformLayer : CATransformLayer @end
@implementation AMTransformLayer
- (void)setOpaque:(BOOL)opaque {
    // Intentional no-op. Super's implementation emits a warning to the console (and no-ops). I never call -setOpaque: on this layer, but UIKit does, which creates noise in the log.
}
@end

@implementation AMTransformView

+ (Class)layerClass {
    return [AMTransformLayer class];
}

@end
