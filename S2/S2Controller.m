//
//  S2Controller.m
//  S2
//
//  Created by sassembla on 2013/09/22.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "S2Controller.h"
#import "KSMessenger.h"

#import "TimeMine.h"

#import "WebSocketConnectionOperation.h"
#import "PullUpController.h"

#import "CompileChamberController.h"
#import "CompileSettingController.h"


#import "Emitter.h"

#import "S2Token.h"


@implementation S2Controller {
    int m_state;
    
    KSMessenger * messenger;
    KSMessenger * poolMessenger;
    
    NSDictionary * paramDict;
    WebSocketConnectionOperation * serverOperation;
    
    NSDictionary * m_connectionDict;
    
    PullUpController * pullUpCont;
    
    CompileChamberController * cChamberCont;
    
    CompileSettingController * cSettingCont;
    
    Emitter * m_emitter;
}

/**
 値と親がある状態で初期化
 */
- (id) initWithDict:(NSDictionary * )params withMasterName:(NSString * )masterNameAndId {
        
    if (self = [super init]) {
        NSAssert1(params[KEY_WEBSOCKETSERVER_ADDRESS], @"%@ required", KEY_WEBSOCKETSERVER_ADDRESS);
        
        paramDict = [[NSDictionary alloc]initWithDictionary:params];

        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:S2_MASTER];
        [messenger connectParent:masterNameAndId];
        
        
        m_emitter = [[Emitter alloc]init];
        
        
        // serve
        serverOperation = [[WebSocketConnectionOperation alloc]initWebSocketConnectionOperationWithMaster:[messenger myNameAndMID] withAddressAndPort:paramDict[KEY_WEBSOCKETSERVER_ADDRESS]];
        
        // pull
        pullUpCont = [[PullUpController alloc] initWithMasterNameAndId:[messenger myNameAndMID]];
        
        // compile
        cChamberCont = [[CompileChamberController alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
        
        // setting
        cSettingCont = [[CompileSettingController alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
    }
    return self;
}


- (void) setCompilerSettings:(NSDictionary * )settingsDict {
    [messenger call:S2_COMPILERSETTINGCONTROLLER withExec:S2_COMPILERSETTINGCONTROLLER_EXEC_SET,
     [messenger tag:@"settingsDict" val:settingsDict],
     nil];
}


- (void) receiver:(NSNotification * )notif {
    
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    
    switch (m_state) {
        case STATE_NONE:{
            switch ([messenger execFrom:KS_WEBSOCKETCONNECTIONOPERATION viaNotification:notif]) {
                case KS_WEBSOCKETCONNECTIONOPERATION_OPENED:{
                    m_state = STATE_IGNITED;
                    break;
                }
            }
            break;
        }
            
        case STATE_IGNITED:{
            switch ([messenger execFrom:KS_WEBSOCKETCONNECTIONOPERATION viaNotification:notif]) {
                case KS_WEBSOCKETCONNECTIONOPERATION_ESTABLISHED:{
                    
                    [TimeMine setTimeMineLocalizedFormat:@"2013/11/03 1:06:45" withLimitSec:100000 withComment:@"リセットまでは必要ないけど、繋ぎ直しによるイベントとかを発行しないとなー。何がおこったか解らなくなる。"];
                    if (m_connectionDict) {
                        return;
                    }
                    
                    NSAssert(dict[@"clientAddr:port"], @"clientAddr:port required");
                    NSLog(@"connection established with %@", dict[@"clientAddr:port"]);
                    
                    
                    NSString * conUUID = [KSMessenger generateMID];
                    NSMutableDictionary * connectionDict = [[NSMutableDictionary alloc]init];
                    connectionDict[@"connectionAddr"] = dict[@"clientAddr:port"];
                    connectionDict[@"updatedCount"] = [NSNumber numberWithInteger:1];
                    
                   
                    // initialize
                    m_connectionDict = [[NSDictionary alloc]initWithObjectsAndKeys:connectionDict, conUUID, nil];
                    
                    // chamberのリセットを行う
                    [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_INITIALIZE,
                     [messenger tag:@"chamberCount" val:@S2_DEFAULT_CHAMBER_COUNT],
                     nil];
                    
                    // ready for signal. normally wait [listed].
                    [self callToMaster:S2_CONT_EXEC_CONNECTED withMessageDict:m_connectionDict];
                    
                    break;
                }
                case KS_WEBSOCKETCONNECTIONOPERATION_RECEIVED:{
                    NSAssert(dict[@"data"], @"data required");
                    [self routing:dict[@"data"]];
                    break;
                }
                case KS_WEBSOCKETCONNECTIONOPERATION_DISCONNECTED:{
                    // do nothing
                    break;
                }
            }
            
            switch ([messenger execFrom:S2_PULLUPCONT viaNotification:notif]) {
                case S2_PULLUPCONT_PULLING:{
                    NSAssert(dict[@"pullingId"], @"pullingId required");
                    NSAssert(dict[@"sourcePath"], @"sourcePath required");
                    
                    // gen pullMessage
                    NSString * pullMessage = [m_emitter generatePullMessage:dict[@"pullingId"] withPath:dict[@"sourcePath"]];
                    
                    [messenger call:KS_WEBSOCKETCONNECTIONOPERATION withExec:KS_WEBSOCKETCONNECTIONOPERATION_PUSH,
                     [messenger tag:@"message" val:pullMessage],
                     nil];
                    
                    [self callToMaster:S2_CONT_EXEC_PULLINGSTARTED withMessageDict:dict];
                    break;
                }
                case S2_PULLUPCONT_PULLUP:{
                    NSAssert(dict[@"path"], @"path required");
                    NSAssert(dict[@"source"], @"source required");
                    
                    
                    [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_POOL,
                     [messenger tag:@"path" val:dict[@"path"]],
                     [messenger tag:@"source" val:dict[@"source"]],
                     nil];
                    break;
                }
                case S2_PULLUPCONT_PULL_COMPLETED:{

                    // act as kick compiler.
                    [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_COMPILE, nil];
                    
                    // notify to user.
                    [TimeMine setTimeMineLocalizedFormat:@"2013/11/30 20:20:17" withLimitSec:100000 withComment:@"pullが終わった段階での通知をしよう。内容は、pullに関するidが降られているといいんだろうなーと思うなど。pull = リセットだわ。ファイルの削除とかが発生したらリセットが必要。リセットでエイリアス作るか。"];
                    NSString * pullCompletedMessage = @"pull overed";
                    

                    [messenger call:KS_WEBSOCKETCONNECTIONOPERATION withExec:KS_WEBSOCKETCONNECTIONOPERATION_PUSH,
                     [messenger tag:@"message" val:pullCompletedMessage],
                     nil];
                    
                    
                    [self callToMaster:S2_CONT_EXEC_PULLINGCOMPLETED withMessageDict:dict];
                    break;
                }
            }
            
            switch ([messenger execFrom:S2_COMPILECHAMBERCONT viaNotification:notif]) {
                case S2_COMPILECHAMBERCONT_EXEC_CAHMBERSPINUPPED:{

                    [self callToMaster:S2_CONT_EXEC_SPINUPPED withMessageDict:dict];
                    
                    break;
                }
                case S2_COMPILECHAMBERCONT_EXEC_CHAMBER_IGNITED:{
                    NSAssert(dict[@"ignitedChamberId"], @"ignitedChamberId required");
                    
                    [self callToMaster:S2_CONT_EXEC_IGNITED withMessageDict:dict];
                    break;
                }
                case S2_COMPILECHAMBERCONT_EXEC_CHAMBER_COMPILED:{
                    NSAssert(dict[@"compiledChamberId"], @"compiledChamberId required");
                    [self callToMaster:S2_CONT_EXEC_COMPILED withMessageDict:dict];
                    break;
                }
                case S2_COMPILECHAMBERCONT_EXEC_OUTPUT:{
                    NSAssert(dict[@"message"], @"message required");
                    
                    [messenger call:KS_WEBSOCKETCONNECTIONOPERATION withExec:KS_WEBSOCKETCONNECTIONOPERATION_PUSH,
                     [messenger tag:@"message" val:dict[@"message"]],
                     nil];
                    
                    [self callToMaster:S2_CONT_EXEC_OUTPUTTED withMessageDict:dict];
                    break;
                }
                case S2_COMPILECHAMBERCONT_EXEC_RESEND:{
                    NSAssert(dict[@"message"],  @"message required");
                    [self callToMaster:S2_CONT_EXEC_RESENDED withMessageDict:dict];
                }
            }
            break;
        }
    }
    
}


- (void) routing:(NSData * )data {

    // messagePack使うならココかな。送付側に負荷が無ければ良いけど、ありそうだよなー。でも使ってみないと解らない。使うと速いし軽いかも知れない。文字よりは軽そう。
    
    NSString * dataStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"dataStr %@", dataStr);
    
    if ([dataStr hasPrefix:S2_TRIGGER_PREFIX_LISTED]) {
        NSString * keyAndListOfSourcesStr = dataStr;
        
        // keyデリミタvalueデリミタ...ってなってるので、デリミタで割る。
        NSArray * keyAndListOfSourcesArray = [keyAndListOfSourcesStr componentsSeparatedByString:KEY_LISTED_DELIM];
        
        NSRange theRange;
        
        theRange.location = 1;
        theRange.length = [keyAndListOfSourcesArray count]-1;
        NSArray * listOfSourcesArray = [keyAndListOfSourcesArray subarrayWithRange:theRange];
        
        [messenger call:S2_PULLUPCONT withExec:S2_PULLUPCONT_LISTED,
         [messenger tag:@"listOfSources" val:listOfSourcesArray],
         nil];
        return;
    }
    
    if ([dataStr hasPrefix:S2_TRIGGER_PREFIX_PULLED]) {
        NSString * keyAndPathAndSource = dataStr;
        
        NSRange theRange;
        theRange.location = [S2_TRIGGER_PREFIX_PULLED length]+1;
        theRange.length = [[messenger myMID]length];
        
        NSString * pulledId = [keyAndPathAndSource substringWithRange:theRange];
        NSString * source = [keyAndPathAndSource substringFromIndex:[S2_TRIGGER_PREFIX_PULLED length]+[pulledId length]+1+1];
        
        NSAssert([pulledId length] == [[messenger myMID] length], @"pulledId length not match, %lu", (unsigned long)[pulledId length]);
        
        [messenger call:S2_PULLUPCONT withExec:S2_PULLUPCONT_PULLED,
         [messenger tag:@"pulledId" val:pulledId],
         [messenger tag:@"source" val:source],
         nil];
        return;
    }
    
    if ([dataStr hasPrefix:S2_TRIGGER_PREFIX_UPDATED]) {
        NSArray * spacedComponents = [dataStr componentsSeparatedByString:@" "];
        NSString * keyAndPathStr = spacedComponents[0];
        
        NSArray * keyAndPathArray = [keyAndPathStr componentsSeparatedByString:@":"];

        NSString * path = keyAndPathArray[1];
        
        NSString * source = [dataStr substringFromIndex:[S2_TRIGGER_PREFIX_UPDATED length] + [path length] + 1 + 1];
        
        [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_INPUT,
         [messenger tag:@"path" val:path],
         [messenger tag:@"source" val:source],
         nil];
        return;
    }
    
    if ([dataStr hasPrefix:S2_TRIGGER_PREFIX_COMPILE]) {
        [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_COMPILE, nil];
        return;
    }
}





- (int) state {
    return m_state;
}

- (int) updatedCount {
    for (NSString * key in m_connectionDict) {
        return [m_connectionDict[key][@"updatedCount"] intValue];
    }
    
    return -1;
}


// for test
- (void) callToMaster:(int)exec withMessageDict:(NSDictionary * )messageDict {
    if ([messenger hasParent]) {
        [messenger callParent:exec,
         [messenger tag:@"wrappedDict" val:messageDict],
         nil];
    }
}

- (NSDictionary * )compileChamberControllersMessageBuffer {
    return [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_MESSAGEBUFFER, nil][@"messageBuffer"];
}


/**
 終了
 */
- (void) shutDown {
    [serverOperation shutDown];
    
    [cChamberCont close];
    
    [cSettingCont close];
    
    [pullUpCont close];
    
    [messenger closeConnection];
}



@end
