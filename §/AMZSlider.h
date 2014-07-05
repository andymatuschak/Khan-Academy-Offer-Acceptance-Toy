//
//  AMZSlider.h
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@protocol AMZSliderDelegate, AMZSliderDataSource;

/// We want our slider to have orthographic geometry but projected positioning (i.e. the lines should always be e.g 2px wide, but positioned as they hsould be in 3D space). This class does the math to make that happen.
@interface AMZSlider : UIView

@property (nonatomic, weak) id <AMZSliderDataSource> dataSource;
@property (nonatomic, weak) id <AMZSliderDelegate> delegate;

// Projection
@property (nonatomic) GLKMatrix4 GLKTransform;       // to transform points in Z-slider space to screen space. defaults to identity.
@property (nonatomic) CGPoint zeroIntersectionPoint; // the point at which the slider track intersects the plane z=0. defaults to 0, 0.

// Track
@property (nonatomic) CGFloat minimumZValue;         // defaults to 0
@property (nonatomic) CGFloat maximumZValue;         // defaults to 0

// Knobs
- (void)reloadKnobs;

@end

@protocol AMZSliderDataSource <NSObject>
- (NSUInteger)numberOfKnobsInZSlider:(AMZSlider *)zSlider;
- (CGFloat)zSlider:(AMZSlider *)zSlider zPositionOfKnob:(NSUInteger)knobIndex;
- (UIColor *)zSlider:(AMZSlider *)zSlider colorOfKnob:(NSUInteger)knobIndex;
@end

@protocol AMZSliderDelegate <NSObject>
@optional
- (void)zSlider:(AMZSlider *)zSlider didMoveKnob:(NSUInteger)knobIndex toZPosition:(CGFloat)zPosition;
@end
