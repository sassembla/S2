//
//  S2Controller.m
//  S2
//
//  Created by sassembla on 2013/09/22.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "S2Controller.h"
#import "KSMessenger.h"


#import "WebSocketConnectionOperation.h"
#import "TimeMine.h"

#define KEY_XCTEST  (@"-XCTest")


#import "PullUpController.h"



@implementation S2Controller {
    int m_state;
    
    KSMessenger * messenger;
    
    NSDictionary * paramDict;
    WebSocketConnectionOperation * serverOperation;
    
    NSDictionary * m_connectionDict;
    
    PullUpController * pullUpCont;
}

/**
 値と親がある状態で初期化
 */
- (id) initWithDict:(NSDictionary * )params withMasterName:(NSString * )masterNameAndId {
    
    if (params[KEY_XCTEST]) {
        return nil;
    }
    
    if ([params count] == 0) {
        return nil;
    }
    
    if (self = [super init]) {
        NSAssert1(params[KEY_WEBSOCKETSERVER_ADDRESS], @"%@ required", KEY_WEBSOCKETSERVER_ADDRESS);
        
        paramDict = [[NSDictionary alloc]initWithDictionary:params];

        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:S2_MASTER];
        [messenger connectParent:masterNameAndId];
        
        
        serverOperation = [[WebSocketConnectionOperation alloc]initWebSocketConnectionOperationWithMaster:[messenger myNameAndMID] withAddressAndPort:paramDict[KEY_WEBSOCKETSERVER_ADDRESS]];
        
        
        // pull
        pullUpCont = [[PullUpController alloc] initWithMasterNameAndId:[messenger myNameAndMID]];
        
        
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
                default:{
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
                    m_connectionDict = @{conUUID:connectionDict};
                    
                    
                    [self callToMaster:S2_EXEC_CONNECTED withMessageDict:m_connectionDict];
                    
                    break;
                }
                case KS_WEBSOCKETCONNECTIONOPERATION_RECEIVED:{
                    NSAssert(dict[@"data"], @"data required");
                    [self routing:dict[@"data"]];
                    break;
                }
            }
            
            switch ([messenger execFrom:S2_PULLUPCONT viaNotification:notif]) {
                case PULLUPCONT_PULLING:{
                    [TimeMine setTimeMineLocalizedFormat:@"2013/10/08 0:24:53" withLimitSec:100 withComment:@"pullを実行する"];
                    
                    break;
                }
            }
            break;
        }
    }
    
}


- (void) routing:(NSData * )data {
    // stringに分解、になるのかなー。
    // messagePack使うならココかな。送付側に負荷が無ければ良いけど、ありそうだよなー。
    
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

    [TimeMine setTimeMineLocalizedFormat:@"2013/10/08 0:58:03" withLimitSec:10000 withComment:@"このへんに、compileChamberControllerへのupdate受け入れ処理"];
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

- (NSDictionary * ) connections {
    if (m_connectionDict) return m_connectionDict;
    return nil;
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
         [messenger tag:@"messageDict" val:messageDict],
         nil];
    }
}



/**
 終了
 */
- (void) shutDown {
    [pullUpCont close];
    [serverOperation shutDown];
    [messenger closeConnection];
}



@end
