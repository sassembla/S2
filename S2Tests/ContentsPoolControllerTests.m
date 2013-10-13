//
//  ContentsPoolControllerTests.m
//  S2
//
//  Created by sassembla on 2013/10/13.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KSMessenger.h"

#import "ContentsPoolController.h"

#define TEST_MASTER (@"TEST_MASTER")

@interface ContentsPoolControllerTests : XCTestCase

@end

@implementation ContentsPoolControllerTests {
    KSMessenger * messenger;
    ContentsPoolController * cPoolCont;
}

//- (void)setUp
//{
//    [super setUp];
//    messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
//    cPoolCont = [[ContentsPoolController alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
//}
//
//- (void)tearDown
//{
//    [cPoolCont close];
//    [messenger closeConnection];
//    [super tearDown];
//}
//
//- (void) receiver:(NSNotification * )notif {
//    
//}
//
//- (void)testExample
//{
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
//}

@end
