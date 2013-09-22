//
//  S2Tests.m
//  S2Tests
//
//  Created by sassembla on 2013/09/21.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KSMessenger.h"


#define TEST_MASTER (@"TEST_MASTER")

@interface S2Tests : XCTestCase {
    KSMessenger * messenger;
}

@end

@implementation S2Tests

- (void)setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    [messenger closeConnection];
    [super tearDown];
}

/**
 初期化、起動時の処理
 */
- (void) testIgnite {
    
}
- (void)testExample
{
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
