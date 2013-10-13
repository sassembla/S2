//
//  CompileChamberController.m
//  S2
//
//  Created by sassembla on 2013/10/13.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "CompileChamberController.h"
#import "KSMessenger.h"

#import "TimeMine.h"

@implementation CompileChamberController {
    KSMessenger * messenger;

    int m_count;
}

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:S2_COMPILECHAMBERCONT];
        [messenger connectParent:masterNameAndId];
        
        m_count = 0;
    }
    return self;
}

- (void) readyChamber:(int)count {
    NSAssert(0 < count, @"count is negative or 0.");
    m_count = count;
    
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 16:00:45" withLimitSec:10000 withComment:@"チャンバーのリセットと初期化。どんな情報を持てば良いかは、チャンバー側を作ってから考える。"];
}


- (int) countOfReadyChamber {
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 16:03:17" withLimitSec:1000 withComment:@"コンパイル開始できる状態のチャンバー数を返す。集計が必要。"];
    return 0;
}




- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
        case S2_COMPILECHAMBERCONT_EXEC_INITIALIZE:{
            NSAssert(dict[@"chamberCount"], @"chamberCount required");
            [self readyChamber:[dict[@"chamberCount"] intValue]];
            break;
        }
        case S2_COMPILECHAMBERCONT_EXEC_INPUT:{
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 15:51:08" withLimitSec:10000 withComment:@"S2_COMPILECHAMBERCONT_EXEC_INPUT の受け、待ち受け状態のチャンバーへの投入開始"];
            break;
        }
    }
    
}



- (void) close {
    [messenger closeConnection];
}

@end
