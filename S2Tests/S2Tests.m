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
    
    NSMutableDictionary * m_pullingDict;
}

@end

@implementation S2Tests

- (void)setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    
    m_pullingDict = [[NSMutableDictionary alloc]init];
}

- (void)tearDown
{
    NSLog(@"over, will close");
    [cont shutDown];
    
    [messenger closeConnection];
    
    [m_pullingDict removeAllObjects];
    
    [super tearDown];
}

- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:S2_MASTER viaNotification:notif]) {
        case S2_EXEC_PULLINGSTARTED:{
            
            break;
        }
            
        default:
            break;
    }
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


- (void) testListUpdated {
    // 起動する
    NSDictionary * dict = @{KEY_WEBSOCKETSERVER_ADDRESS: TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:dict withMasterName:[messenger myNameAndMID]];
    
    
    while (true) {
        if ([cont state] == STATE_IGNITED) {
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    
    NSString * message = [[NSString alloc]initWithFormat:@"%@%@%@%@%@",
                          TRIGGER_PREFIX_LISTED, KEY_LISTED_DELIM,
                          TEST_LISTED_1, KEY_LISTED_DELIM,
                          TEST_LISTED_2];
    
    // listUpdate送付
    [self connectClientTo:TEST_SERVER_URL withMessage:message withPipe:nil];
    
    // 2件のpulling状態になる。このテスト内での辞書を数えよう。
    XCTAssertTrue([m_pullingDict count] == 2, @"not match, %d", [m_pullingDict count]);
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
    
    XCTFail(@"not yet implemented");
    
    
    // 対応するpulledの後、CompileChamberControllerへと装填
    
}







@end
