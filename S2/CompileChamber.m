//
//  CompileChamber.m
//  S2
//
//  Created by sassembla on 2013/10/13.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "CompileChamber.h"
#import "KSMessenger.h"

#import "S2Token.h"
#import "Emitter.h"

#import "CompileSettingController.h"

#import "TimeMine.h"

@implementation CompileChamber {
    KSMessenger * messenger;
    KSMessenger * settingReceiver;
    
    NSString * m_chamberId;
    
    NSArray * statesArray;
    
    NSString * m_emitterId;
    Emitter * emitter;
    
    MFTask * m_compileTask;
    
    NSString * m_state;
}

- (id) initWithChamberId:(NSString * )chamberId withMasterNameAndId:(NSString * )masterNameAndId {
    if (self = [super init]) {
        // messenger that compile control only
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(compilationReceiver:) withName:S2_COMPILECHAMBER];
        [messenger connectParent:masterNameAndId];
        
        // messenger that setting receive only
        settingReceiver = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(settingReceiver:) withName:S2_COMPILECHAMBER_SETTINGRECEIVER];
        [settingReceiver connectParent:S2_COMPILERSETTINGCONTROLLER];
        
        statesArray = STATE_STR_ARRAY;
        m_emitterId = [[NSString alloc]initWithString:[KSMessenger generateMID]];
        emitter = [[Emitter alloc]initWithMasterName:[messenger myNameAndMID] as:m_emitterId];
        
        m_chamberId = [[NSString alloc]initWithString:chamberId];
        
        [messenger callMyself:S2_COMPILECHAMBER_EXEC_SPINUP, nil];
    }
    return self;
}

- (void) compilationReceiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:[messenger myName] viaNotification:notif]) {
        case S2_COMPILECHAMBER_EXEC_SPINUP:{
            m_state = statesArray[STATE_SPINUPPING];
            
            // 非同期でspinupを行う
            [messenger callMyself:S2_COMPILECHAMBER_EXEC_SPINUP_WITH_ASYNC,
             [messenger tag:@"identity" val:[messenger myMID]],
             [messenger withDelay:S2_DEFAULT_SPINUP_TIME],
             nil];
            return;
        }
        case S2_COMPILECHAMBER_EXEC_SPINUP_WITH_ASYNC:{
            [self spinup];
            return;
        }
        case S2_COMPILECHAMBER_EXEC_COMPILE:{
            NSAssert(dict[@"compileTask"], @"compileTask required");
            MFTask * task = dict[@"compileTask"];
            
            // launch
            [task launch];
            return;
        }
    }
    
    // 自分以外からのmessageは、chamberIdのチェックを行う
    NSAssert(dict[@"id"], @"id required");
    
    if (![dict[@"id"] isEqualToString:m_chamberId]) {
        return;
    }
    
    
    // controllerからのmessage
    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
        case S2_COMPILECHAMBER_EXEC_SPINUP:{
            [messenger callMyself:S2_COMPILECHAMBER_EXEC_SPINUP, nil];
            break;
        }
        case S2_COMPILECHAMBER_EXEC_IGNITE:{
            NSAssert(dict[@"compileBasePath"], @"compileBasePath required");
            
            [self ignite:dict[@"compileBasePath"]];
            break;
        }
        case S2_COMPILECHAMBER_EXEC_ABORT:{
            [self abort];
            break;
        }
        case S2_COMPILECHAMBER_EXEC_PURGE:{
            [self abort];
            [self close];
            break;
        }
    }
    
    
    // emitterからのmessage
    switch ([messenger execFrom:m_emitterId viaNotification:notif]) {
        case S2_EMITTER_EXEC_OUTPUT:{
            NSAssert(dict[@"type"], @"type required");
            NSAssert(dict[@"messageDict"], @"messageDict required");
            
            
            int type = [dict[@"type"] intValue];
            if ([messenger hasParent]) {
                [messenger callParent:S2_COMPILECHAMBER_EXEC_TICK,
                 [messenger tag:@"id" val:m_chamberId],
                 [messenger tag:@"type" val:dict[@"type"]],
                 [messenger tag:@"messageDict" val:dict[@"messageDict"]],
                 nil];
            }
            
            
            if (type == EMITTER_MESSAGE_TYPE_CONTROL) {
                
                if ([messenger hasParent]) {
                    [TimeMine setTimeMineLocalizedFormat:@"2013/11/30 0:26:45" withLimitSec:100000 withComment:@"コントロールされた完了をトレースする。理由が特殊そうな気がする。"];
                    //                NSString * chamberIdAndMessage = [[NSString alloc]initWithFormat:@"%@ : %@", m_chamberId, @", コントロールされたcompiled!がありそう"];
                    //                [messenger callParent:S2_COMPILECHAMBER_EXEC_TICK,
                    //                 [messenger tag:@"id" val:m_chamberId],
                    //                 [messenger tag:@"type" val:@(EMITTER_MESSAGE_TYPE_MESSAGE)],
                    //                 [messenger tag:@"messageDict" val:@{@"message":chamberIdAndMessage}],
                    //                 nil];
                }
                
                
                m_state = statesArray[STATE_COMPILED];
                
                if ([messenger hasParent]) {
                    [messenger callParent:S2_COMPILECHAMBER_EXEC_COMPILED,
                     [messenger tag:@"id" val:m_chamberId],
                     nil];
                }
            }
            break;
        }
    }
}


- (void) settingReceiver:(NSNotification * )notif {}


- (NSString * ) state {
    return m_state;
}


- (NSString * ) chamberId {
    return m_chamberId;
}


/**
 スピンアップ
 */
- (void) spinup {
    [TimeMine setTimeMineLocalizedFormat:@"2013/11/30 11:51:25" withLimitSec:100000 withComment:@"スピンアップ処理、gradleを途中で止めておけるとベスト。スピンアップ終了まではこのブロック内でロックしてOK。今回は瞬間でSpinUpしたことにする。"];
    
    // spinupping
    m_state = statesArray[STATE_SPINUPPED];

    if ([messenger hasParent]) {
        [messenger callParent:S2_COMPILECHAMBER_EXEC_SPINUPPED,
         [messenger tag:@"id" val:m_chamberId],
         nil];
    }
}


/**
 着火
 */
- (void) ignite:(NSString * )compileBasePath {
    
    m_compileTask = [[MFTask alloc] init];
    [m_compileTask setDelegate:self];
    
    [m_compileTask setLaunchPath:@"/bin/sh"];
    
    
    // zincとMFTaskの足し算だと取れないものがある。errorかな。
    NSString * gradlebuildStr = [[NSString alloc]initWithFormat:@"/usr/local/bin/gradle --daemon -b %@ build -i", compileBasePath];
    NSArray * currentParams = @[@"-c", gradlebuildStr];

    [m_compileTask setArguments:currentParams];
    
    m_state = statesArray[STATE_COMPILING];
    
    if ([messenger hasParent]) {
        [messenger callParent:S2_COMPILECHAMBER_EXEC_IGNITED,
         [messenger tag:@"id" val:m_chamberId],
         nil];
    }
    
    // read setting
    NSDictionary * compilationSetting = [settingReceiver callParent:S2_COMPILECHAMBER_SETTINGRECEIVER_EXEC_GET, nil][@"settingsDict"];
    
    float compileDelay = S2_COMPILER_WAIT_TIME;
    if (compilationSetting[@"compileDelay"]) compileDelay = [compilationSetting[@"compileDelay"] floatValue];
    
    [messenger callMyself:S2_COMPILECHAMBER_EXEC_COMPILE,
     [messenger withDelay:compileDelay],
     [messenger tag:@"compileTask" val:m_compileTask],
     nil];
}

- (BOOL) isCompiling {
    return m_state == statesArray[STATE_COMPILING];
}



- (void) taskDidRecieveData:(NSData*) theData fromTask:(MFTask*)task {
    NSString * message = [[NSString alloc]initWithData:theData encoding:NSUTF8StringEncoding];
    [self filteringWithEmitter:message];
}

- (void) taskDidRecieveErrorData:(NSData*) theData fromTask:(MFTask*)task {
    NSString * message = [[NSString alloc]initWithData:theData encoding:NSUTF8StringEncoding];
    [self filteringWithEmitter:message];
}

- (void) filteringWithEmitter:(NSString * )message {
    [emitter filtering:message withChamberId:m_chamberId];
}

- (void) taskDidTerminate:(MFTask*) theTask {}

- (void) taskDidRecieveInvalidate:(MFTask*) theTask {}

- (void) taskDidLaunch:(MFTask*) theTask {}



/**
 中断
 */
- (void) abort {
    if ([m_compileTask isRunning]) {
        [m_compileTask terminate];
    }
    
    m_state = statesArray[STATE_ABORTED];
    
    [messenger callParent:S2_COMPILECHAMBER_EXEC_ABORTED,
     [messenger tag:@"id" val:m_chamberId],
     nil];
}


- (void) close {
    [settingReceiver closeConnection];
    [messenger closeConnection];
}
@end
