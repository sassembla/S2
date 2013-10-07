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

#import "S2Token.h"
#import "S2TestSupportDefines.h"

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
    [wsclient setArguments:@[@"-m", message, @"-t", url, @"-q"]];
    
    [wsclient setStandardInput:input];
    
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
    
    cont = [[S2Controller alloc]initWithDict:dict withMasterName:[messenger myNameAndMID]];
}


- (void) testWaitIgnited {
    // 起動する
    NSDictionary * dict = @{KEY_WEBSOCKETSERVER_ADDRESS: TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:dict withMasterName:[messenger myNameAndMID]];
    
    
    while (true) {
        if ([cont state] == STATE_IGNITED) {
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
}

- (void) testConnectionCountAppend {
    // 起動する
    NSDictionary * dict = @{KEY_WEBSOCKETSERVER_ADDRESS: TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:dict withMasterName:[messenger myNameAndMID]];
    
    
    while (true) {
        if ([cont state] == STATE_IGNITED) {
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // クライアントから接続、メッセージを送付
    [self connectClientTo:TEST_SERVER_URL withMessage:TEST_MESSAGE withPipe:nil];
   
    // update count up
    while (true) {
        if (0 < [cont updatedCount]) {
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    
}


- (void) testUpdated {
    // 起動する
    NSDictionary * dict = @{KEY_WEBSOCKETSERVER_ADDRESS: TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:dict withMasterName:[messenger myNameAndMID]];
    
    
    while (true) {
        if ([cont state] == STATE_IGNITED) {
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // クライアントから接続、メッセージを送付
    [self connectClientTo:TEST_SERVER_URL withMessage:TEST_MESSAGE withPipe:nil];
    
    
    // update count up
    while (true) {
        if (0 < [cont updatedCount]) {
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
//    // listUpdate送付
//    [self connectClientTo:TEST_SERVER_URL withMessage:TEST_MESSAGE withPipe:nil];
    
}




/*
 connectとは無関係に、クライアントからのコード一覧の送付、コード断片のアップデートに対応する
 */
- (void) testReceiveCodeList {

    // リストを受け取ると、その後Pullを発生させる(チャンバーとは関係ないけどスケールするのかなここ。先にテスト書いちゃった方がいいな。)
    // messagingで送った方が無難なんだが、connectionContのフリをするのは大変かなあ？誘発するアクションを実行すれば良いよね。
//    [self connectClientTo:TEST_SERVER_URL withMessage:pulledMessage withPipe:nil];
    
    
    
    // まとまってないので後回し
    
    
    
//    NSArray * pullingLists = [self pulling]
//    
//    
//    // 擬似的にpulledを二件送る
//    for (NSString * pullingId in pullingLists) {
//        // デリミタもろとも、update扱いでいいんじゃねーの？って気がしてきた。syncに替わるsyncみたいな概念について考えると楽しそう。
//        NSString * pulledMessage = [[NSString alloc]initWithFormat:@"%@%@", TEST_PULLED, @"somecode"];
//        [self connectClientTo:TEST_SERVER_URL withMessage:pulledMessage withPipe:nil];
//    }
    
    
    // 対応するpulledの後、CompileChamberControllerへと装填
    
}







@end
