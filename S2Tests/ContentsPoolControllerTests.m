//
//  ContentsPoolControllerTests.m
//  S2
//
//  Created by sassembla on 2013/10/13.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KSMessenger.h"

#import "ContentsPoolController.h"

#define TEST_MASTER (@"TEST_MASTER")

@interface ContentsPoolControllerTests : XCTestCase

@end

@implementation ContentsPoolControllerTests {
    KSMessenger * messenger;
    ContentsPoolController * cPoolCont;
}

- (void)setUp
{
    [super setUp];
    messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    cPoolCont = [[ContentsPoolController alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
}

- (void)tearDown
{
    [cPoolCont close];
    [messenger closeConnection];
    [super tearDown];
}

- (void) receiver:(NSNotification * )notif {
    
}

/**
 接続に来る際、データをスキーマに併せて解析して、ビルド可能なパターンを返す。
 そろっていなくてもspinup時に呼ばれるのを考慮する。
 今はspinuppedでしか呼ばれないけど。gradle側で待つ以外の選択肢があるかな。

 その選択肢をどんな言語でもいいから作れれば、並列メモリ共有が実現できる。
 まあ、いまは良いや。この先があれば。
 
 zincの中身を開けてそこが共有可能であれば、面白いと思う。
 */


- (void) testSomething {
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
