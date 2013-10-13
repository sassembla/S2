//
//  WebSocketConnectionOperation.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/23.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <Foundation/Foundation.h>

//server
#import "MBWebSocketServer.h"

#define KS_WEBSOCKETCONNECTIONOPERATION (@"KS_WEBSOCKETCONNECTIONOPERATION")

#define KEY_WEBSOCKET_TYPE  (@"type")
#define OPTION_TYPE_SERVER  (@"server")



typedef enum {
    KS_WEBSOCKETCONNECTIONOPERATION_OPENED = 0,
    KS_WEBSOCKETCONNECTIONOPERATION_ESTABLISHED,
    KS_WEBSOCKETCONNECTIONOPERATION_RECEIVED,
    KS_WEBSOCKETCONNECTIONOPERATION_DISCONNECTED
} TYPE_KS_WEBSOCKETCONNECTIONOPERATION;


typedef enum {
    WEBSOCKET_TYPE_SERVER,
} WEBSOCKET_TYPE;

@interface WebSocketConnectionOperation : NSObject <MBWebSocketServerDelegate>

- (id) initWebSocketConnectionOperationWithMaster:(NSString * )masterNameAndId withAddressAndPort:(NSString * )addr;
- (void) shutDown;
@end
