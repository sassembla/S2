//
//  CompileChamberController.m
//  S2
//
//  Created by sassembla on 2013/10/13.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "CompileChamberController.h"
#import "KSMessenger.h"

#import "CompileChamber.h"

#import "TimeMine.h"

@implementation CompileChamberController {
    KSMessenger * messenger;

    NSMutableDictionary * m_chamberDict;
    
    int m_count;
}

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:S2_COMPILECHAMBERCONT];
        [messenger connectParent:masterNameAndId];
        
        m_count = 0;
        m_chamberDict = [[NSMutableDictionary alloc]init];
    }
    return self;
}

/**
 チャンバーを初期化する
 
 既存チャンバーは全て破棄、
 新規にチャンバーを一定数作成
 */
- (void) readyChamber:(int)count {
    NSAssert(0 < count, @"count is negative or 0.");
    
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 18:06:58" withLimitSec:10000 withComment:@"既存チャンバーを破棄"];
    
    
    // 初期化
    m_count = count;
    m_chamberDict = [[NSMutableDictionary alloc]init];
    
    for (int i = 0; i < m_count; i++) {
        CompileChamber * chamber = [[CompileChamber alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
        NSString * chamberId = [chamber chamberId];
        
        NSMutableDictionary * chamberInfoDict = [[NSMutableDictionary alloc]init];
        [chamberInfoDict setValue:[chamber state] forKey:@"state"];
        
        [m_chamberDict setValue:chamberInfoDict forKey:chamberId];
    }
    
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 18:18:36" withLimitSec:10000 withComment:@"もし辞書型にする場合は、一度ここで開くとかする必要がある。"];
}


- (int) countOfSpinuppedChamber {
    NSArray * states = STATE_STR_ARRAY;
    
    int count = 0;
    for (NSDictionary * chamberDict in m_chamberDict) {
        if (chamberDict[@"state"] == states[STATE_SPINUPPED]) count++;
    }
    return count;
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
    
    switch ([messenger execFrom:S2_COMPILECHAMBER viaNotification:notif]) {
        case S2_COMPILECHAMBER_EXEC_SPAWNED:{
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 18:19:59" withLimitSec:10000 withComment:@"chamber初期化完了時の処理"];
            break;
        }
        case S2_COMPILECHAMBER_EXEC_SPINUPPED:{
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 18:28:54" withLimitSec:10000 withComment:@"スピンアップ完了なので、statusを更新する。"];
            break;
        }
    }
    
}



- (void) close {
    [messenger closeConnection];
}

@end
