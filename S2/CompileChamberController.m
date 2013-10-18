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
    NSMutableDictionary * m_messageDict;
    
    int m_count;
    
    NSArray * static_chamber_states;
    
    ContentsPoolController * contentsPoolCont;
    
    NSMutableArray * m_chamberPriority;
}

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:S2_COMPILECHAMBERCONT];
        [messenger connectParent:masterNameAndId];
        
        m_count = 0;
        m_chamberDict = [[NSMutableDictionary alloc]init];
        
        static_chamber_states = STATE_STR_ARRAY;
        
        contentsPoolCont = [[ContentsPoolController alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
        
        m_chamberPriority = [[NSMutableArray alloc]init];
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
    
    m_messageDict = [[NSMutableDictionary alloc]init];
}


- (NSArray * ) specificStateChambers:(NSString * )state {
    NSMutableArray * array = [[NSMutableArray alloc]init];
    for (NSString * chamberId in [m_chamberDict keyEnumerator]) {
        NSDictionary * chamberInfoDict = m_chamberDict[chamberId];
        NSAssert(chamberInfoDict[@"state"], @"state required");
        if ([chamberInfoDict[@"state"] isEqualToString:state]) {
            [array addObject:chamberId];
        }
    }
    return array;
}

- (NSArray * ) spinuppingChambers {
    return [self specificStateChambers:static_chamber_states[STATE_SPINUPPING]];
}

- (NSArray * ) spinuppedChambers {
    return [self specificStateChambers:static_chamber_states[STATE_SPINUPPED]];
}

- (NSArray * ) ignitingChambers {
    return [self specificStateChambers:static_chamber_states[STATE_COMPILING]];
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
            NSAssert(dict[@"path"], @"path required");
            NSAssert(dict[@"source"], @"source required");
            NSDictionary * poolInfoDict = [messenger call:S2_CONTENTSPOOLCONT withExec:S2_CONTENTSPOOLCONT_EXEC_DRAIN,
                                           [messenger tag:@"path" val:dict[@"path"]],
                                           [messenger tag:@"source" val:dict[@"source"]],
                                           nil];
            
            // ignition
            if (poolInfoDict) {
                NSString * compileBasePath = poolInfoDict[@"compileBasePath"];
                
                NSString * currentIgnitedChamberId = [self igniteIdleChamber:compileBasePath];
                
                [messenger callParent:S2_COMPILECHAMBERCONT_EXEC_CHAMBER_IGNITED,
                 [messenger tag:@"ignitedChamberId" val:currentIgnitedChamberId],
                 nil];
            }
            break;
        }
        case S2_COMPILECHAMBERCONT_EXEC_UPDATE:{
            NSAssert(dict[@"updatedSource"], @"updatedSource required");
            [TimeMine setTimeMineLocalizedFormat:@"" withLimitSec:10000 withComment:@"アップデートが届いたので、分解して"];
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
        
        case S2_COMPILECHAMBER_EXEC_IGNITED:{
            NSAssert(dict[@"id"], @"id required");
            [self changeChamberStatus:dict[@"id"] to:static_chamber_states[STATE_COMPILING]];
            [self setChamberPriorityFirst:dict[@"id"]];
            
            /*
             イベントとしては、新しいigniteが来たタイミングで、
             ・priorityが変わる(newが現れる)
             ・それまでのnewがoldになる
             ・メッセージのレベルが落ちるので、
             clear
             旧メッセージの送り込みを継続
             になる。
             
             黄色で送り込むかな。messageQueue。
             */

            [TimeMine setTimeMineLocalizedFormat:@"2013/10/18 12:04:58" withLimitSec:100000 withComment:@"優先度のすげ替えが発生したので、一気に生きているチャンバーのinfoを塗り替える。"];
            
            break;
        }
            
        case S2_COMPILECHAMBER_EXEC_COMPILED:{
            NSAssert(dict[@"id"], @"id required");
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 19:37:31" withLimitSec:10000 withComment:@"コンパイル後の処理"];
            
            [self removePriority:dict[@"id"]];

            // 特定チャンバーのメッセージを消す
            [m_messageDict removeObjectForKey:dict[@"id"]];

            break;
        }
        case S2_COMPILECHAMBER_EXEC_ABORTED:{
            NSAssert(dict[@"id"], @"id required");
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 19:37:31" withLimitSec:10000 withComment:@"abort後の処理"];
            
            [self removePriority:dict[@"id"]];
            break;
        }
            
        case S2_COMPILECHAMBER_EXEC_TICK:{
            NSAssert(dict[@"id"], @"id required");
            NSAssert(dict[@"message"], @"message required");
            
            // もうここでフィルタリングして、光らせる系の命令にしちゃっていいんでは。
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/18 9:53:02" withLimitSec:100000 withComment:@"要素を削る最前提は、レベルパラメータをみて行う。レベリングはここで行う。arrayにchamberIdを溜めていって、先頭のほうほどレベルが高い。みたいにする。chamberが死んだらそのchamberからのメッセージはすべて削る。"];
            
            /*
             チャンバーの寿命は、igniteされたりabortされたりで替わる。現在塗りつぶし(既存runnningを破棄)は発生していないので、どうするかな。
             ー＞既存runnningで埋まった場合は何もしない、でOK
             */
            
            
            [messenger callParent:S2_COMPILECHAMBERCONT_EXEC_OUTPUT,
             [messenger tag:@"message" val:dict[@"message"]],
             nil];
            
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

- (NSString * ) igniteIdleChamber:(NSString * )compileBasePath {
    NSString * ignitedChamberId = nil;
    
    for (NSString * chamberId in [m_chamberDict keyEnumerator]) {
        NSDictionary * chamberInfoDict = m_chamberDict[chamberId];

        if ([chamberInfoDict[@"state"] isEqualToString:static_chamber_states[STATE_SPINUPPED]]) {
            
            ignitedChamberId = [[NSString alloc]initWithFormat:@"%@", chamberId];
            
            [messenger call:S2_COMPILECHAMBER withExec:S2_COMPILECHAMBER_EXEC_IGNITE,
             [messenger tag:@"id" val:chamberId],
             [messenger tag:@"compileBasePath" val:compileBasePath],
             nil];
            break;
        }
    }
    
    return ignitedChamberId;
}


- (void) setChamberPriorityFirst:(NSString * )chamberId {
    if ([m_chamberPriority containsObject:chamberId]) [m_chamberPriority removeObject:chamberId];
    [m_chamberPriority insertObject:chamberId atIndex:0];
}

- (BOOL) isFirstPriority:(NSString * )chamberId {
    return m_chamberPriority[0] == chamberId;
}

- (void) removePriority:(NSString * )chamberId {
    [m_chamberPriority removeObject:chamberId];
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
