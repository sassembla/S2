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
}

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:S2_COMPILECHAMBER];
        
        
        statesArray = STATE_STR_ARRAY;
        
        
        m_chamberId = [[NSString alloc]initWithFormat:@"chamber_%@", [KSMessenger generateMID]];
        m_state = statesArray[STATE_SPINUPPING];
        
        
        [messenger connectParent:masterNameAndId];
        
        [messenger callParent:S2_COMPILECHAMBER_EXEC_SPAWNED,
         [messenger tag:@"id" val:m_chamberId],
         nil];
        
        [messenger callMyself:S2_COMPILECHAMBER_EXEC_SPINUP,
//         [messenger withDelay:DEFAULT_SPINUP_TIME],
         nil];
    }
    return self;
}

- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:[messenger myName] viaNotification:notif]) {
        case S2_COMPILECHAMBER_EXEC_SPINUP:{
            [self spinup];
            return;
        }
    }
    
    // 自分以外からのmessageは、chamberIdのチェックを行う
    NSAssert(dict[@"chamberId"], @"chamberId required");
    
    if (dict[@"chamberId"] != m_chamberId) {
        return;
    }
    
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 16:41:21" withLimitSec:10000 withComment:@"受け取るものを考え中。起動命令、中止命令"];
//    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
//        case <#constant#>:
//            <#statements#>
//            break;
//            
//        default:
//            break;
//    }
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
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/20 18:22:15" withLimitSec:10000 withComment:@"スピンアップ処理、gradleを途中で止めておけるとベスト。スピンアップ終了まではロックしてOK。今回は即SpinUpしたことにする。"];
    
    m_state = statesArray[STATE_SPINUPPED];
    
    [messenger callParent:S2_COMPILECHAMBER_EXEC_SPINUPPED,
     [messenger tag:@"id" val:m_chamberId],
     nil];
}


/**
 着火
 */
- (void) ignite:(NSString * )compileBasePath withCodes:(NSDictionary * )idsAndContents {
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 17:24:14" withLimitSec:10000 withComment:@"プールから現状のコードを取得する。最小の更新箇所だけを貰う感じ、とかが出来なくても良いので、現在充填されてるコード群を丸っと持ってくる。ポインタだけとかで良いかな。ignite時に渡されれば良い。"];
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 17:33:37" withLimitSec:10000 withComment:@"プールに入れた時点で、情報を纏めておくと良いと思うので、ここでは特にgradleのパスと、コード集の辞書を丸っと渡す。"];
    
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
    [m_compileTask setTerminationHandler:^(NSTask * task) {
        NSLog(@"%@ killed!", task);
    }];
    
    
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 18:47:06" withLimitSec:10000 withComment:@"currentOut の受けと、直上のマスターへの返答をしないといけないが、どうすれば良いかなー。tailを調べる"];
    
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 18:47:06" withLimitSec:10000 withComment:@"無視方法は、コントローラ側でcurrentでなければ無視する、みたいなので良い"];
    
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 19:07:19" withLimitSec:1000 withComment:@"まだコンパイルできない。"];
//    [compileTask launch];
    
    
    
    m_state = statesArray[STATE_COMPILING];
    [messenger callParent:S2_COMPILECHAMBER_EXEC_IGNITED,
     [messenger tag:@"id" val:m_chamberId],
     nil];
}



/**
 中断
 */
- (void) abort {
    if ([m_compileTask isRunning]) {
        [m_compileTask terminate];
        // たぶん非同期でシグナルが来るような気がする。
    }
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 18:49:46" withLimitSec:10000 withComment:@"中断処理、taskを強制的にterminateする。"];
    
    m_state = statesArray[STATE_ABORTED];
}


- (void) close {
    [messenger closeConnection];
}

@end
