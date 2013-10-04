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


@implementation S2Controller {
    int m_state;
    
    KSMessenger * messenger;
    
    NSDictionary * paramDict;
    WebSocketConnectionOperation * serverOperation;
}

/**
 値と親がある状態で初期化
 */
- (id) initWithDict:(NSDictionary * )params withMasterName:(NSString * )masterNameAndId {
    
    if (params[KEY_XCTEST]) {
        return nil;
    }
    
    if (self = [super init]) {
        NSAssert1(params[KEY_WEBSOCKETSERVER_ADDRESS], @"%@ required", KEY_WEBSOCKETSERVER_ADDRESS);
        
        paramDict = [[NSDictionary alloc]initWithDictionary:params];

        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:S2_MASTER];
        [messenger connectParent:masterNameAndId];
        
        
        serverOperation = [[WebSocketConnectionOperation alloc]initWebSocketConnectionOperationWithMaster:[messenger myNameAndMID] withAddressAndPort:paramDict[KEY_WEBSOCKETSERVER_ADDRESS]];
    }
    return self;
}



- (void) receiver:(NSNotification * )notif {
    
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
//    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
//        default:{
//            NSLog(@"from parent default %@", dict);
//			break;
//        }
//	}
    
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
                    m_state = STATE_CONNECTED;
                    
                    break;
                }
                default:{
                    break;
                }
            }
            break;
        }
        case STATE_CONNECTED:{
            switch ([messenger execFrom:KS_WEBSOCKETCONNECTIONOPERATION viaNotification:notif]) {
                    
                case KS_WEBSOCKETCONNECTIONOPERATION_RECEIVED:{
                    NSAssert(dict[@"data"], @"data required");
                    NSString * dataStr = [[NSString alloc]initWithData:dict[@"data"] encoding:NSUTF8StringEncoding];
                    NSLog(@"dataStr %@", dataStr);
                    break;
                }
                    
                default:
                    break;
            }

            break;
        }
            
        default:
            break;
    }
    
}

- (int) state {
    return m_state;
}



- (void) shutDown {
    [serverOperation shutDown];
    [messenger closeConnection];
}



@end
