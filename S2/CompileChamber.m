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

#import "TimeMine.h"

@implementation CompileChamber {
    KSMessenger * messenger;
    NSString * m_chamberId;
    
    NSArray * statesArray;
    
    
    MFTask * m_compileTask;
    
    NSString * m_state;
}

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:S2_COMPILECHAMBER];
        [messenger connectParent:masterNameAndId];
        
        statesArray = STATE_STR_ARRAY;
        
        
        m_chamberId = [[NSString alloc]initWithFormat:@"chamber_%@", [KSMessenger generateMID]];
        
        [messenger callMyself:S2_COMPILECHAMBER_EXEC_SPINUP, nil];
    }
    return self;
}

- (void) receiver:(NSNotification * )notif {
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
            
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/20 15:42:23" withLimitSec:100000 withComment:@"ignite 何回通ってますかね！！"];
            
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
}

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
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/20 18:22:15" withLimitSec:10000 withComment:@"スピンアップ処理、gradleを途中で止めておけるとベスト。スピンアップ終了まではこのブロック内でロックしてOK。今回は瞬間でSpinUpしたことにする。"];
    
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
    
    NSArray * currentParams = @[@"--daemon", @"-b", compileBasePath, @"build", @"-i"];
    
    [m_compileTask setLaunchPath:@"/usr/local/bin/gradle"];
    [m_compileTask setArguments:currentParams];
    
    
    // compile start
    [m_compileTask launch];
}

- (BOOL) isCompiling {
    return m_state == statesArray[STATE_COMPILING];
}


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


/**
 マスターへと経過を送付する
 */
- (void) taskDidLaunch:(MFTask * ) theTask {
    m_state = statesArray[STATE_COMPILING];
    
    if ([messenger hasParent]) {
        [messenger callParent:S2_COMPILECHAMBER_EXEC_IGNITED,
         [messenger tag:@"id" val:m_chamberId],
         nil];
    }
}

- (void) taskDidRecieveData:(NSData * ) theData fromTask:(MFTask * )task {
    NSString * message = [[NSString alloc]initWithData:theData encoding:NSUTF8StringEncoding];
    if ([messenger hasParent]) {
        [messenger callParent:S2_COMPILECHAMBER_EXEC_TICK,
         [messenger tag:@"id" val:m_chamberId],
         [messenger tag:@"message" val:message],
         nil];
    }
}

- (void) taskDidRecieveErrorData:(NSData * ) theData fromTask:(MFTask * )task {
    NSString * message = [[NSString alloc]initWithData:theData encoding:NSUTF8StringEncoding];
    if ([messenger hasParent]) {
        [messenger callParent:S2_COMPILECHAMBER_EXEC_TICK,
         [messenger tag:@"id" val:m_chamberId],
         [messenger tag:@"message" val:message],
         nil];
    }
}

- (void) taskDidTerminate:(MFTask * ) theTask {
    m_state = statesArray[STATE_COMPILED];
    
    if ([messenger hasParent]) {
        [messenger callParent:S2_COMPILECHAMBER_EXEC_COMPILED,
         [messenger tag:@"id" val:m_chamberId],
         nil];
    }
}

- (void) taskDidRecieveInvalidate:(MFTask * ) theTask {}



- (void) close {
    [messenger closeConnection];
}












@end
