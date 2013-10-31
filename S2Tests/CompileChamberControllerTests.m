//
//  CompileChamberControllerTests.m
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


#define TEST_ID             (@"TEST_ID")
#define TEST_ID_2           (@"TEST_ID_2")

#define TEST_MESSAGE        (@"TEST_MESSAGE")
#define TEST_MESSAGE_2      (@"TEST_MESSAGE_2")


#import "S2TestSupportDefines.h"

#import "CompileSettingController.h"


/**
 Chamberのコントロールを行う
 
 
 */
@interface CompileChamberControllerTests : XCTestCase

@end




@implementation CompileChamberControllerTests  {
    KSMessenger * messenger;
    KSMessenger * dummySettingMessenger;
    
    CompileChamberController * cChambCont;
    
    NSMutableArray * m_chamberIgnitedArray;
    NSMutableArray * m_chamberCompiledArray;
    NSMutableArray * m_chamberAbortedArray;
    
    int m_repeatCount;
    
    NSMutableArray * m_resendedMessagesArray;
}

- (void) setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    dummySettingMessenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(dummySettingReceiver:) withName:S2_COMPILERSETTINGCONTROLLER];
    
    cChambCont = [[CompileChamberController alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
    
    m_chamberIgnitedArray = [[NSMutableArray alloc] init];
    m_chamberCompiledArray = [[NSMutableArray alloc] init];
    m_chamberAbortedArray = [[NSMutableArray alloc] init];
    
    m_repeatCount = 0;
    
    m_resendedMessagesArray = [[NSMutableArray alloc]init];
}

- (void) tearDown
{
    [m_chamberIgnitedArray removeAllObjects];
    [m_chamberCompiledArray removeAllObjects];
    [m_chamberAbortedArray removeAllObjects];
    
    [m_resendedMessagesArray removeAllObjects];
    
    [cChambCont close];
    
    [dummySettingMessenger closeConnection];
    [messenger closeConnection];
    [super tearDown];
}


- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    
    switch ([messenger execFrom:S2_COMPILECHAMBERCONT viaNotification:notif]) {
        case S2_COMPILECHAMBERCONT_EXEC_CHAMBER_IGNITED:{
            NSAssert(dict[@"ignitedChamberId"], @"ignitedChamberId required");
            [m_chamberIgnitedArray addObject:dict[@"ignitedChamberId"]];
            break;
        }
            
        case S2_COMPILECHAMBERCONT_EXEC_CHAMBER_COMPILED:{
            NSAssert(dict[@"compiledChamberId"], @"compiledChamberId required");
            [m_chamberCompiledArray addObject:dict[@"compiledChamberId"]];
            
            break;
        }
            
        case S2_COMPILECHAMBERCONT_EXEC_CHAMBER_ABORTED:{
            // abortするのが最前な条件が、そのチャンバーをリセットする以外に存在しないので、この戦略はテスト以外でとられることがない。
            
            NSAssert(dict[@"abortedChamberId"], @"abortedChamberId required");
            [m_chamberAbortedArray addObject:dict[@"abortedChamberId"]];
            break;
        }
        case S2_COMPILECHAMBERCONT_EXEC_RESEND:{
            NSAssert(dict[@"priorityDict"], @"priorityDict required");
            [m_resendedMessagesArray addObject:dict[@"priorityDict"]];
            break;
        }
            
        default:
            
            break;
    }
}

- (void) dummySettingReceiver:(NSNotification * )notif {}


// util
- (bool) countupThenFail {
    m_repeatCount++;
    if (TEST_REPEAT_COUNT < m_repeatCount) {
        return true;
    }
    return false;
}

- (bool) countupLongThenFail {
    m_repeatCount++;
    if (TEST_REPEAT_COUNT_3 < m_repeatCount) {
        return true;
    }
    return false;
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



/**
 スピンアップ中のchamberのid集を返す
 */
- (void) testGetSpinuppingChambers {
    [cChambCont readyChamber:TEST_CHAMBER_NUM_2];
    
    NSArray * chamberIds = [cChambCont spinuppingChambers];
    
    XCTAssertTrue([chamberIds count] == TEST_CHAMBER_NUM_2, @"not match, %lu", (unsigned long)[chamberIds count]);
    [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
}


- (void) testResetChamberThenSpinupped {
    [cChambCont readyChamber:TEST_CHAMBER_NUM_2];
    
    // wait for spinupped
    while ([[cChambCont spinuppedChambers] count] < TEST_CHAMBER_NUM_2) {
        if ([self countupThenFail]) return;
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    XCTAssertTrue([[cChambCont spinuppedChambers]count] == TEST_CHAMBER_NUM_2, @"not match, %lu", (unsigned long)[[cChambCont spinuppedChambers] count]);
}


- (void) testSourceInputted {
    [cChambCont readyChamber:TEST_CHAMBER_NUM_2];
    
    
    // wait for spinup
    while ([[cChambCont spinuppedChambers] count] < TEST_CHAMBER_NUM_2) {
        if ([self countupThenFail]) return;
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // データの受け口へとTEST_COMPILEBASEPATHを送る。
    // コンパイル可能なファイル名と内容
    [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_INPUT,
     [messenger tag:@"path" val:TEST_COMPILEBASEPATH],
     [messenger tag:@"source" val:[self readSource:TEST_COMPILEBASEPATH]],
     nil];
    
    // 装填完了、m_chamberIgnitedArrayにignitedChamberIdが　ひとつ　入る
    XCTAssertTrue([m_chamberIgnitedArray count] == 1, @"not match, %lu", (unsigned long)[m_chamberIgnitedArray count]);
}


- (void) testChambersStatus_1of2_WorkingThenFinishCompiling {
    [cChambCont readyChamber:TEST_CHAMBER_NUM_2];
    
    // wait for spinup
    while ([[cChambCont spinuppedChambers] count] < TEST_CHAMBER_NUM_2) {
        if ([self countupThenFail]) {
            XCTFail(@"too late");
            break;
        }
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    // データの受け口へとTEST_COMPILEBASEPATHを送る。
    [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_INPUT,
     [messenger tag:@"path" val:TEST_COMPILEBASEPATH],
     [messenger tag:@"source" val:[self readSource:TEST_COMPILEBASEPATH]],
     nil];
    

    // コンパイル完了まで待つ
    while ([m_chamberCompiledArray count] < 1) {
        if ([self countupLongThenFail]) {
            XCTFail(@"too late");
            break;
        }
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    XCTAssertTrue([m_chamberCompiledArray count] == 1, @"not match, %lu", (unsigned long)[m_chamberCompiledArray count]);
}


/**
  チャンバーのフル稼働
 */
- (void) testChambersAllCompiling {
    [cChambCont readyChamber:TEST_CHAMBER_NUM_2];
    
    // wait for spinup
    while ([[cChambCont spinuppedChambers] count] < TEST_CHAMBER_NUM_2) {
        if ([self countupThenFail]) return;
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    // データの受け口へとTEST_COMPILEBASEPATHをチャンバー数分送付
    for (int i = 0; i < TEST_CHAMBER_NUM_2; i++) {
        [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_INPUT,
         [messenger tag:@"path" val:TEST_COMPILEBASEPATH],
         [messenger tag:@"source" val:[self readSource:TEST_COMPILEBASEPATH]],
         nil];
    }
    
    // この時点で全チャンバーがフル稼働している筈
    XCTAssertTrue([[cChambCont compilingChambers] count] == TEST_CHAMBER_NUM_2, @"not match, %lu", (unsigned long)[[cChambCont compilingChambers] count]);
    
    XCTAssertTrue([m_chamberIgnitedArray count] == TEST_CHAMBER_NUM_2, @"not match, %lu", (unsigned long)[m_chamberIgnitedArray count]);
}

/**
 チャンバーの数を上回る上書きが発生する状態の時
 
 abortしたところで、spinupのコストを賄えるとは思えないので、chamber不足でabortさせることは無い。
 */
- (void) testChamberAbortByOverrap {
    [cChambCont readyChamber:TEST_CHAMBER_NUM_2];
    
    // wait for spinup
    while ([[cChambCont spinuppedChambers] count] < TEST_CHAMBER_NUM_2) {
        if ([self countupThenFail]) return;
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    // データの受け口へとTEST_COMPILEBASEPATHをチャンバー数 + 1 分送付
    for (int i = 0; i < TEST_CHAMBER_NUM_2 + 1; i++) {
        [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_INPUT,
         [messenger tag:@"path" val:TEST_COMPILEBASEPATH],
         [messenger tag:@"source" val:[self readSource:TEST_COMPILEBASEPATH]],
         nil];
    }
    
    // この時点で全チャンバーがフル稼働
    XCTAssertTrue([[cChambCont compilingChambers] count] == TEST_CHAMBER_NUM_2, @"not match, %lu", (unsigned long)[[cChambCont compilingChambers] count]);
    
    // コンパイル開始サインはTEST_CHAMBER_NUM_2。
    XCTAssertTrue([m_chamberIgnitedArray count] == TEST_CHAMBER_NUM_2, @"not match, %lu", (unsigned long)[m_chamberIgnitedArray count]);
}


- (void) testResendContainsData {
    // 1つをバッファに追加
    [cChambCont bufferMessage:TEST_MESSAGE to:TEST_ID];
    
    // priorityを勝手に制御
    [cChambCont setChamberPriorityFirst:TEST_ID];
    
    // index 1から上のみを再送する
    [cChambCont resendFrom:0 length:1];
    
    // S2_COMPILECHAMBERCONT_EXEC_RESEND の件数が1つ
    XCTAssertTrue([m_resendedMessagesArray count] == 1, @"not match, %lu", (unsigned long)[m_resendedMessagesArray count]);
    
    
    NSDictionary * sample = m_resendedMessagesArray[0];
    XCTAssertNotNil(sample[@"0"], @"is nil, %@", sample);
    
    NSDictionary * sample2 = sample[@"0"];
    XCTAssertNotNil(sample2[TEST_ID], @"is nil, %@", sample2);
    
    NSArray * array = sample2[TEST_ID];
    XCTAssertTrue([array count] == 1, @"not match, %lu", (unsigned long)[array count]);
    
    XCTAssertTrue([array[0] isEqualToString:TEST_MESSAGE], @"not match, %@", array[0]);
}


- (void) testResendContainsDataWithPriorityChange {
    // 2つを別バッファに追加
    [cChambCont bufferMessage:TEST_MESSAGE to:TEST_ID];
    [cChambCont bufferMessage:TEST_MESSAGE_2 to:TEST_ID_2];
    
    // priorityを勝手に制御、
    [cChambCont setChamberPriorityFirst:TEST_ID];
    [cChambCont setChamberPriorityFirst:TEST_ID_2];// TEST_ID_2がtopに、TEST_IDは2ndに。
    
    // index 1から上のみを再送する
    [cChambCont resendFrom:1 length:1];
    
    // S2_COMPILECHAMBERCONT_EXEC_RESEND の件数が1つ
    XCTAssertTrue([m_resendedMessagesArray count] == 1, @"not match, %lu", (unsigned long)[m_resendedMessagesArray count]);
    
    
    NSDictionary * sample = m_resendedMessagesArray[0];
    XCTAssertNotNil(sample[@"1"], @"is nil, %@", sample);
    
    NSDictionary * sample2 = sample[@"1"];
    XCTAssertNotNil(sample2[TEST_ID], @"is nil, %@", sample2);
}


- (void) testResendContains2Data {
    // TEST_IDバッファに２つ,TEST_ID_2には何もなし
    [cChambCont bufferMessage:TEST_MESSAGE to:TEST_ID];
    [cChambCont bufferMessage:TEST_MESSAGE_2 to:TEST_ID];
    
    // priorityを勝手に制御
    [cChambCont setChamberPriorityFirst:TEST_ID];
    [cChambCont setChamberPriorityFirst:TEST_ID_2];// TEST_ID_2がtopに、TEST_IDは2ndに。
    
    // index 1から上のみを再送する
    [cChambCont resendFrom:1 length:1];
    
    // S2_COMPILECHAMBERCONT_EXEC_RESEND の件数が1つ
    XCTAssertTrue([m_resendedMessagesArray count] == 1, @"not match, %lu", (unsigned long)[m_resendedMessagesArray count]);
    
    
    NSDictionary * sample = m_resendedMessagesArray[0];
    XCTAssertNotNil(sample[@"1"], @"is nil, %@", sample);
    
    NSDictionary * sample2 = sample[@"1"];
    XCTAssertNotNil(sample2[TEST_ID], @"is nil, %@", sample2);
}

- (void) testResendContains2DataWithNotEmpty2 {
    // TEST_IDバッファに２つ,TEST_ID_2には何もなし
    [cChambCont bufferMessage:TEST_MESSAGE to:TEST_ID];
    [cChambCont bufferMessage:TEST_MESSAGE_2 to:TEST_ID];
    
    [cChambCont bufferMessage:TEST_MESSAGE to:TEST_ID_2];
    
    // priorityを勝手に制御
    [cChambCont setChamberPriorityFirst:TEST_ID];
    [cChambCont setChamberPriorityFirst:TEST_ID_2];// TEST_ID_2がtopに、TEST_IDは2ndに。
    
    // index 1から上のみを再送する
    [cChambCont resendFrom:1 length:1];
    
    // S2_COMPILECHAMBERCONT_EXEC_RESEND の件数が1つ
    XCTAssertTrue([m_resendedMessagesArray count] == 1, @"not match, %lu", (unsigned long)[m_resendedMessagesArray count]);
    
    
    NSDictionary * sample = m_resendedMessagesArray[0];
    XCTAssertNotNil(sample[@"1"], @"is nil, %@", sample);
    
    NSDictionary * sample2 = sample[@"1"];
    XCTAssertNotNil(sample2[TEST_ID], @"is nil, %@", sample2);
}

@end
