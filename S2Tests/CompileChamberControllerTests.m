//
//  CompileChamberControllerTests.m
//  S2
//
//  Created by sassembla on 2013/10/07.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KSMessenger.h"


#define TEST_MASTER (@"TEST_MASTER")

#import "S2TestSupportDefines.h"


/**
 Chamberのコントロールを行う
 
 
 */
@interface CompileChamberControllerTests : XCTestCase {
    KSMessenger * messenger;
//    CompileChamberController * comp;
}

@end

@implementation CompileChamberControllerTests

- (void)setUp
{
    [super setUp];
//    comp = [[CompileChamberController alloc] initWithMasterNameAndId:[messenger myNameAndMID]];
}

- (void)tearDown
{
//    [comp close];
    [messenger closeConnection];
    [super tearDown];
}







@end
