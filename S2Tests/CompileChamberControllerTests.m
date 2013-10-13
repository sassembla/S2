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


/**
 Chamberのコントロールを行う
 
 
 */
@interface CompileChamberControllerTests : XCTestCase

@end




@implementation CompileChamberControllerTests  {
    KSMessenger * messenger;
    CompileChamberController * cChambCont;
    
    NSMutableArray * m_chamberResponseArray;
}

- (void) setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    cChambCont = [[CompileChamberController alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
    
    m_chamberResponseArray = [[NSMutableArray alloc] init];
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
            // chamberにidとか振るよねきっと。
            //            [m_chamberResponseArray addObject:<#(id)#>]
            XCTFail(@"not yet implemented");
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

- (void) testResetChamberThenSpinupped {
    [cChambCont readyChamber:TEST_CHAMBER_NUM_2];
    
    XCTAssertTrue([cChambCont countOfSpinuppedChamber] == TEST_CHAMBER_NUM_2, @"not match, %d", [cChambCont countOfSpinuppedChamber]);
}

- (void) testSourceInputted {
    [cChambCont readyChamber:TEST_CHAMBER_NUM_2];
    
    // データの受け口へとコードを送る。
    // ファイル名と内容
    NSString * fileName = TEST_LISTED_1;
    NSString * contents = @"test source code content";
    
    
    [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_INPUT,
     [messenger tag:@"id" val:fileName],
     [messenger tag:@"contents" val:contents],
     nil];
    
    
    // 装填完了、ビルド開始、までを発行すればいいか。
    XCTAssertTrue([m_chamberResponseArray count] == 1, @"not match, %lu", (unsigned long)[m_chamberResponseArray count]);
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
