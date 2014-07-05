//
//  AMScenario.m
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import "AMPlane.h"
#import "AMScenario.h"
#import "FBTweakInline.h"
#import "PocketSVG.h"

NSString * const AMScenarioErrorDomain = @"AMScenarioErrorDomain";
const int AMScenerioErrorPrimaryScenarioParsingError = 0;

#define AMPrimaryScenarioPlaneCount 5
static const CGFloat AMPrimaryScenarioTargetZPositions[AMPrimaryScenarioPlaneCount] = { -400, 200, 100, -200, 0 };
static const CGFloat AMPrimaryScenarioInitialZPositions[AMPrimaryScenarioPlaneCount] = { -500, 250, 0, -50, 150 };

@implementation AMScenario

+ (instancetype)loadPrimaryScenarioWithError:(NSError * __autoreleasing *)error {
    static AMScenario *__primaryScenario;
    static dispatch_once_t __onceToken;
    dispatch_once(&__onceToken, ^{
        NSMutableArray *planes = [NSMutableArray array];
        BOOL didFail = NO;
        for (int i = 0; i < AMPrimaryScenarioPlaneCount; i++) {
            CGPathRef path = [PocketSVG pathFromSVGFileNamed:[NSString stringWithFormat:@"%d", i]];
            if (!path) {
                if (error) *error = [NSError errorWithDomain:AMScenarioErrorDomain code:AMScenerioErrorCodePrimaryScenarioLoadFailure userInfo:nil];
                didFail = YES;
                break;
            }
            
            AMPlane *plane = [[AMPlane alloc] initWithBezierPath:[UIBezierPath bezierPathWithCGPath:path]
                                                 targetZPosition:AMPrimaryScenarioTargetZPositions[i]];
            plane.zPosition = AMPrimaryScenarioInitialZPositions[i];
            [planes addObject:plane];
        }
        
        CGPathRef completePath = [PocketSVG pathFromSVGFileNamed:@"NoPeeking"];
        if (!completePath) {
            if (error) *error = [NSError errorWithDomain:AMScenarioErrorDomain code:AMScenerioErrorCodePrimaryScenarioLoadFailure userInfo:nil];
            didFail = YES;
        }
        
        if (!didFail) {
            __primaryScenario = [[AMScenario alloc] initWithPlanes:planes completePath:[UIBezierPath bezierPathWithCGPath:completePath]];
        }
    });
    return __primaryScenario;
}

- (instancetype)initWithPlanes:(NSArray *)planes completePath:(UIBezierPath *)completePath {
    if (!(self = [super init])) return nil;
    _planes = planes;
    _completePath = completePath;
    return self;
}

static CGFloat AMZScenarioCompletionThreshold() { return FBTweakValue(@"Scenario", @"Winning", @"Threshold", 50); }

- (BOOL)isComplete {
    // What matters is that the deltas match.
    CGFloat error = 0;
    for (int i = 1; i < AMPrimaryScenarioPlaneCount; i++) {
        CGFloat targetDelta = AMPrimaryScenarioTargetZPositions[i] - AMPrimaryScenarioTargetZPositions[i-1];
        CGFloat currentDelta = [self.planes[i] zPosition] - [self.planes[i-1] zPosition];
        error += fabs(targetDelta - currentDelta);
    }
    return error <= AMZScenarioCompletionThreshold();
}

- (id)copyWithZone:(NSZone *)zone {
    NSMutableArray *newPlanes = [NSMutableArray array];
    for (AMPlane *plane in self.planes) {
        [newPlanes addObject:[plane copy]];
    }
    return [[AMScenario alloc] initWithPlanes:newPlanes completePath:self.completePath];
}

@end
