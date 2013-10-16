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

#import "TimeMine.h"

@interface CompileChamberTests : XCTestCase

@end

@implementation CompileChamberTests {
    KSMessenger * messenger;
    CompileChamber * cChamber;
    
    NSMutableDictionary * m_chamberResponseDict;
    
    int m_repeatCount;
}

- (void) setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    cChamber = [[CompileChamber alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
    
    m_chamberResponseDict = [[NSMutableDictionary alloc]init];
    
    m_repeatCount = 0;
}

- (void) tearDown
{
    [m_chamberResponseDict removeAllObjects];
    
    [cChamber close];
    [messenger closeConnection];
    [super tearDown];
}


- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:S2_COMPILECHAMBER viaNotification:notif]) {
        case S2_COMPILECHAMBER_EXEC_IGNITED:{
            break;
        }
        case S2_COMPILECHAMBER_EXEC_ABORTED:{
            break;
        }
            
        default:
            break;
    }
}


// util
- (NSString * )targetState:(int)index {
    NSArray * targetStates = STATE_STR_ARRAY;
    return targetStates[index];
}

- (bool) countupThenFail {
    m_repeatCount++;
    if (TEST_REPEAT_COUNT_2 < m_repeatCount) {
        XCTFail(@"too long wait");
        return true;
    }
    return false;
}

- (NSMutableDictionary * ) readSource:(NSString * )filePath withBaseDict:(NSDictionary * )base {
    NSFileHandle * readHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    
    if (readHandle) {
        NSData * data = [readHandle readDataToEndOfFile];
        NSString * fileContentsStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        
        NSMutableDictionary * newBaseDict = [[NSMutableDictionary alloc]initWithDictionary:base];
        [newBaseDict setValue:fileContentsStr forKey:filePath];
        
        return newBaseDict;
    }
    
    return nil;
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
    NSDictionary * testDict = @{@"a":@"b"};
    
    [cChamber ignite:TEST_COMPILEBASEPATH withCodes:testDict];

    XCTAssertTrue([cChamber state] == [self targetState:STATE_COMPILING], @"not match, %@", [cChamber state]);
}

- (void) testIgniteAndAbortThenAborted {
    
    NSDictionary * testDict = @{@"a":@"b"};
    [cChamber ignite:TEST_COMPILEBASEPATH withCodes:testDict];
    [cChamber abort];
    
    XCTAssertTrue([cChamber state] == [self targetState:STATE_ABORTED], @"not match, %@", [cChamber state]);
}

/**
 十分なコンテンツを渡して、コンパイル成功
 */
- (void) testIgniteAndAbortThenCompiledPerfectly {
    
    NSString * contents1 = @"";
    NSString * contents2 = @"";
    
    NSDictionary * testDict = @{TEST_SCALA_1:contents1,
                                TEST_SCALA_2:contents2};
    
    [cChamber ignite:TEST_COMPILEBASEPATH withCodes:testDict];
    
    while ([cChamber isCompiling]) {
        if ([self countupThenFail]) break;
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    XCTAssertTrue([cChamber state] == [self targetState:STATE_COMPILED], @"not match, %@", [cChamber state]);
}

/**
 不十分なコンテンツを渡して、コンパイル成功しない
 */
- (void) testIgniteAndAbortThenCompileFailure {
    
    NSString * contents = @"";
    NSDictionary * testDict = @{TEST_SCALA_1:contents};
    
    [cChamber ignite:TEST_COMPILEBASEPATH withCodes:testDict];
    
    while ([cChamber isCompiling]) {
        if ([self countupThenFail]) {
            XCTFail(@"too late");
            break;
        }
        [[NSRunLoop mainRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    
    XCTAssertTrue([cChamber state] == [self targetState:STATE_COMPILE_FAILED], @"not match, %@", [cChamber state]);
}

/**
 十分なコンテンツを渡して、abort
 */
- (void) testIgniteAndAbortThenCompileAbort {
    
    NSMutableDictionary * testDict_1 = [self readSource:TEST_SCALA_1 withBaseDict:nil];
    NSMutableDictionary * withTestDict_2 = [self readSource:TEST_SCALA_2 withBaseDict:testDict_1];
    NSMutableDictionary * withCompileBasePathContents = [self readSource:TEST_COMPILEBASEPATH withBaseDict:withTestDict_2];
    
    [cChamber ignite:TEST_COMPILEBASEPATH withCodes:withCompileBasePathContents];
    
    [cChamber abort];
    
    XCTAssertTrue([cChamber state] == [self targetState:STATE_COMPILE_ABORTED], @"not match, %@", [cChamber state]);
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
