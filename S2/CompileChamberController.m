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
    
    
    NSArray * static_chamber_states;
}

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:S2_COMPILECHAMBERCONT];
        [messenger connectParent:masterNameAndId];
        
        m_count = 0;
        m_chamberDict = [[NSMutableDictionary alloc]init];
        
        static_chamber_states = STATE_STR_ARRAY;
    }
    return self;
}

/**
 チャンバーを初期化する
 
 既存チャンバーを全て破棄、
 新規にチャンバーを一定数作成
 */
- (void) readyChamber:(int)count {
    NSAssert(0 < count, @"count is negative or 0.");
    
    for (NSString * currentChamberId in m_chamberDict) {
        [messenger call:S2_COMPILECHAMBER withExec:S2_COMPILECHAMBER_EXEC_PURGE,
         [messenger tag:@"id" val:currentChamberId],
         nil];
    }
    
    // 初期化
    m_count = count;
    m_chamberDict = [[NSMutableDictionary alloc]init];
    
    for (int i = 0; i < m_count; i++) {
        CompileChamber * chamber = [[CompileChamber alloc]initWithMasterNameAndId:[messenger myNameAndMID]];

        NSString * currentChamberId = [NSString stringWithFormat:@"%@", [chamber chamberId]];
        NSString * currentChamberState = [NSString stringWithFormat:@"%@", [chamber state]];
        
        NSMutableDictionary * chamberInfoDict = [[NSMutableDictionary alloc]init];
        [chamberInfoDict setValue:currentChamberState forKey:@"state"];
        
        [m_chamberDict setValue:chamberInfoDict forKey:currentChamberId];
    }
    
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 21:08:25" withLimitSec:100000 withComment:@"もし辞書型にする場合は、一度ここで開くとかする必要がある。"];
}


- (int) countOfSpinuppedChamber {
    int count = 0;
    for (NSString * chamberId in [m_chamberDict keyEnumerator]) {
        NSDictionary * chamberInfoDict = m_chamberDict[chamberId];
        NSAssert(chamberInfoDict[@"state"], @"state required");
        if ([chamberInfoDict[@"state"] isEqualToString:static_chamber_states[STATE_SPINUPPED]]) count++;
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
            // インプットがあったので、プール上のコードを編集、編集完了と同時に暇なchamberへとGoを出す。
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 22:30:24" withLimitSec:10000 withComment:@"プールからの現在のデータ取得"];
            
            NSDictionary * poolInfoDict = [[NSDictionary alloc]initWithObjectsAndKeys:@"a", @"b", nil];
            
            NSString * compileBasePath = poolInfoDict[@"compileBasePath"];
            NSDictionary * idsAndContents = poolInfoDict[@"idsAndContents"];
            
            if (!compileBasePath) {
                [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 22:32:43" withLimitSec:10000 withComment:@"プールからの条件未達成時の挙動"];
                break;
            }
            if (!idsAndContents) {
                [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 22:25:54" withLimitSec:10000 withComment:@"プールからの条件未達成時の挙動2"];
                break;
            }
            
            [self igniteIdleChamber:compileBasePath withContents:idsAndContents];
            
            break;
        }
    }
    
    // チャンバーからのメッセージ
    switch ([messenger execFrom:S2_COMPILECHAMBER viaNotification:notif]) {
            
            
        case S2_COMPILECHAMBER_EXEC_SPINUPPED:{
            NSAssert(dict[@"id"], @"id required");
            [self changeChamberStatus:dict[@"id"] to:static_chamber_states[STATE_SPINUPPED]];
            break;
        }
        
            
        case S2_COMPILECHAMBER_EXEC_COMPILED:{
            NSAssert(dict[@"id"], @"id required");
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 19:37:31" withLimitSec:10000 withComment:@"スピンアップを行う"];
            break;
        }
        case S2_COMPILECHAMBER_EXEC_ABORTED:{
            NSAssert(dict[@"id"], @"id required");
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 19:37:31" withLimitSec:10000 withComment:@"スピンアップを行う2"];
            break;
        }
            
        case S2_COMPILECHAMBER_EXEC_TICK:{
            
            break;
        }
    }
    
}


- (void) changeChamberStatus:(NSString * )chamberId to:(NSString * )state {
    NSDictionary * currentChamberInfoDict =  m_chamberDict[chamberId];
    
    NSMutableDictionary * updatedChamberInfoDict = [[NSMutableDictionary alloc]initWithDictionary:currentChamberInfoDict];
    updatedChamberInfoDict[@"state"] = state;
    
    [m_chamberDict setValue:updatedChamberInfoDict forKey:chamberId];
}

- (NSString * ) igniteIdleChamber:(NSString * )compileBasePath withContents:(NSDictionary * )idsAndContents {
    NSString * ignitedChamberId = nil;
    
    for (NSString * chamberId in [m_chamberDict keyEnumerator]) {
        NSDictionary * chamberInfoDict = m_chamberDict[chamberId];

        if ([chamberInfoDict[@"state"] isEqualToString:static_chamber_states[STATE_SPINUPPED]]) {
            
            ignitedChamberId = [[NSString alloc]initWithFormat:@"%@", chamberId];
            
            [messenger call:S2_COMPILECHAMBER withExec:S2_COMPILECHAMBER_EXEC_IGNITE,
             [messenger tag:@"id" val:chamberId],
             [messenger tag:@"compileBasePath" val:compileBasePath],
             [messenger tag:@"idsAndContents" val:idsAndContents],
             nil];
            break;
        }
    }
    
    return ignitedChamberId;
}


- (void) close {
    [messenger closeConnection];
}

@end
