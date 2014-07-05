//
//  AMNoMotionAvailableWarningViewController.m
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import "AMNoMotionAvailableWarningViewController.h"

@implementation AMNoMotionAvailableWarningViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) return nil;
    [self setNeedsStatusBarAppearanceUpdate];
    return self;
}

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:self.view.bounds];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    label.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    label.text = @"You need a physical iPad to run this app.";
    [label sizeToFit];
    [self.view addSubview:label];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
}

- (BOOL)prefersStatusBarHidden { return YES; }

@end
