//
//  S2CompilationResultTests.m
//  S2
//
//  Created by sassembla on 2013/10/22.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "S2Controller.h"

#import "KSMessenger.h"

#import "S2TestSupportDefines.h"
#import "S2Token.h"

#define TEST_SERVER_URL (@"ws://127.0.0.1:8824")

#define TEST_PATH_NSWS  (@"./S2Tests/TestResource/tool/nsws")

#define TEST_MASTER (@"TEST_MASTER")

#import "TimeMine.h"

@interface S2CompilationResultTests : XCTestCase

@end

@implementation S2CompilationResultTests {
    KSMessenger * messenger;
    
    S2Controller * cont;
    
    NSMutableArray * m_ignitedChamberArray;
    NSMutableArray * m_compiledResults;
    NSMutableArray * m_resendArray;
    
    
    int m_repeatCount;
    int m_compiledCounts;
}

- (void)setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    
    m_ignitedChamberArray = [[NSMutableArray alloc]init];
    m_compiledResults = [[NSMutableArray alloc]init];
    m_resendArray = [[NSMutableArray alloc] init];
    
    m_repeatCount = 0;
    m_compiledCounts = 0;
}

- (void)tearDown
{
    [m_ignitedChamberArray removeAllObjects];
    [m_compiledResults removeAllObjects];
    [m_resendArray removeAllObjects];
    
    [cont shutDown];
    [messenger closeConnection];
    [super tearDown];
}

- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    XCTAssertNotNil(dict[@"wrappedDict"], @"wrappedDict required");
    NSDictionary * wrappedDict = dict[@"wrappedDict"];
    
    switch ([messenger execFrom:S2_MASTER viaNotification:notif]) {
        case S2_CONT_EXEC_IGNITED:{
            XCTAssertNotNil(wrappedDict[@"ignitedChamberId"], @"ignitedChamberId required");
            
            [m_ignitedChamberArray addObject:wrappedDict[@"ignitedChamberId"]];
            break;
        }
        case S2_CONT_EXEC_TICK:{
            NSAssert(wrappedDict[@"message"], @"message required");
            [m_compiledResults addObject:wrappedDict[@"message"]];
            break;
        }
        case S2_CONT_EXEC_RESENDED:{
            NSAssert(wrappedDict[@"message"], @"message required");
            [m_resendArray addObject:wrappedDict[@"message"]];
            break;
        }
        case S2_CONT_EXEC_COMPILED:{
            m_compiledCounts++;
            break;
        }
    }
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




// コンパイルの正否系


- (void) testCompileSucceededWithSpecificMessages {
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
    
    NSArray * updateArray = @[TEST_SCALA_1, TEST_SCALA_2, TEST_SCALA_3, TEST_COMPILEBASEPATH];
    
    // updateを発生させる。 最後の一つでコンパイルが開始される。
    for (NSString * path in updateArray) {
        NSString * message3 = [[NSString alloc]initWithFormat:@"%@:%@ %@", S2_TRIGGER_PREFIX_UPDATED, path, [self readSource:path]];
        [self connectClientTo:TEST_SERVER_URL withMessage:message3];
    }
    
    XCTAssertTrue([m_ignitedChamberArray count] == 1, @"not match, %lu", (unsigned long)[m_ignitedChamberArray count]);
   
    while (m_compiledCounts == 0) {
        if ([self countupLongThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    /*
     -daemon ver
     Starting Build
     
     BUILD SUCCESSFUL これだけあればOK
     Total time: (.*) secs
     
     
     */
    XCTAssertTrue([m_compiledResults count] == 1, @"not match, %lu", (unsigned long)[m_compiledResults count]);
}

- (void) testCompileFailure {
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/31 21:57:28" withLimitSec:10000 withComment:@"順で実行すると機能しない。原因を探そう。"];
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
    
    XCTAssertTrue(m_compiledCounts == 0, @"not match, %d", m_compiledCounts);
    
    // コンパイル失敗する組み合わせ
    NSArray * updateArray = @[TEST_SCALA_1, TEST_SCALA_2, TEST_SCALA_3_FAIL, TEST_COMPILEBASEPATH];
    
    // updateを発生させる。 最後の一つでコンパイルが開始される。
    for (NSString * path in updateArray) {
        NSString * message3 = [[NSString alloc]initWithFormat:@"%@:%@ %@", S2_TRIGGER_PREFIX_UPDATED, path, [self readSource:path]];
        [self connectClientTo:TEST_SERVER_URL withMessage:message3];
    }
    
    XCTAssertTrue([m_ignitedChamberArray count] == 1, @"not match, %lu", (unsigned long)[m_ignitedChamberArray count]);
    while (m_compiledCounts < 1) {
        if ([self countupLongThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    /*
     -daemon ver
     
     1)//これはワンセット、この行の何文字目、という。 7の18、とかが出せると良い。 3行かな。
     [ant:scalac] /Users/highvision/S2.fcache/S2Tests/TestResource/sampleProject_gradle/src/main/scala/com/kissaki/TestProject/TestProject_fail.scala:7: error: not found: type Samplaaae2,
     	val b = new Samplaaae2()// typo here
                         ^
     //
     
     2):compileScala FAILED
     */
    
    //ここでは、上記のもののみ受け取るのが正しい。
    XCTAssertTrue([m_compiledResults count] == 2, @"not match, %lu", (unsigned long)[m_compiledResults count]);
}



- (void) testCompileWithZincSucceededWithSpecificMessages {
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
    
    NSArray * updateArray = @[TEST_SCALA_1_ZINC, TEST_SCALA_2_ZINC, TEST_SCALA_3_ZINC, TEST_COMPILEBASEPATH_ZINC];
    
    // updateを発生させる。 最後の一つでコンパイルが開始される。
    for (NSString * path in updateArray) {
        NSString * message3 = [[NSString alloc]initWithFormat:@"%@:%@ %@", S2_TRIGGER_PREFIX_UPDATED, path, [self readSource:path]];
        [self connectClientTo:TEST_SERVER_URL withMessage:message3];
    }
    
    XCTAssertTrue([m_ignitedChamberArray count] == 1, @"not match, %lu", (unsigned long)[m_ignitedChamberArray count]);
    while (m_compiledCounts == 0) {
        if ([self countupLongThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    /*
     -zinc ver
     なんか普通にやろうとしても失敗するんだが。
     3件の失敗と1件のfailedが入る。
     */
    XCTAssertTrue([m_compiledResults count] == 4, @"not match, %lu", (unsigned long)[m_compiledResults count]);
}

- (void) testCompileFailureWithZinc {
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
    
    // コンパイル失敗する組み合わせ
    NSArray * updateArray = @[TEST_SCALA_1_ZINC, TEST_SCALA_2_ZINC, TEST_SCALA_3_FAIL_ZINC, TEST_COMPILEBASEPATH_ZINC];
    
    // updateを発生させる。 最後の一つでコンパイルが開始される。
    for (NSString * path in updateArray) {
        NSString * message3 = [[NSString alloc]initWithFormat:@"%@:%@ %@", S2_TRIGGER_PREFIX_UPDATED, path, [self readSource:path]];
        [self connectClientTo:TEST_SERVER_URL withMessage:message3];
    }
    
    XCTAssertTrue([m_ignitedChamberArray count] == 1, @"not match, %lu", (unsigned long)[m_ignitedChamberArray count]);
    while (m_compiledCounts == 0) {
        if ([self countupLongThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    /*
     -zinc ver
     
     FAILURE: Build failed with an exception.
     BUILD FAILED
     
     * Where:
     Build file '/Users/t.inoue/Desktop/S2/S2Tests/TestResource/sampleProject_gradle_zinc/build.gradle' line: 24
     ,
     
     
     */
    XCTAssertTrue([m_compiledResults count] == 4, @"not match, %lu", (unsigned long)[m_compiledResults count]);
}


/**
 resendが発生する
 */
- (void) testResend {
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
    
    NSArray * updateArray = @[TEST_SCALA_1, TEST_SCALA_2, TEST_SCALA_3, TEST_COMPILEBASEPATH];
    
    // updateを発生させる。 最後の一つでコンパイルが開始される。
    for (NSString * path in updateArray) {
        NSString * message3 = [[NSString alloc]initWithFormat:@"%@:%@ %@", S2_TRIGGER_PREFIX_UPDATED, path, [self readSource:path]];
        [self connectClientTo:TEST_SERVER_URL withMessage:message3];
    }
    
    XCTAssertTrue([m_ignitedChamberArray count] == 1, @"not match, %lu", (unsigned long)[m_ignitedChamberArray count]);
    
    // コンパイルが済んでいるわけがない
    XCTAssertTrue(m_compiledCounts == 0, @"not match, %d", m_compiledCounts);
    
    // この時点でさらにupdateを発生させる
    NSString * message4 = [[NSString alloc]initWithFormat:@"%@:%@ %@", S2_TRIGGER_PREFIX_UPDATED, updateArray[0], [self readSource:updateArray[0]]];
    [self connectClientTo:TEST_SERVER_URL withMessage:message4];
    
    XCTAssertTrue(m_compiledCounts == 0, @"not match, %d", m_compiledCounts);
    
    
    // +1つが着火状態
    XCTAssertTrue([m_ignitedChamberArray count] == 2, @"not match, %lu", (unsigned long)[m_ignitedChamberArray count]);
    
    while (m_compiledCounts < 2) {
        if ([self countupThenFail]) {
            XCTFail(@"too long wait");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // コンパイル済メッセージが最低でも2つ入っているので、resendが発生しているはず
    XCTAssertTrue([m_resendArray count] == 1, @"not match, %lu", (unsigned long)[m_resendArray count]);
}


/*
 別チャンバーでのテスト実行
 */




@end
