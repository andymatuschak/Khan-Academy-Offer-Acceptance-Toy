//
//  AMAppDelegate.m
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import "AMAppDelegate.h"
#import "AMNoMotionAvailableWarningViewController.h"
#import "AMScenario.h"
#import "AMToyRootViewController.h"
#import "FBTweakStore.h"
#import "FBTweakViewController.h"

@interface AMAppDelegate () <FBTweakViewControllerDelegate>
@property (nonatomic) AMToyRootViewController *toyRootViewController;
@end

@implementation AMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    BOOL overrideDeviceMotionCheck = NO;
#if DEVELOPMENT
    overrideDeviceMotionCheck = YES;
#endif
    
    if ([[[CMMotionManager alloc] init] isDeviceMotionAvailable] || overrideDeviceMotionCheck) {
        self.toyRootViewController = [[AMToyRootViewController alloc] init];
        self.window.rootViewController = self.toyRootViewController;
        // Load up the scenario asynchronously to avoid blocking the main thread.
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSError *error = nil;
            AMScenario *scenario = [AMScenario loadPrimaryScenarioWithError:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (scenario) {
                    self.toyRootViewController.scenario = scenario;
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Couldn't load message!" message:@"This isn't going to work at all! Ask Andy for more info." delegate:nil cancelButtonTitle:@"Sad Times" otherButtonTitles:nil] show];
                }
            });
        });
    } else {
        self.window.rootViewController = [[AMNoMotionAvailableWarningViewController alloc] init];
    }
    
#if DEVELOPMENT
    UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showTweaks)];
    twoFingerTap.numberOfTouchesRequired = 2;
    twoFingerTap.numberOfTapsRequired = 2;
    [self.window addGestureRecognizer:twoFingerTap];
#endif
    
    [self.window makeKeyAndVisible];
    return YES;
}

#if DEVELOPMENT

- (void)showTweaks
{
    FBTweakViewController *tweakViewController = [[FBTweakViewController alloc] initWithStore:[FBTweakStore sharedInstance]];
    tweakViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    tweakViewController.tweaksDelegate = self;
    [self.window.rootViewController presentViewController:tweakViewController animated:YES completion:nil];
}

#endif

- (void)tweakViewControllerPressedDone:(FBTweakViewController *)tweakViewController
{
    [tweakViewController dismissViewControllerAnimated:YES completion:nil];
}


@end
