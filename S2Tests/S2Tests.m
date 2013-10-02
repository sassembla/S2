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


/**
 S2全体の挙動に関わるテスト
 usecase的な書き方をするのがいいんだろうなー。
 */
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
}

- (void)tearDown
{
    [cont shutDown];
    
    [messenger closeConnection];
    [super tearDown];
}

- (void) receiver:(NSNotification * )notif {
    
}




/**
 初期化、起動時の処理
 */
- (void) testIgniteThenDown {
    /*
     WebSocketServerの起動
     */
    NSDictionary * dict = @{@"url": TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:dict withMasterName:TEST_MASTER];
}

/**
 連続した挙動のテスト
 */
- (void) testIgniteThenConnectDummyClient {
    
}

@end
