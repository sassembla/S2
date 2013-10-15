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


#import "S2Token.h"


@implementation S2Controller {
    int m_state;
    
    KSMessenger * messenger;
    
    NSDictionary * paramDict;
    WebSocketConnectionOperation * serverOperation;
    
    NSDictionary * m_connectionDict;
    
    PullUpController * pullUpCont;
    
    CompileChamberController * cChamberCont;
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
        
        // serve
        serverOperation = [[WebSocketConnectionOperation alloc]initWebSocketConnectionOperationWithMaster:[messenger myNameAndMID] withAddressAndPort:paramDict[KEY_WEBSOCKETSERVER_ADDRESS]];
        
        // pull
        pullUpCont = [[PullUpController alloc] initWithMasterNameAndId:[messenger myNameAndMID]];
        
        // compile
        cChamberCont = [[CompileChamberController alloc]initWithMasterNameAndId:[messenger myNameAndMID]];
    }
    return self;
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
            // 1 first only
            switch ([messenger execFrom:KS_WEBSOCKETCONNECTIONOPERATION viaNotification:notif]) {
                case KS_WEBSOCKETCONNECTIONOPERATION_ESTABLISHED:{
                    
                    // only one can connect
                    if (m_connectionDict) {
                        NSLog(@"already connected by one client.");
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
                    
                    [messenger call:S2_COMPILECHAMBERCONT withExec:S2_COMPILECHAMBERCONT_EXEC_INITIALIZE,
                     [messenger tag:@"chamberCount" val:@S2_DEFAULT_CHAMBER_COUNT],
                     nil];
                    
                    
                    [self callToMaster:S2_EXEC_CONNECTED withMessageDict:m_connectionDict];
                    
                    break;
                }
                case KS_WEBSOCKETCONNECTIONOPERATION_RECEIVED:{
                    NSAssert(dict[@"data"], @"data required");
                    [self routing:dict[@"data"]];
                    break;
                }
                case KS_WEBSOCKETCONNECTIONOPERATION_DISCONNECTED:{
                    
                    [TimeMine setTimeMineLocalizedFormat:@"2013/10/13 16:30:38" withLimitSec:100000 withComment:@"切断時のアクション、なんらか表示する必要があるなー、、、ビューになんか出せるかな。チャンバー情報とかも筒抜けで出せれば。良い事あるかもな。"];
                    break;
                }
            }
            
            switch ([messenger execFrom:S2_PULLUPCONT viaNotification:notif]) {
                case PULLUPCONT_PULLING:{
                    NSAssert(dict[@"connectionId"], @"connectionId required");
                    NSAssert(dict[@"sourcePath"], @"sourcePath required");
                    
                    NSString * sourcePath = dict[@"sourcePath"];
                    NSString * identity = dict[@"connectionId"];
                    
                    NSString * message = [[NSString alloc]initWithFormat:@"ss@readFileData:{\"path\":\"%@\"}->(data|message)monocastMessage:{\"target\":\"S2Client\",\"message\":\"replace\",\"header\":\"-update:%@ \"}->showAtLog:{\"message\":\"pulled:%@\"}->showStatusMessage:{\"message\":\"pulled:%@\"}", sourcePath, identity, sourcePath, sourcePath];
                    
                    [messenger call:KS_WEBSOCKETCONNECTIONOPERATION withExec:KS_WEBSOCKETCONNECTIONOPERATION_PUSH,
                     [messenger tag:@"message" val:message],
                     nil];
                    
                    [self callToMaster:S2_EXEC_PULLINGSTARTED withMessageDict:dict];
                    break;
                }
            }
            break;
        }
    }
    
}


- (void) routing:(NSData * )data {

    // messagePack使うならココかな。送付側に負荷が無ければ良いけど、ありそうだよなー。でも使ってみないと解らない。使うと速いし軽いかも知れない。文字よりは軽そう。
    
    NSString * dataStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    // returnがあるかどうか、っての、頭にuuid着ければ解決しない？　っていうのはあるけど、一時認識するためにここでのexec分解は必須。
    
    if ([dataStr hasPrefix:TRIGGER_PREFIX_LISTED]) {
        [messenger call:S2_PULLUPCONT withExec:PULLUPCONT_LISTED,
         [messenger tag:@"listOfSources" val:dataStr],
         nil];
        return;
    }
    
    if ([dataStr hasPrefix:TRIGGER_PREFIX_PULLED]) {
        [messenger call:S2_PULLUPCONT withExec:PULLUPCONT_PULLED,
         [messenger tag:@"pulledSource" val:dataStr],
         nil];
        return;
    }

    [TimeMine setTimeMineLocalizedFormat:@"2013/10/14 23:47:18" withLimitSec:10000 withComment:@"このへんに、compileChamberControllerへのupdate受け入れ処理"];
//    if ([dataStr hasPrefix:TRIGGER_PREFIX_UPDATED]) {
//        [messenger call:S2_COMPCHAMBERCONT withExec:COMPCHAMBERCONT_UPDATED,
//         [messenger tag:@"updatedSource" val:dataStr],
//         nil];
//        return;
//    }
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



/**
 終了
 */
- (void) shutDown {
    
    [serverOperation shutDown];
    
    [pullUpCont close];
    
    [messenger closeConnection];
}



@end
