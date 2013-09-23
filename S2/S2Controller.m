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



@implementation S2Controller {
    KSMessenger * messenger;
    
    WebSocketConnectionOperation * serverOperation;
}

- (id) initWithMaster:(NSString * )masterNameAndId {

    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:S2_MASTER];
        [messenger connectParent:masterNameAndId];
    }
    
    return self;
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
        case EXEC_INITIALIZE:{
            NSAssert(dict[@"url"], @"url required");
            
            serverOperation = [[WebSocketConnectionOperation alloc]initWebSocketConnectionOperationWithMaster:[messenger myNameAndMID] withAddressAndPort:dict[@"url"]];
            
			break;
		}
			
		default:
			break;
	}
    
    switch ([messenger execFrom:KS_WEBSOCKETCONNECTIONOPERATION viaNotification:notif]) {
        case KS_WEBSOCKETCONNECTIONOPERATION_OPENED:{
            [TimeMine setTimeMineLocalizedFormat:@"2013/09/23 10:51:41" withLimitSec:10000 withComment:@"開いた通知が来たので、準備完了している筈"];
            break;
        }
        case KS_WEBSOCKETCONNECTIONOPERATION_RECEIVED:{
            [TimeMine setTimeMineLocalizedFormat:@"2013/09/23 10:15:10" withLimitSec:1000 withComment:@"データの受け取りが完了したので、チャンバーへと回す。idとかを取り出すことが出来る筈。"];
            break;
        }
            
        default:
            break;
    }

}



- (void) shutDown {
    [serverOperation shutDown];
    [TimeMine setTimeMineLocalizedFormat:@"2013/09/22 21:57:25" withLimitSec:100000 withComment:@"WebSocketServerを閉じる処理"];
    [messenger closeConnection];
}



@end
