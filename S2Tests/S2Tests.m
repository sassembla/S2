//
//  S2Tests.m
//  S2Tests
//
//  Created by sassembla on 2013/09/21.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KSMessenger.h"

#import "S2Controller.h"

#import "TimeMine.h"

#define TEST_MASTER (@"TEST_MASTER")


#define TEST_SERVER_URL (@"ws://test:8824")



@interface S2Tests : XCTestCase {
    KSMessenger * messenger;
    S2Controller * cont;
}

@end

@implementation S2Tests

- (void)setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    
    cont = [[S2Controller alloc]initWithMaster:TEST_MASTER];
}

- (void)tearDown
{
    [cont shutDown];
    
    [messenger closeConnection];
    
    [TimeMine setTimeMineLocalizedFormat:@"2013/09/23 10:45:27" withLimitSec:1000 withComment:@"WebSocketServerの終了に時間がかかったイメージ。"];
    [super tearDown];
}

- (void) receiver:(NSNotification * )notif {
    
}




/**
 初期化、起動時の処理
 */
- (void) testIgnite {
    /*
     WebSocketServerの起動
     */
    [messenger call:S2_MASTER withExec:EXEC_INITIALIZE,
     [messenger tag:@"url" val:TEST_SERVER_URL],
     nil];
}

- (void) testIgnite2 {
    /*
     起動後、仮clientから接続
     */
    [messenger call:S2_MASTER withExec:EXEC_INITIALIZE,
     [messenger tag:@"url" val:TEST_SERVER_URL],
     nil];
    
    
}


@end
