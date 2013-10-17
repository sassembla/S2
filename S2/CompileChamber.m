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

    if ([messenger hasParent]) {
        [messenger callParent:S2_COMPILECHAMBER_EXEC_SPINUPPED,
         [messenger tag:@"id" val:m_chamberId],
         nil];
    }
}


/**
 着火
 */
- (void) ignite:(NSString * )compileBasePath withCodes:(NSDictionary * )idsAndContents {
    
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/17 19:14:11" withLimitSec:10000 withComment:@"試験実装として、一カ所にフォルダをつくり、ファイルを吐き出す。吐き出し先はべつにここで設定しないでも良い筈。プールが吐き出しててもいい。それが終わってから処理が走る、とか。"];
    
    NSString * targetPath = @"/Users/highvision/1_36_38/";
    
    [self generateFiles:idsAndContents to:targetPath];
    
    NSString * refinedCompileBasePath = @"S2Tests/TestResource/sampleProject/build.gradle";

    NSString * placeBasePathWithGradlePath = [[NSString alloc] initWithFormat:@"%@%@", targetPath, refinedCompileBasePath];
    
    
    m_compileTask = [[MFTask alloc] init];
    [m_compileTask setDelegate:self];
    
    NSArray * currentParams = @[@"--daemon", @"-b", placeBasePathWithGradlePath, @"build", @"-i"];
    
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
}


/**
 マスターへと経過を送付する
 */
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

- (void) taskDidLaunch:(MFTask * ) theTask {
    m_state = statesArray[STATE_COMPILING];
    
    if ([messenger hasParent]) {
        [messenger callParent:S2_COMPILECHAMBER_EXEC_IGNITED,
         [messenger tag:@"id" val:m_chamberId],
         nil];
    }
}

- (void) close {
    [messenger closeConnection];
}








/**
 ファイル作成(メモリ上のものを使う場合は不要)
 */
- (void) generateFiles:(NSDictionary * )pathAndSources to:(NSString * )generateTargetPath {
    
    NSError * error;
    NSFileManager * fMan = [[NSFileManager alloc]init];
    [fMan createDirectoryAtPath:generateTargetPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    //ファイル出力
    for (NSString * path in [pathAndSources allKeys]) {
        NSString * targetPath;
        
        //フォルダ生成
        targetPath = [NSString stringWithFormat:@"%@%@", generateTargetPath, path];
        [fMan createDirectoryAtPath:[targetPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        
        //ファイル生成
        bool result = [fMan createFileAtPath:targetPath contents:[pathAndSources[path] dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        
        if (result) {
            NSLog(@"generated:%@", targetPath);
        } else {
            NSLog(@"fail to generate:%@", targetPath);
        }
        
        NSFileHandle * writeHandle = [NSFileHandle fileHandleForUpdatingAtPath:targetPath];
        [writeHandle writeData:[pathAndSources[path] dataUsingEncoding:NSUTF8StringEncoding]];
    }
}




@end
