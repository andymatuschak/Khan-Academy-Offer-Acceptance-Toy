//
//  AMScenario.h
//  §
//
//  Copyright (c) 2014 Andy Matuschak. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString * const AMScenarioErrorDomain;
const int AMScenerioErrorCodePrimaryScenarioLoadFailure;

@interface AMScenario : NSObject <NSCopying>
+ (instancetype)loadPrimaryScenarioWithError:(NSError * __autoreleasing *)error; // may perform blocking I/O -- call from background

- (instancetype)initWithPlanes:(NSArray *)planes completePath:(UIBezierPath *)completePath;
@property (readonly, nonatomic) NSArray *planes;

@property (readonly, nonatomic, getter=isComplete) BOOL complete;
@property (readonly, nonatomic) UIBezierPath *completePath;
@end
