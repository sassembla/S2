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
    
    NSMutableArray * m_pullCompleteArray;
    NSMutableArray * m_spinuppedArray;
    NSMutableArray * m_ignitedChamberArray;
    NSMutableArray * m_compiledChamberArray;
    
    int m_repeatCount;
}

@end

@implementation S2Tests

- (void)setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    
    m_pullingDict = [[NSMutableDictionary alloc]init];
    m_pullCompleteArray = [[NSMutableArray alloc]init];
    m_spinuppedArray = [[NSMutableArray alloc]init];
    m_ignitedChamberArray = [[NSMutableArray alloc]init];
    m_compiledChamberArray = [[NSMutableArray alloc]init];
    
    m_repeatCount = 0;
}

- (void)tearDown
{
    NSLog(@"over, will close");
    [cont shutDown];
    
    [messenger closeConnection];
    
    [m_pullingDict removeAllObjects];
    [m_pullCompleteArray removeAllObjects];
    [m_spinuppedArray removeAllObjects];
    [m_ignitedChamberArray removeAllObjects];
    [m_compiledChamberArray removeAllObjects];
    
    [super tearDown];
}

- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];

    XCTAssertNotNil(dict[@"wrappedDict"], @"wrappedDict required");
    NSDictionary * wrappedDict = dict[@"wrappedDict"];
    
    switch ([messenger execFrom:S2_MASTER viaNotification:notif]) {
        case S2_CONT_EXEC_DISCONNECTED:{
            break;
        }
        case S2_CONT_EXEC_CONNECTED:{
            break;
        }
            
        case S2_CONT_EXEC_PULLINGSTARTED:{
            XCTAssertNotNil(wrappedDict[@"pullingId"], @"pullingId required");
            XCTAssertNotNil(wrappedDict[@"sourcePath"], @"sourcePath required");
            
            [m_pullingDict setObject:wrappedDict[@"sourcePath"] forKey:wrappedDict[@"pullingId"]];
            break;
        }
        case S2_CONT_EXEC_PULLINGCOMPLETED:{
            [m_pullCompleteArray addObject:@"pulled"];
            break;
        }
        case S2_CONT_EXEC_SPINUPPED:{
            [m_spinuppedArray addObject:@"spinupped"];
            break;
        }
        case S2_CONT_EXEC_IGNITED:{
            XCTAssertNotNil(wrappedDict[@"ignitedChamberId"], @"ignitedChamberId required");

            [m_ignitedChamberArray addObject:wrappedDict[@"ignitedChamberId"]];
            break;
        }
        case S2_CONT_EXEC_COMPILED:{
            XCTAssertNotNil(wrappedDict[@"compiledChamberId"], @"compiledChamberId required");
            
            [m_compiledChamberArray addObject:wrappedDict[@"compiledChamberId"]];
            break;
        }
    }
}



// utility
/**
 WebSocketでの通信を行い、データを送付して切断する
 */
- (void) connectClientTo:(NSString * )url withMessage:(NSString * )message {

    // kill all nsws before
    NSTask * killAllNsws = [[NSTask alloc] init];
    [killAllNsws setLaunchPath:@"/usr/bin/killall"];
    [killAllNsws setArguments:@[@"-9", @"nsws"]];
    [killAllNsws launch];
    [killAllNsws waitUntilExit];
    
    NSTask * wsclient = [[NSTask alloc]init];
    [wsclient setLaunchPath:TEST_PATH_NSWS];
    [wsclient setArguments:@[@"-m", message, @"-t", url, @"-q"]];
    [wsclient launch];
    
    [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    // kill all nsws
    NSTask * killAllNsws2 = [[NSTask alloc] init];
    [killAllNsws2 setLaunchPath:@"/usr/bin/killall"];
    [killAllNsws2 setArguments:@[@"-9", @"nsws"]];
    [killAllNsws2 launch];
    [killAllNsws2 waitUntilExit];
    
    [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
}

- (bool) countupThenFail {
    m_repeatCount++;
    if (TEST_REPEAT_COUNT < m_repeatCount) {
        return true;
    }
    return false;
}

- (bool) countupLongThenFail {
    m_repeatCount++;
    if (TEST_REPEAT_COUNT_5 < m_repeatCount) {
        return true;
    }
    return false;
}

- (NSString * ) readSource:(NSString * )filePath {
    NSFileHandle * readHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    
    if (readHandle) {
        NSData * data = [readHandle readDataToEndOfFile];
        NSString * fileContentsStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        return fileContentsStr;
    }
    
    return nil;
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
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
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
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // クライアントから接続、メッセージを送付
    [self connectClientTo:TEST_SERVER_URL withMessage:TEST_MESSAGE];
   
    // update count up
    while ([cont updatedCount] == 0) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    
}


- (void) testListUpdated {
    // 起動する
    NSDictionary * serverSettingDict = @{KEY_WEBSOCKETSERVER_ADDRESS: TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:serverSettingDict withMasterName:[messenger myNameAndMID]];
    
    
    while (true) {
        if ([cont state] == STATE_IGNITED) {
            break;
        }
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    NSArray * pullArray = @[TEST_LISTED_1, TEST_LISTED_2];
    NSString * message = [[NSString alloc]initWithFormat:@"%@%@%@",
                          S2_TRIGGER_PREFIX_LISTED, KEY_LISTED_DELIM,
                          [pullArray componentsJoinedByString:KEY_LISTED_DELIM]
                          ];
    
    // listUpdate送付
    [self connectClientTo:TEST_SERVER_URL withMessage:message];
    
    while ([m_pullingDict count] < [pullArray count]) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // 2件のpulling状態になる。このテスト内での辞書を数えよう。
    XCTAssertTrue([m_pullingDict count] == [pullArray count], @"not match, %lu vs %lu", (unsigned long)[pullArray count], (unsigned long)[m_pullingDict count]);
}



/**
 pull後のpulledを発生させる。idとかも勝手に入力。
 */
- (void) testPulledPartial {
    // 起動する
    NSDictionary * serverSettingDict = @{KEY_WEBSOCKETSERVER_ADDRESS: TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:serverSettingDict withMasterName:[messenger myNameAndMID]];
    
    
    while (true) {
        if ([cont state] == STATE_IGNITED) {
            break;
        }
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }

    NSArray * pullArray = @[TEST_LISTED_1, TEST_LISTED_2];
    NSString * message = [[NSString alloc]initWithFormat:@"%@%@%@",
                          S2_TRIGGER_PREFIX_LISTED, KEY_LISTED_DELIM,
                          [pullArray componentsJoinedByString:KEY_LISTED_DELIM]
                          ];
    
    // listUpdate送付
    [self connectClientTo:TEST_SERVER_URL withMessage:message];// 1
    
    while ([m_pullingDict count] < [pullArray count]) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }

    // pullArrayの内容を送付
    for (NSString * key in [m_pullingDict allKeys]) {
        NSString * message2 = [[NSString alloc]initWithFormat:@"%@%@%@%@%@",
                               S2_TRIGGER_PREFIX_PULLED, KEY_LISTED_DELIM,
                               key, KEY_LISTED_DELIM, [self readSource:key]
                               ];
        
        [self connectClientTo:TEST_SERVER_URL withMessage:message2];
    }
    
    // spinupが終わるまで待つ
    while ([m_spinuppedArray count] < [pullArray count]) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    XCTAssertTrue([m_spinuppedArray count] == S2_DEFAULT_CHAMBER_COUNT, @"not match, %lu", (unsigned long)[m_spinuppedArray count]);
}

/**
 listを送付、
 updateでコードを作成、
 プロジェクトを生成してビルド開始させる
 */
- (void) testUpdateThenStartCompilation {
    // 起動する
    NSDictionary * serverSettingDict = @{KEY_WEBSOCKETSERVER_ADDRESS: TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:serverSettingDict withMasterName:[messenger myNameAndMID]];
    
    while ([cont state] != STATE_IGNITED) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }

    // フルパッケージのリストを渡す 最後にcompile条件であるTEST_COMPILEBASEPATHがそろう
    NSArray * pullArray = @[TEST_SCALA_1, TEST_SCALA_2, TEST_SCALA_3, TEST_COMPILEBASEPATH];
    
    // listUpdate送付
    NSString * message = [[NSString alloc]initWithFormat:@"%@%@%@",
                          S2_TRIGGER_PREFIX_LISTED, KEY_LISTED_DELIM,
                          [pullArray componentsJoinedByString:KEY_LISTED_DELIM]
                          ];
    
    [self connectClientTo:TEST_SERVER_URL withMessage:message];
    
    
    // pullUpが設定分のカウントを出すまで、、という適当な待ちを行う
    while ([m_pullingDict count] < [pullArray count]) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // pullArrayの内容を送付
    for (NSString * key in [m_pullingDict allKeys]) {
        NSString * message2 = [[NSString alloc]initWithFormat:@"%@%@%@%@%@",
                              S2_TRIGGER_PREFIX_PULLED, KEY_LISTED_DELIM,
                              key, KEY_LISTED_DELIM, [self readSource:key]
                              ];
        
        [self connectClientTo:TEST_SERVER_URL withMessage:message2];// このタイミングでspinuppedがたまたま合ってるだけ！
    }
    
    // spinupが終わるまで待つ
    while ([m_spinuppedArray count] < [pullArray count]) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    
    // この時点でコンパイル開始した形跡がある。
    XCTAssertTrue(0 < [m_ignitedChamberArray count], @"not match, %lu", (unsigned long)[m_ignitedChamberArray count]);
}


/**
 コンパイル完了まで
 */
- (void) testListedThenFinishCompletion {
    // 起動する
    NSDictionary * serverSettingDict = @{KEY_WEBSOCKETSERVER_ADDRESS: TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:serverSettingDict withMasterName:[messenger myNameAndMID]];
    
    while ([cont state] != STATE_IGNITED) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // フルパッケージをのリストを渡す 最後にcompile条件であるTEST_COMPILEBASEPATHがそろう
    NSArray * pullArray = @[TEST_SCALA_1, TEST_SCALA_2, TEST_SCALA_3, TEST_COMPILEBASEPATH];
    
    // listUpdate送付
    NSString * message = [[NSString alloc]initWithFormat:@"%@%@%@",
                          S2_TRIGGER_PREFIX_LISTED, KEY_LISTED_DELIM,
                          [pullArray componentsJoinedByString:KEY_LISTED_DELIM]
                          ];
    
    [self connectClientTo:TEST_SERVER_URL withMessage:message];
    
    
    // pullUpが設定分のカウントを出すまで、、という適当な待ちを行う
    while ([m_pullingDict count] < [pullArray count]) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    
    // pullArrayの内容を送付
    for (NSString * key in [m_pullingDict allKeys]) {
        NSString * message2 = [[NSString alloc]initWithFormat:@"%@%@%@%@%@",
                               S2_TRIGGER_PREFIX_PULLED, KEY_LISTED_DELIM,
                               key, KEY_LISTED_DELIM, [self readSource:key]
                               ];
        
        [self connectClientTo:TEST_SERVER_URL withMessage:message2];
    }
    
    // この時点で、pull completeによってコンパイルが開始される。
    
    // 全チャンバーのスピンアップが発生、完了している。
    while ([m_spinuppedArray count] < S2_DEFAULT_CHAMBER_COUNT) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // 特定のチャンバーのコンパイルの完了を待つ。 m_ignitedArray[0]内のチャンバーの終了がくるまで待つ。
    while ([m_compiledChamberArray count] == 0) {
        if ([self countupLongThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    
    
    // この時点でコンパイル完了した形跡がある。
    XCTAssertTrue([m_ignitedChamberArray count] == 1, @"not match, %lu", (unsigned long)[m_ignitedChamberArray count]);
}


/**
 起動からempty状態のままでコンパイル開始まで、コンパイルは発生しない。
 */
- (void) testNotStartCompilation {
    // 起動する
    NSDictionary * serverSettingDict = @{KEY_WEBSOCKETSERVER_ADDRESS: TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:serverSettingDict withMasterName:[messenger myNameAndMID]];
    
    while ([cont state] != STATE_IGNITED) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // コンパイル発動
    NSString * compileMessage = [[NSString alloc]initWithFormat:@"%@", S2_TRIGGER_PREFIX_COMPILE];
    [self connectClientTo:TEST_SERVER_URL withMessage:compileMessage];
    
    
    // この時点でコンパイル開始した形跡が無い。
    XCTAssertTrue([m_ignitedChamberArray count] == 0, @"not match, %lu", (unsigned long)[m_ignitedChamberArray count]);
}



/**
 アップデートでのコンパイル終了まで
 */
- (void) testUpdatedThenFinishCompletion {
    // 起動する
    NSDictionary * serverSettingDict = @{KEY_WEBSOCKETSERVER_ADDRESS: TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:serverSettingDict withMasterName:[messenger myNameAndMID]];
    
    while ([cont state] != STATE_IGNITED) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    NSArray * pullArray = @[TEST_SCALA_1, TEST_SCALA_2, TEST_SCALA_3, TEST_COMPILEBASEPATH];
    
    // listUpdate送付
    NSString * message = [[NSString alloc]initWithFormat:@"%@%@%@",
                          S2_TRIGGER_PREFIX_LISTED, KEY_LISTED_DELIM,
                          [pullArray componentsJoinedByString:KEY_LISTED_DELIM]
                          ];
    
    [self connectClientTo:TEST_SERVER_URL withMessage:message];
    
    
    // pullUpが設定分のカウントを出すまで、、という適当な待ちを行う
    while ([m_pullingDict count] < [pullArray count]) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // pullArrayの内容を送付
    for (NSString * key in [m_pullingDict allKeys]) {
        NSString * message2 = [[NSString alloc]initWithFormat:@"%@%@%@%@%@",
                               S2_TRIGGER_PREFIX_PULLED, KEY_LISTED_DELIM,
                               key, KEY_LISTED_DELIM, [self readSource:key]
                               ];
        
        [self connectClientTo:TEST_SERVER_URL withMessage:message2];
    }
    
    // 一度目のコンパイルが発生しているので、一つのチャンバーがコンパイルを行っている。
    XCTAssertTrue([m_ignitedChamberArray count] == 1, @"not match, %lu", (unsigned long)[m_ignitedChamberArray count]);
    
    // updateを発生させて、2つ目のチャンバーを動かす
    NSString * message3 = [[NSString alloc]initWithFormat:@"%@:%@ %@", S2_TRIGGER_PREFIX_UPDATED, TEST_SCALA_1, [self readSource:TEST_SCALA_1]];
    [self connectClientTo:TEST_SERVER_URL withMessage:message3];
    
    XCTAssertTrue([m_ignitedChamberArray count] == 2, @"not match, %lu", (unsigned long)[m_ignitedChamberArray count]);
}


- (void) testCompileThenFinishCompile {
    // 起動する
    NSDictionary * serverSettingDict = @{KEY_WEBSOCKETSERVER_ADDRESS: TEST_SERVER_URL};
    
    cont = [[S2Controller alloc]initWithDict:serverSettingDict withMasterName:[messenger myNameAndMID]];
    
    while ([cont state] != STATE_IGNITED) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    NSArray * pullArray = @[TEST_SCALA_1, TEST_SCALA_2, TEST_SCALA_3, TEST_COMPILEBASEPATH];
    
    // listUpdate送付
    NSString * message = [[NSString alloc]initWithFormat:@"%@%@%@",
                          S2_TRIGGER_PREFIX_LISTED, KEY_LISTED_DELIM,
                          [pullArray componentsJoinedByString:KEY_LISTED_DELIM]
                          ];
    
    [self connectClientTo:TEST_SERVER_URL withMessage:message];
    
    
    // pullUpが設定分のカウントを出すまで、、という適当な待ちを行う
    while ([m_pullingDict count] < [pullArray count]) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // pullArrayの内容を送付
    for (NSString * key in [m_pullingDict allKeys]) {
        NSString * message2 = [[NSString alloc]initWithFormat:@"%@%@%@%@%@",
                               S2_TRIGGER_PREFIX_PULLED, KEY_LISTED_DELIM,
                               key, KEY_LISTED_DELIM, [self readSource:key]
                               ];
        
        [self connectClientTo:TEST_SERVER_URL withMessage:message2];
    }
    
    
    // 一度目のコンパイルが発生しているので、一つのチャンバーがコンパイルを行っている。
    XCTAssertTrue([m_ignitedChamberArray count] == 1, @"not match, %lu", (unsigned long)[m_ignitedChamberArray count]);
    
    // ２つ目のコンパイル
    NSString * message3 = S2_TRIGGER_PREFIX_COMPILE;
    [self connectClientTo:TEST_SERVER_URL withMessage:message3];
    
    
    XCTAssertTrue([m_ignitedChamberArray count] == 2, @"not match, %lu", (unsigned long)[m_ignitedChamberArray count]);
}

@end
