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

#import "S2Token.h"
#import "Emitter.h"


#import "TimeMine.h"

@implementation CompileChamberController {
    KSMessenger * messenger;

    NSMutableDictionary * m_chamberDict;
    
    int m_count;
    
    NSArray * static_chamber_states;
    
    ContentsPoolController * contentsPoolCont;
    
    NSMutableArray * m_chamberPriority;
    
    NSMutableDictionary * m_messageBuffer;
    
    Emitter * m_emitter;
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
        
        m_messageBuffer = [[NSMutableDictionary alloc]init];
        
        m_emitter = [[Emitter alloc]init];
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

- (NSArray * ) compilingChambers {
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
        case S2_COMPILECHAMBERCONT_EXEC_POOL:{
            NSAssert(dict[@"path"], @"path required");
            NSAssert(dict[@"source"], @"source required");
            
            [messenger call:S2_CONTENTSPOOLCONT withExec:S2_CONTENTSPOOLCONT_EXEC_ADD_DRAIN,
             [messenger tag:@"path" val:dict[@"path"]],
             [messenger tag:@"source" val:dict[@"source"]],
             nil];

            break;
        }
        case S2_COMPILECHAMBERCONT_EXEC_INPUT:{
            // インプットがあったので、プール上のコードを編集、編集完了と同時に暇なchamberへとGoを出す。
            NSAssert(dict[@"path"], @"path required");
            NSAssert(dict[@"source"], @"source required");
            
            [self compileOrNot:dict[@"path"] withSource:dict[@"source"]];
            
            break;
        }
        case S2_COMPILECHAMBERCONT_EXEC_COMPILE:{
            [self compileOrNot:nil withSource:nil];
            break;
        }
        case S2_COMPILECHAMBERCONT_EXEC_MESSAGEBUFFER:{
            [messenger callback:notif,
             [messenger tag:@"messageBuffer" val:m_messageBuffer],
             nil];
            break;
        }
    }
    
    // チャンバーからのメッセージ
    switch ([messenger execFrom:S2_COMPILECHAMBER viaNotification:notif]) {
        case S2_COMPILECHAMBER_EXEC_SPINUPPED:{
            NSAssert(dict[@"id"], @"id required");
            [self changeChamberStatus:dict[@"id"] to:static_chamber_states[STATE_SPINUPPED]];

            [messenger callParent:S2_COMPILECHAMBERCONT_EXEC_CAHMBERSPINUPPED, nil];
            break;
        }
        
        case S2_COMPILECHAMBER_EXEC_IGNITED:{
            NSAssert(dict[@"id"], @"id required");
            
            NSString * currentIgnitedChamberId = dict[@"id"];
            
            // compilingにする
            [self changeChamberStatus:currentIgnitedChamberId to:static_chamber_states[STATE_COMPILING]];
            
            // priorityを上げる
            [self setChamberPriorityFirst:currentIgnitedChamberId];
            
            // messageBufferに起動メッセージを足す
            [self bufferMessage:@{@"message":@"ignited"} withType:@(EMITTER_MESSAGE_TYPE_MESSAGE) to:currentIgnitedChamberId];
            

            [messenger callParent:S2_COMPILECHAMBERCONT_EXEC_CHAMBER_IGNITED,
             [messenger tag:@"ignitedChamberId" val:currentIgnitedChamberId],
             nil];
            
            NSString * message = [m_emitter generateMessage:EMITTER_MESSAGE_TYPE_MESSAGE withParam:@{@"message":[[NSString alloc]initWithFormat:@"chamber ignited:%@", currentIgnitedChamberId]} priority:0];
            
            NSString * withHead = [[NSString alloc]initWithFormat:@"ss@%@", message];
            
            [messenger callParent:S2_COMPILECHAMBERCONT_EXEC_OUTPUT,
             [messenger tag:@"message" val:withHead],
             nil];

            
            // resendを発生させる
            [self resendFrom:1 length:S2_RESEND_DEPTH];

            break;
        }
            
        case S2_COMPILECHAMBER_EXEC_COMPILED:{
            NSAssert(dict[@"id"], @"id required");
            
            [self removePriority:dict[@"id"]];

            
            
            // spinup
            [messenger call:S2_COMPILECHAMBER withExec:S2_COMPILECHAMBER_EXEC_SPINUP,
             [messenger tag:@"id" val:dict[@"id"]],
             nil];
            
            
            // 通知
            [messenger callParent:S2_COMPILECHAMBERCONT_EXEC_CHAMBER_COMPILED,
             [messenger tag:@"compiledChamberId" val:dict[@"id"]],
             nil];
            
            break;
        }
        case S2_COMPILECHAMBER_EXEC_ABORTED:{
            NSAssert(dict[@"id"], @"id required");
            
            // プライオリティから除外
            [self removePriority:dict[@"id"]];
            
            // spinup
            [messenger call:S2_COMPILECHAMBER withExec:S2_COMPILECHAMBER_EXEC_SPINUP,
             [messenger tag:@"id" val:dict[@"id"]],
             nil];
            
            // 通知
            [messenger callParent:S2_COMPILECHAMBERCONT_EXEC_CHAMBER_ABORTED,
             [messenger tag:@"abortedChamberId" val:dict[@"id"]],
             nil];
            break;
        }
            
        case S2_COMPILECHAMBER_EXEC_TICK:{
            NSAssert(dict[@"id"], @"id required");
            NSAssert(dict[@"type"], @"type required");
            NSAssert(dict[@"messageDict"], @"messageDict required");
            
            // 最新のみ
            if ([self isFirstPriority:dict[@"id"]]) {
                
                // buffer
                if (dict[@"messageDict"]) [self bufferMessage:dict[@"messageDict"] withType:dict[@"type"] to:dict[@"id"]];
                
                // メッセージを出力
                NSString * message = [m_emitter generateMessage:[dict[@"type"] intValue] withParam:dict[@"messageDict"] priority:0];
                if (message) {
                    NSString * output = [[NSString alloc]initWithFormat:@"ss@%@", message];
                    
                    [messenger callParent:S2_COMPILECHAMBERCONT_EXEC_OUTPUT,
                     [messenger tag:@"message" val:output],
                     nil];
                }
            }
            
            break;
        }
    }
}


/**
 set
 */
- (void) bufferMessage:(NSDictionary * )messageDict withType:(NSNumber * )type to:(NSString * )chamberId {
    NSMutableArray * array = m_messageBuffer[chamberId];
    
    // add type param
    NSMutableDictionary * bufDict = [[NSMutableDictionary alloc]initWithDictionary:messageDict];
    [bufDict setValue:type forKey:COMPILECHAMBERCONT_BUFFFERED_MESSAGETYPE];
    
    if (array) {
        [array addObject:bufDict];
    } else {
        array = [[NSMutableArray alloc]init];
        [array addObject:bufDict];
        [m_messageBuffer setValue:array forKey:chamberId];
    }
}



- (void) compileOrNot:(NSString * )path withSource:(NSString * )source {
    NSDictionary * poolInfoDict = nil;
    if (path && source) {
        poolInfoDict = [messenger call:S2_CONTENTSPOOLCONT withExec:S2_CONTENTSPOOLCONT_EXEC_ADD_DRAIN,
                                   [messenger tag:@"path" val:path],
                                   [messenger tag:@"source" val:source],
                                   nil];
    } else {
        poolInfoDict = [messenger call:S2_CONTENTSPOOLCONT withExec:S2_CONTENTSPOOLCONT_EXEC_DRAIN, nil];
    }
                        
    // ignition with input
    if (poolInfoDict) {
        NSString * compileBasePath = poolInfoDict[@"compileBasePath"];
        
        // spinup 状態のチャンバーを駆り出す
        if ([self igniteIdleChamber:compileBasePath]) {} else {
            // all chambers are full.
            // 全てのチャンバーがspinup中かコンパイル中。
            
            [messenger callParent:S2_COMPILECHAMBERCONT_EXEC_ALLCHAMBERS_FILLED, nil];
        }
    }
}

/**
 bufferの内容をresendする
 */
- (void) resendFrom:(int)index length:(int)len {
    if ([m_chamberPriority count] <= index) return;
    
    // 1 ~ length - index
    if ([m_chamberPriority count] < index + len) {
        len = (int)[m_chamberPriority count] - index;
    }
    
    // resend with priority-key
    NSMutableDictionary * priorityDict = [[NSMutableDictionary alloc]init];
    for (int i = index; i < index + len; i++) {
        
        
        NSString * chamberId = m_chamberPriority[i];
        if ((m_messageBuffer[chamberId])) {
            // chamberId:Array なので、これをそのままKey-Value としてコピーして渡す
            NSDictionary * currentDict = @{chamberId:m_messageBuffer[chamberId]};
            [priorityDict setValue:currentDict forKey:[[NSString alloc]initWithFormat:@"%d", i]];
        }
    }
    
    if (0 < [priorityDict count]) {
        // resend
        NSMutableArray * messageArray = [[NSMutableArray alloc]init];
        
        // keyで列挙、順は問わないが値は使う。
        for (NSString * priorityKeyStr in [priorityDict keyEnumerator]) {
            int priorityInt = [priorityKeyStr intValue];
            
            NSDictionary * identityAndMessageArray = priorityDict[priorityKeyStr];
            
            // 要素1で、内容はarray
            NSArray * messageArraySourceArray = [identityAndMessageArray allValues][0];
            
            // このmessageに対してkeyInt priorityでのメッセージ生成を行う
            for (NSDictionary * rawMessageDict in messageArraySourceArray) {
                NSAssert1(rawMessageDict[COMPILECHAMBERCONT_BUFFFERED_MESSAGETYPE], @"%@ required", COMPILECHAMBERCONT_BUFFFERED_MESSAGETYPE);
                int type = [rawMessageDict[COMPILECHAMBERCONT_BUFFFERED_MESSAGETYPE] intValue];
                NSString * filteredMessage = [m_emitter generateMessage:type withParam:rawMessageDict priority:priorityInt];
                
                if (filteredMessage) [messageArray addObject:filteredMessage];
            }
        }
        
        NSString * combined = [m_emitter combineMessages:messageArray];
        
        if (0 < [combined length]) {
            NSString * withHead = [[NSString alloc]initWithFormat:@"ss@%@", combined];
            
            [messenger callParent:S2_COMPILECHAMBERCONT_EXEC_OUTPUT,
             [messenger tag:@"message" val:withHead],
             nil];
            
            // send for information
            [messenger callParent:S2_COMPILECHAMBERCONT_EXEC_RESEND,
             [messenger tag:@"message" val:withHead],
             nil];
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
    
    /*
    // 無い場合、プライオリティの低いコンパイル中のものを使用する。
    if (ignitedChamberId) {} else {
        lowPriorityChamberId なチャンバーの動作をabort -> spinup -> 、、と持っていくことは出来るが、メリットを感じないのでやらない。
        ignitedChamberId = [self lowPriorityAbortableChamberId];
    }
     */
    
    return ignitedChamberId;
}


- (void) setChamberPriorityFirst:(NSString * )chamberId {
    if ([m_chamberPriority containsObject:chamberId]) {
        [m_chamberPriority removeObject:chamberId];
    }
    [m_chamberPriority insertObject:chamberId atIndex:0];
}

- (BOOL) isFirstPriority:(NSString * )chamberId {
    return m_chamberPriority[0] == chamberId;
}

- (NSNumber * ) chamberPriority:(NSString * )chamberid {
   
    if ([m_chamberPriority containsObject:chamberid]) {
        return [NSNumber numberWithInteger:[m_chamberPriority indexOfObject:chamberid]];
    }
    
    NSAssert(false, @"should not reach here");
    
    return @-1;
}

- (void) removePriority:(NSString * )chamberId {
    [m_chamberPriority removeObject:chamberId];
}

- (NSString * ) lowPriorityAbortableChamberId {
    for (NSString * lowPriorityChamberId in [m_chamberPriority reverseObjectEnumerator]) {
        NSDictionary * chamberInfoDict = m_chamberDict[lowPriorityChamberId];
        if ([chamberInfoDict[@"state"] isEqualToString:static_chamber_states[STATE_COMPILING]]) {
            return lowPriorityChamberId;
        }
    }
    return nil;
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
