//
//  PullUpControllerTests.m
//  S2
//
//  Created by sassembla on 2013/10/07.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "PullUpController.h"
#import "S2TestSupportDefines.h"

#import "KSMessenger.h"



#define TEST_MASTER (@"TEST_MASTER")


@interface PullUpControllerTests : XCTestCase {
    KSMessenger * messenger;
    
    PullUpController * pullUpCont;
}

@end

@implementation PullUpControllerTests

- (void)setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    pullUpCont = [[PullUpController alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
}


- (void)tearDown
{
    [pullUpCont close];
    [messenger closeConnection];
    [super tearDown];
}


- (void) receiver:(NSNotification * )notif {
    switch ([messenger execFrom:S2_PULLUPCONT viaNotification:notif]) {
        case S2_PULLUPCONT_PULLING:{
            
            break;
        }
            
        default:
            break;
    }
}


/**
 stringをファイルから読み出す。
 */
- (NSString * ) readSource:(NSString * )filePath {
    NSFileHandle * readHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    
    if (readHandle) {
        NSData * data = [readHandle readDataToEndOfFile];
        NSString * fileContentsStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        return fileContentsStr;
    }
    
    return nil;
}





- (void)testReceivedListsThenPulledCodeShouldBeCompleted {
    NSArray * listed = @[TEST_LISTED_1, TEST_LISTED_2];
    
    // このソースのpull開始、該当のソース入力を与えると、completedを送ってくる
    [pullUpCont listed:listed];
    
    
    NSDictionary * pullingDict = [pullUpCont pullingPathList];
    NSArray * keys = [pullingDict allKeys];
    

    // 全てのテスト用コードを読み出す
    for (NSString * key in keys) {
        [pullUpCont pulled:key source:@"something"];
    }
    
    XCTAssertTrue([pullUpCont isCompleted], @"not completed");
}



- (void)testReceivedListsThenPulledThePartOfCodeShouldNotBeCompleted {
    NSArray * listed = @[TEST_LISTED_1, TEST_LISTED_2];
    
    // このソースのpull開始、該当のソース入力を与えると、completedを送ってくる
    [pullUpCont listed:listed];
    
    
    NSDictionary * pullingDict = [pullUpCont pullingPathList];
    NSArray * keys = [pullingDict allKeys];
    
    
    // テスト用コードを読み出す
    NSString * source1 = [self readSource:TEST_LISTED_1];
    [pullUpCont pulled:keys[0] source:source1];
    
    XCTAssertFalse([pullUpCont isCompleted], @"completed");
}



- (void)testReceivedListsShouldNotBeCompleted {
    NSArray * listed = @[TEST_LISTED_1, TEST_LISTED_2];
    
    // このソースのpull開始、該当のソース入力を与えると、completedを送ってくる
    [pullUpCont listed:listed];
    
    XCTAssertFalse([pullUpCont isCompleted], @"completed");
}





@end
