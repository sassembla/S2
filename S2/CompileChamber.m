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
    
    // 今のところは普通のコンパイラ。
    NSTask * m_compileTask;
    
    NSString * m_state;
    
    BOOL m_compiling;
    
    NSArray * m_keywords;
}

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:S2_COMPILECHAMBER];
        [messenger connectParent:masterNameAndId];
        
        statesArray = STATE_STR_ARRAY;
        
        
        m_chamberId = [[NSString alloc]initWithFormat:@"chamber_%@", [KSMessenger generateMID]];
        
        [messenger callMyself:S2_COMPILECHAMBER_EXEC_SPINUP, nil];
        
        m_compiling = false;
        
        m_keywords = S2_COMPILER_KEYWORDS;
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
    
    if (dict[@"id"] != m_chamberId) {
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
            NSAssert(dict[@"idsAndContents"], @"idsAndContents required");
            
            [self ignite:dict[@"compileBasePath"] withCodes:dict[@"idsAndContents"]];
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

    [messenger callParent:S2_COMPILECHAMBER_EXEC_SPINUPPED,
     [messenger tag:@"id" val:m_chamberId],
     nil];
}


/**
 着火
 */
- (void) ignite:(NSString * )compileBasePath withCodes:(NSDictionary * )idsAndContents {
    m_compiling = true;
    
    m_compileTask = [[NSTask alloc] init];
    
    
//    NSString * currentCompileBasePath;
//    //build.gradleを探し出す
//    for (NSString * path in [codeDict allKeys]) {
//        if ([[path lastPathComponent] isEqualToString:@"build.gradle"]) {
//            currentCompileBasePath = [[NSString alloc]initWithString:path];
//        }
//    }
//    
//    if (currentCompileBasePath) {
//        
//    } else {
//        [self writeLogLine:@"compile abort, no build targeting file"];
//        return nil;
//    }
//    
//    
//    NSString * compileBasePath = [NSString stringWithFormat:@"%@%@", [self currentWorkPath], currentCompileBasePath];
//    [self writeLogLine:compileBasePath];

    
    NSArray * currentParams = @[@"--daemon", @"-b", compileBasePath, @"build", @"-i"];
    
    [m_compileTask setLaunchPath:@"/usr/local/bin/gradle"];
    [m_compileTask setArguments:currentParams];
    
    NSPipe * currentOut = [[NSPipe alloc]init];
    
    [m_compileTask setStandardOutput:currentOut];
    [m_compileTask setStandardError:currentOut];
    
    // compile start
    [m_compileTask launch];
    
    // ファイルハンドラを作ってそこから読む、みたいな処理があったよねー確か。あれはなんだったか。EnteringOrbitだ
    
    
    m_state = statesArray[STATE_COMPILING];
    [messenger callParent:S2_COMPILECHAMBER_EXEC_IGNITED,
     [messenger tag:@"id" val:m_chamberId],
     nil];
    
    NSFileHandle * publishHandle = [currentOut fileHandleForReading];
    
    
    char buffer[BUFSIZ];
    FILE * fp = fdopen([publishHandle fileDescriptor], "r");
    
    while(fgets(buffer, BUFSIZ, fp)) {
        NSString * message = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
        NSLog(@"hereComes %@", message);
        
        [TimeMine setTimeMineLocalizedFormat:@"2013/10/15 21:20:13" withLimitSec:100000 withComment:@"ここを使わないでもよくなった！"];
        
        [messenger callParent:S2_COMPILECHAMBER_EXEC_TICK,
         [messenger tag:@"id" val:m_chamberId],
         [messenger tag:@"message" val:message],
         nil];
    }
}

- (BOOL) isCompiling {
    return m_compiling;
}


/**
 中断
 */
- (void) abort {
    if ([m_compileTask isRunning]) {
        [m_compileTask terminate];
        // たぶん非同期でシグナルが来るような気がする。
    }
    
    m_state = statesArray[STATE_ABORTED];
}


- (void) shutdownTask {
    
}

- (void) close {
    [messenger closeConnection];
}

@end
