//
//  EmitterTests.m
//  S2
//
//  Created by sassembla on 2013/09/23.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface EmitterTests : XCTestCase

@end

@implementation EmitterTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 接続されているclientに対して、特定のメッセージを投げる
 pullとかのメッセージを定型化する。
 
 pull, tick
 
 メッセンジャー持たないでも良さげだけど、フィルタ層として用意しておくとあとでメンテがラク。
 こいつ自身がフィルタになる。
 */

- (void) testSomething {
    XCTFail(@"not yet implemented");
}
@end
