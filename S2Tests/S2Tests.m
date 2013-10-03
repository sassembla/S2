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

#define TEST_MASTER     (@"TEST_MASTER")
#define TEST_SERVER_URL (@"ws://127.0.0.1:8824")
#define TEST_MESSAGE    (@"TEST_MESSAGE")

#define TEST_PATH_NSWS  (@"./S2Tests/TestResource/tool/nsws")

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



// utility
- (NSPipe * ) connectClientTo:(NSString * )url withMessage:(NSString * )message withPipe:(NSPipe * )pipe {
    NSPipe * input = [[NSPipe alloc]init];
    if (pipe) input = pipe;
    
    NSTask * wsclient = [[NSTask alloc]init];
    [wsclient setLaunchPath:TEST_PATH_NSWS];
    [wsclient setArguments:@[@"-m", message, @"-t", url]];
    [wsclient launch];
    
    return input;
}



/**
 初期化、起動時の処理
 */
- (void) testIgniteThenDown {
    /*
     WebSocketServerの起動
     */
    NSDictionary * dict = @{KEY_WEBSOCKETSERVER_ADDRESS: TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:dict withMasterName:TEST_MASTER];
}


- (void) testIgniteThenConnectDummyClient {
    // 起動する
    NSDictionary * dict = @{KEY_WEBSOCKETSERVER_ADDRESS: TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:dict withMasterName:TEST_MASTER];
    
    
    while (true) {
        if ([cont state] == STATE_IGNITED) {
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // クライアントから接続、メッセージを送付
    [self connectClientTo:TEST_SERVER_URL withMessage:TEST_MESSAGE withPipe:nil];
    
    // 接続を待つ
    while (true) {
        if ([cont state] == STATE_CONNECTED) {
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
}

- (void) test {
    
}





@end
