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

enum STATE {
    STATE_NONE,
    STATE_IGNITED,
    STATE_CONNECTED
};

@implementation S2Controller {
    int m_state;
    
    KSMessenger * messenger;
    
    
    WebSocketConnectionOperation * serverOperation;
}

- (id) initWithDict:(NSDictionary * )data {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:S2_MASTER];
        [TimeMine setTimeMineLocalizedFormat:@"2013/09/23 10:19:09" withLimitSec:1000 withComment:@"コマンドラインからのパラメータとかを入れる"];
    }
    return self;
}



- (void) receiver:(NSNotification * )notif {
    
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
        default:{
            NSLog(@"from parent default %@", dict);
			break;
        }
	}
    
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
                    [TimeMine setTimeMineLocalizedFormat:@"2013/09/23 10:15:10" withLimitSec:1000 withComment:@"データの受け取りが完了したので、チャンバーへと回す。idとかを取り出すことが出来る筈。"];
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



- (void) shutDown {
    [serverOperation shutDown];
    [messenger closeConnection];
}



@end
