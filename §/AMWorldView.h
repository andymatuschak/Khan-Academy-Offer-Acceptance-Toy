//
//  AMWorldView.h
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AMWorldViewGameState) {
    AMWorldViewGameStateActive,
    AMWorldViewGameStateComplete
};

@protocol AMWorldViewDataSource, AMWorldViewDelegate;
@interface AMWorldView : UIView
@property (nonatomic, weak) id <AMWorldViewDataSource> dataSource;
@property (nonatomic, weak) id <AMWorldViewDelegate> delegate;
@property (nonatomic, assign) AMWorldViewGameState gameState;
- (void)reloadPlanes;
@end

@class AMPlane;
@protocol AMWorldViewDataSource <NSObject>
- (NSUInteger)numberOfPlanesInWorldView:(AMWorldView *)worldView;
- (AMPlane *)worldView:(AMWorldView *)worldView planeAtIndex:(NSUInteger)planeIndex;
- (UIBezierPath *)completeMessageForWorldView:(AMWorldView *)worldView;
@end

@protocol AMWorldViewDelegate <NSObject>
@optional
- (void)worldView:(AMWorldView *)worldView didMovePlane:(NSUInteger)planeIndex toZPosition:(CGFloat)zPosition;
- (void)worldViewDidReceiveRestartAction:(AMWorldView *)worldView;
@end
