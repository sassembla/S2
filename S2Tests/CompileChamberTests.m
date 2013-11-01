//
//  CompileChamberTests.m
//  S2
//
//  Created by sassembla on 2013/10/07.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KSMessenger.h"

#import "CompileChamber.h"

#define TEST_MASTER (@"TEST_MASTER")

#import "S2TestSupportDefines.h"

#import "CompileSettingController.h"


#import "TimeMine.h"

@interface CompileChamberTests : XCTestCase

@end

@implementation CompileChamberTests {
    KSMessenger * messenger;
    KSMessenger * settingDummyMessenger;
    
    CompileChamber * cChamber;
    
    NSMutableDictionary * m_chamberResponseDict;
    NSArray * m_stateArray;
    int m_repeatCount;
    
    NSArray * execArray;
}

- (void) setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    settingDummyMessenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(dummySettingReceiver:) withName:S2_COMPILERSETTINGCONTROLLER];
    
    cChamber = [[CompileChamber alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
    
    m_chamberResponseDict = [[NSMutableDictionary alloc]init];
    m_repeatCount = 0;
    
    execArray = @[
                  @"S2_COMPILECHAMBER_EXEC_SPINUP",
                  @"S2_COMPILECHAMBER_EXEC_SPINUP_WITH_ASYNC",
                  @"S2_COMPILECHAMBER_EXEC_SPINUPPED",
                  
                  @"S2_COMPILECHAMBER_EXEC_IGNITE",
                  @"S2_COMPILECHAMBER_EXEC_IGNITED",
                  
                  @"S2_COMPILECHAMBER_EXEC_GETTICK",
                  
                  @"S2_COMPILECHAMBER_EXEC_COMPILE",
                  @"S2_COMPILECHAMBER_EXEC_COMPILED",
                  
                  @"S2_COMPILECHAMBER_EXEC_ABORT",
                  @"S2_COMPILECHAMBER_EXEC_ABORTED",
                  
                  @"S2_COMPILECHAMBER_EXEC_TICK",
                  
                  @"S2_COMPILECHAMBER_EXEC_PURGE",
                  ];
    XCTAssertTrue([execArray count] == NUM_OF_S2_COMPILECHAMBER_EXEC, @"not match, %lu", (unsigned long)[execArray count]);
}

- (void) tearDown
{
    [m_chamberResponseDict removeAllObjects];
    
    [cChamber close];
    
    [settingDummyMessenger closeConnection];
    
    [messenger closeConnection];
    [super tearDown];
}


- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:S2_COMPILECHAMBER viaNotification:notif]) {
        case S2_COMPILECHAMBER_EXEC_IGNITED:{
            NSLog(@"ignited, %@", dict[@"id"]);
            
            [self update:dict[@"id"] to:S2_COMPILECHAMBER_EXEC_IGNITED];
            break;
        }
        case S2_COMPILECHAMBER_EXEC_ABORTED:{
            NSLog(@"aborted, %@", dict[@"id"]);
            [self update:dict[@"id"] to:S2_COMPILECHAMBER_EXEC_ABORTED];
            break;
        }
        case S2_COMPILECHAMBER_EXEC_TICK:{
            NSLog(@"tick, %@", dict[@"id"]);
            NSLog(@"message is %@", dict[@"message"]);
            [self update:dict[@"id"] to:S2_COMPILECHAMBER_EXEC_TICK];
            break;
        }
            
        case S2_COMPILECHAMBER_EXEC_COMPILED:{
            NSLog(@"compiled, %@", dict[@"id"]);
            [self update:dict[@"id"] to:S2_COMPILECHAMBER_EXEC_COMPILED];
            break;
        }
        default:
            break;
    }
}

- (void) dummySettingReceiver:(NSNotification * )notif {}




// util
- (void) update:(NSString * )chamberId to:(int)index {
    NSMutableArray * array = [m_chamberResponseDict valueForKey:chamberId];
    if (array) {} else array = [[NSMutableArray alloc]init];
    
    NSAssert(index < [execArray count], @"over, %d", index);
    
    [array addObject:execArray[index]];
    [m_chamberResponseDict setObject:array forKey:chamberId];
}

- (NSString * )targetState:(int)index {
    NSArray * targetStates = STATE_STR_ARRAY;
    return targetStates[index];
}

- (bool) countupThenFail {
    m_repeatCount++;
    if (TEST_REPEAT_COUNT_2 < m_repeatCount) {
        return true;
    }
    return false;
}

- (bool) countupLongThenFail {
    m_repeatCount++;
    if (TEST_REPEAT_COUNT_4 < m_repeatCount) {
        return true;
    }
    return false;
}

- (NSString * ) readSource:(NSString * )filePath {
    NSFileHandle * readHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    
    if (readHandle) {
        NSData * data = [readHandle readDataToEndOfFile];
        return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

/**
 ファイル作成(メモリ上のものを使う場合は不要)
 */
- (void) generateFiles:(NSDictionary * )pathAndSources to:(NSString * )generateTargetPath {
    
    NSError * error;
    NSFileManager * fMan = [[NSFileManager alloc]init];
    [fMan createDirectoryAtPath:generateTargetPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    //ファイル出力
    for (NSString * path in [pathAndSources allKeys]) {
        NSString * targetPath;
        
        //フォルダ生成
        targetPath = [NSString stringWithFormat:@"%@%@", generateTargetPath, path];
        [fMan createDirectoryAtPath:[targetPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        
        //ファイル生成
        bool result = [fMan createFileAtPath:targetPath contents:[pathAndSources[path] dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        
        if (result) {
            [TimeMine setTimeMineLocalizedFormat:@"2013/11/30 19:56:30" withLimitSec:100000 withComment:@"f generated!"];
        } else {
            [TimeMine setTimeMineLocalizedFormat:@"2013/11/30 19:56:34" withLimitSec:100000 withComment:@"f fail to generate"];
        }
        
        NSFileHandle * writeHandle = [NSFileHandle fileHandleForUpdatingAtPath:targetPath];
        [writeHandle writeData:[pathAndSources[path] dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void) deleteFiles:(NSString * )deleteTargetPath {
    NSError * error;
    NSFileManager * fMan = [[NSFileManager alloc]init];
    [fMan removeItemAtPath:deleteTargetPath error:&error];
}




/**
 起動時にすでにスピンアップ中の筈
 */
- (void) testGetStatusDefaultIsSpinupping {
    XCTAssertTrue([cChamber state] == [self targetState:STATE_SPINUPPING], @"not match, %@", [cChamber state]);
}

/**
 開始命令が出たら、要素と一緒に現在のプールからモノを引っ張ってきてcompileに入る。
 */
- (void) testIgniteThenStart {
    [cChamber ignite:TEST_COMPILEBASEPATH];

    XCTAssertTrue([cChamber state] == [self targetState:STATE_COMPILING], @"not match, %@", [cChamber state]);
}

- (void) testIgniteAndAbortThenAbortedThenSpinupping {
    [cChamber ignite:TEST_COMPILEBASEPATH];
    [cChamber abort];
    
    XCTAssertTrue([cChamber state] == [self targetState:STATE_ABORTED], @"not match, %@", [cChamber state]);
}

- (void) testGenAndDel {
    [self deleteFiles:TEST_TEMPPROJECT_OUTPUT_PATH];
    NSDictionary * codes = @{TEST_SCALA_1:[self readSource:TEST_SCALA_1]};
    [self generateFiles:codes to:TEST_TEMPPROJECT_OUTPUT_PATH];
    
    [self deleteFiles:TEST_TEMPPROJECT_OUTPUT_PATH];
}

/**
 十分なコンテンツを渡して、コンパイル成功
 */
- (void) testIgniteAndAbortThenCompiledPerfectly {
    [self deleteFiles:TEST_TEMPPROJECT_OUTPUT_PATH];
    
    NSDictionary * codes = @{TEST_SCALA_1:[self readSource:TEST_SCALA_1],
                             TEST_SCALA_2:[self readSource:TEST_SCALA_2],
                             TEST_COMPILEBASEPATH:[self readSource:TEST_COMPILEBASEPATH]};
    
    [self generateFiles:codes to:TEST_TEMPPROJECT_OUTPUT_PATH];
    
    NSString * currentTargetPath = [[NSString alloc]initWithFormat:@"%@%@", TEST_TEMPPROJECT_OUTPUT_PATH, [TEST_COMPILEBASEPATH substringFromIndex:2]];
    
    [cChamber ignite:currentTargetPath];
    
    while (![m_chamberResponseDict[[cChamber chamberId]] containsObject:execArray[S2_COMPILECHAMBER_EXEC_COMPILED]]) {
        if ([self countupLongThenFail]) {
            XCTFail(@"too late");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    [self deleteFiles:TEST_TEMPPROJECT_OUTPUT_PATH];
    
    XCTAssertTrue([cChamber state] == [self targetState:STATE_COMPILED], @"not match, %@", [cChamber state]);
}

/**
 不十分なコンテンツを渡して、コンパイル失敗で終了する。
 */
- (void) testIgniteAndAbortThenCompileFailure {
    [self deleteFiles:TEST_TEMPPROJECT_OUTPUT_PATH];
    
    NSDictionary * codes = @{TEST_SCALA_1:[self readSource:TEST_SCALA_1],
                             TEST_COMPILEBASEPATH:[self readSource:TEST_COMPILEBASEPATH]};
    
    [self generateFiles:codes to:TEST_TEMPPROJECT_OUTPUT_PATH];
    
    NSString * currentTargetPath = [[NSString alloc]initWithFormat:@"%@%@", TEST_TEMPPROJECT_OUTPUT_PATH, [TEST_COMPILEBASEPATH substringFromIndex:2]];
    
    [cChamber ignite:currentTargetPath];
    
    while (![m_chamberResponseDict[[cChamber chamberId]] containsObject:execArray[S2_COMPILECHAMBER_EXEC_COMPILED]]) {
        if ([self countupLongThenFail]) {
            XCTFail(@"too late");
            break;
        }
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    [self deleteFiles:TEST_TEMPPROJECT_OUTPUT_PATH];
    
    XCTAssertTrue([cChamber state] == [self targetState:STATE_COMPILED], @"not match, %@", [cChamber state]);
}

/**
 十分なコンテンツを渡して、コンパイルをabortする
 */
- (void) testIgniteAndAbortThenCompileAbort {
    [self deleteFiles:TEST_TEMPPROJECT_OUTPUT_PATH];
    
    NSDictionary * codes = @{TEST_SCALA_1:[self readSource:TEST_SCALA_1],
                             TEST_SCALA_2:[self readSource:TEST_SCALA_2],
                             TEST_COMPILEBASEPATH:[self readSource:TEST_COMPILEBASEPATH]};
    
    [self generateFiles:codes to:TEST_TEMPPROJECT_OUTPUT_PATH];
    
    NSString * currentTargetPath = [[NSString alloc]initWithFormat:@"%@%@", TEST_TEMPPROJECT_OUTPUT_PATH, [TEST_COMPILEBASEPATH substringFromIndex:2]];
    
    [cChamber ignite:currentTargetPath];
    
    [cChamber abort];
    
    [self deleteFiles:TEST_TEMPPROJECT_OUTPUT_PATH];
    
    XCTAssertTrue([cChamber state] == [self targetState:STATE_ABORTED], @"not match, %@", [cChamber state]);
}


//- (void) testAbortedChamberResponseContainsPrecompiling {
//    [CompileChamber abort];
//    
//    NSString * precompiling_result = [NSString stringWithFormat:@"", CompileChamber, STATE_PRECOMPILING];
//    XCTAssertTrue([m_chamberResponseDict :precompiling_result], @"not contained, %@", m_chamberResponseArray);
//}
//
//
//- (void) testRe_IgnitedChamberResponseContainsCompiling {
//    [CompileChamber abort];
//    [CompileChamber ignite];
//    
//    NSString * precompiling_result = [NSString stringWithFormat:@"", CompileChamber, STATE_COMPILING];
//    XCTAssertTrue([m_chamberResponseArray containsObject:precompiling_result], @"not contained, %@", m_chamberResponseArray);
//}





@end
