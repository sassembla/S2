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

@interface CompileChamberTests : XCTestCase

@end

@implementation CompileChamberTests {
    KSMessenger * messenger;
    CompileChamber * cChamber;
    
    NSMutableDictionary * m_chamberResponseDict;
}

- (void) setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    cChamber = [[CompileChamber alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
    
    m_chamberResponseDict = [[NSMutableDictionary alloc]init];
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


- (void) testGetStatusDefaultIsSpinupped {
    XCTAssertTrue([cChamber state] == [self targetState:STATE_SPINUPPED], @"not match, %@", [cChamber state]);
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
