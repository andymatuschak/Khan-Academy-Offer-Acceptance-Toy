//
//  AMToyRootViewController.m
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import "AMPlane.h"
#import "AMScenario.h"
#import "AMToyRootViewController.h"
#import "AMWorldView.h"

@interface AMToyRootViewController () <AMWorldViewDataSource, AMWorldViewDelegate>
@property (nonatomic) AMWorldView *worldView;
@property (nonatomic) AMScenario *originalScenario;
@end


@implementation AMToyRootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
    return self;
}

- (void)loadView {
    self.worldView = [[AMWorldView alloc] init];
    self.worldView.dataSource = self;
    self.worldView.delegate = self;
    self.view = self.worldView;
    
#if DEVELOPMENT
    UILongPressGestureRecognizer *twoFingerLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(complete:)];
    twoFingerLongPress.numberOfTouchesRequired = 2;
    twoFingerLongPress.minimumPressDuration = 1.0;
    [self.view addGestureRecognizer:twoFingerLongPress];
#endif
}

- (NSUInteger)supportedInterfaceOrientations { return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight; }
- (BOOL)prefersStatusBarHidden { return YES; }

- (void)setScenario:(AMScenario *)scenario {
    if (_scenario != scenario) {
        _scenario = scenario;
        self.originalScenario = [scenario copy];
        [self.worldView reloadPlanes];
    }
}

#pragma mark Planes

- (NSUInteger)numberOfPlanesInWorldView:(AMWorldView *)worldView {
    return [self.scenario.planes count];
}

- (AMPlane *)worldView:(AMWorldView *)worldView planeAtIndex:(NSUInteger)planeIndex {
    return self.scenario.planes[planeIndex];
}

- (void)worldView:(AMWorldView *)worldView didMovePlane:(NSUInteger)planeIndex toZPosition:(CGFloat)zPosition {
#if DEVELOPMENT
    NSLog(@"Moved %ld to %f", (long)planeIndex, zPosition);
#endif
    [self.scenario.planes[planeIndex] setZPosition:zPosition];
    if (self.scenario.complete) {
        worldView.gameState = AMWorldViewGameStateComplete;
    }
}

- (UIBezierPath *)completeMessageForWorldView:(AMWorldView *)worldView {
    return self.scenario.completePath;
}

- (void)worldViewDidReceiveRestartAction:(AMWorldView *)worldView {
    self.scenario = self.originalScenario;
    self.worldView.gameState = AMWorldViewGameStateActive;
}

#if DEVELOPMENT

- (void)complete:(UIGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.worldView.gameState = !self.worldView.gameState;
    }
}

#endif

@end
