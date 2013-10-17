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


#import "S2TestSupportDefines.h"
#import "TimeMine.h"


/**
 Chamberのコントロールを行う
 
 
 */
@interface CompileChamberControllerTests : XCTestCase

@end




@implementation CompileChamberControllerTests  {
    KSMessenger * messenger;
    CompileChamberController * cChambCont;
    
    NSMutableArray * m_chamberResponseArray;
    
    int m_repeatCount;
}

- (void) setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    cChambCont = [[CompileChamberController alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
    
    m_chamberResponseArray = [[NSMutableArray alloc] init];
    
    m_repeatCount = 0;
}

- (void) tearDown
{
    [m_chamberResponseArray removeAllObjects];
    
    
    [cChambCont close];
    [messenger closeConnection];
    [super tearDown];
}


- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    
    switch ([messenger execFrom:S2_COMPILECHAMBERCONT viaNotification:notif]) {
        case S2_COMPILECHAMBERCONT_EXEC_CHAMBER_IGNITED:{
            NSAssert(dict[@"ignitedChamberId"], @"ignitedChamberId required");
            [m_chamberResponseArray addObject:dict[@"ignitedChamberId"]];
            break;
        }
            
        case S2_COMPILECHAMBERCONT_EXEC_CHAMBER_ABORTED:{
            XCTFail(@"not yet implemented2");
            break;
        }
            
        default:
            break;
    }
}


// util
- (bool) countupThenFail {
    m_repeatCount++;
    if (TEST_REPEAT_COUNT < m_repeatCount) {
        XCTFail(@"too long wait");
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
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    XCTAssertTrue([[cChambCont spinuppedChambers]count] == TEST_CHAMBER_NUM_2, @"not match, %lu", (unsigned long)[[cChambCont spinuppedChambers] count]);
}


- (void) testSourceInputted {
    [cChambCont readyChamber:TEST_CHAMBER_NUM_2];
    
    
    // wait for spinup
    while ([[cChambCont spinuppedChambers] count] < TEST_CHAMBER_NUM_2) {
        if ([self countupThenFail]) return;
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    // データの受け口へとコードを送る。
    // コンパイル可能なファイル名と内容
    [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_INPUT,
     [messenger tag:@"path" val:TEST_COMPILEBASEPATH],
     [messenger tag:@"source" val:[self readSource:TEST_COMPILEBASEPATH]],
     nil];
    
    // 装填完了、m_chamberResponseArrayにignitedChamberIdが　ひとつ　入る
    XCTAssertTrue([m_chamberResponseArray count] == 1, @"not match, %lu", (unsigned long)[m_chamberResponseArray count]);
}


- (void) testChambersStatus_1of2_Working {
    [cChambCont readyChamber:TEST_CHAMBER_NUM_2];
    
    
    // wait for spinup
    while ([[cChambCont spinuppedChambers] count] < TEST_CHAMBER_NUM_2) {
        if ([self countupThenFail]) return;
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    // データの受け口へとコードを送る。
    // コンパイル可能なファイル名と内容になる、はず。プールからわたってくるリソースを変更しよう。
    
    [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_INPUT,
     [messenger tag:@"path" val:TEST_COMPILEBASEPATH],
     [messenger tag:@"source" val:[self readSource:TEST_COMPILEBASEPATH]],
     nil];
    
    // コンパイル完了まで待つ
    XCTFail(@"fail!!　プールでジェネレートして、chamberではパスだけを引っ張る。パスさえあれば、動かせる　はず　だし。");

}

/*
 すべて空いている状態からの半投入
 すべて空いている状態からの全投入
 
 空いているチャンバーへと段階的に投入
 空いているチャンバーへと段階的に全投入
 
 チャンバーの強制キャンセル
 チャンバーの上書き(強制キャンセル+新規ブート
 チャンバーのタイムアウト
 
 */

@end
