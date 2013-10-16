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

#import "ContentsPoolController.h"

#import "TimeMine.h"

@implementation CompileChamberController {
    KSMessenger * messenger;

    NSMutableDictionary * m_chamberDict;
    
    int m_count;
    
    NSArray * static_chamber_states;
    
    ContentsPoolController * contentsPoolCont;
}

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:S2_COMPILECHAMBERCONT];
        [messenger connectParent:masterNameAndId];
        
        m_count = 0;
        m_chamberDict = [[NSMutableDictionary alloc]init];
        
        static_chamber_states = STATE_STR_ARRAY;
        
        
        contentsPoolCont = [[ContentsPoolController alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
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
            
            NSDictionary * poolInfoDict = [messenger call:S2_CONTENTSPOOLCONT withExec:S2_CONTENTSPOOLCONT_EXEC_DRAIN, nil];
            
            
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/15 13:23:25" withLimitSec:100000 withComment:@"ここでチェックしたほうがいいのかな。。ケースを洗い出そう。"];
            
            NSString * compileBasePath = poolInfoDict[@"compileBasePath"];
            NSDictionary * idsAndContents = poolInfoDict[@"idsAndContents"];
            
            NSString * currentIgnitedChamberId = [self igniteIdleChamber:compileBasePath withContents:idsAndContents];
            [messenger callParent:S2_COMPILECHAMBERCONT_EXEC_CHAMBER_IGNITED,
             [messenger tag:@"ignitedChamberId" val:currentIgnitedChamberId],
             nil];
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
    
    for (NSString * chamberId in m_chamberDict) {
        [messenger call:S2_COMPILECHAMBER withExec:S2_COMPILECHAMBER_EXEC_PURGE,
         [messenger tag:@"id" val:chamberId],
         nil];
    }
    
    [messenger call:S2_CONTENTSPOOLCONT withExec:S2_CONTENTSPOOLCONT_EXEC_PURGE, nil];
    
    [messenger closeConnection];
}

@end
