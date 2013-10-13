//
//  CompileChamberTests.m
//  S2
//
//  Created by sassembla on 2013/10/07.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KSMessenger.h"

#import "CompileChamberController.h"

#define TEST_MASTER (@"TEST_MASTER")

#define TEST_CHAMBER_NUM_2  (2)


#import "S2TestSupportDefines.h"


@interface CompileChamberTests : XCTestCase

@end

@implementation CompileChamberTests {
    KSMessenger * messenger;
    CompileChamberController * cChambCont;
}

- (void) setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    cChambCont = [[CompileChamberController alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
}

- (void) tearDown
{
    [cChambCont close];
    [messenger closeConnection];
    [super tearDown];
}

- (void) testCheckChambersStatus {
    [cChambCont readyChamber:TEST_CHAMBER_NUM_2];
    
    XCTAssertTrue([cChambCont countOfReadyChamber] == TEST_CHAMBER_NUM_2, @"not match, %d", [cChambCont countOfReadyChamber]);
}

- (void) testSourceInputted
{
    [cChambCont readyChamber:TEST_CHAMBER_NUM_2];
    
    // データの受け口へとコードを送る。
    // ファイル名と内容
    NSString * fileName = TEST_LISTED_1;
    NSString * contents = @"test source code content";

    
    [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_INPUT,
     [messenger tag:@"id" val:fileName],
     [messenger tag:@"contents" val:contents],
     nil];
    
    // チャンバーに装填できる形で用意しておく??
    
    
}

//- (void) {
//    
//}


@end
