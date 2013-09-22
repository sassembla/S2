//
//  WebSocketConnectionOperation.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/23.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

/**
 WebSocketのConnection単位での保持を行うOperation
 
 */


#import "WebSocketConnectionOperation.h"
#import "KSMessenger.h"

/*
 m_operationId は、このインスタンスのidそのもの。このインスタンスと寿命をともにする。
 */
@implementation WebSocketConnectionOperation {
    NSString * m_operationId;
    KSMessenger * messenger;
        
    //behave as server
    MBWebSocketServer * m_server;
}

- (id) initWebSocketConnectionOperationWithMaster:(NSString * )masterNameAndId withConnectionTarget:(NSString * )targetAddr withConnectionIdentity:(NSString * )connectionIdentity withOption:(NSDictionary * )opt {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:KS_WEBSOCKETCONNECTIONOPERATION];
        
        [messenger connectParent:masterNameAndId];
        
        m_operationId = [[NSString alloc]initWithString:connectionIdentity];
        
                
        //initialize
        NSInteger port = 0;
        
        NSString * portWithAddress = targetAddr;
        NSArray * array = [portWithAddress componentsSeparatedByString:@":"];
        NSAssert1([array count] == 3, @"shortage of ':', %@", portWithAddress);

        port = [array[2] integerValue];
        
        NSAssert2(0 < port, @"failed to initialize WebSocket-server, named:%@ port:%@", connectionIdentity, targetAddr);
        
        m_server = [[MBWebSocketServer alloc]initWithPort:port delegate:self];
        NSAssert(m_server, @"failed to start serving, named:%@", connectionIdentity);
    }
    return self;
}


- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    NSAssert(dict[@"operationId"], @"operationId required");
    
    
    if ([dict[@"operationId"] isEqualTo:m_operationId]) {

    } else {
        return;
    }
    
    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
            
        case KS_WEBSOCKETCONNECTIONOPERATION_OPEN:{
            [messenger callParent:KS_WEBSOCKETCONNECTIONOPERATION_ESTABLISHED,
             [messenger tag:@"operationId" val:m_operationId],
             nil];
            break;
        }
            
        case KS_WEBSOCKETCONNECTIONOPERATION_INPUT:{
            NSAssert(dict[@"message"], @"message required");
            [m_server send:dict[@"message"]];
            break;
        }
            
        case KS_WEBSOCKETCONNECTIONOPERATION_CLOSE:{
            [m_server disconnect];
            [messenger closeConnection];
            break;
        }
            
        default:
            break;
    }
}

- (void) received:(id)message {
    [messenger callParent:KS_WEBSOCKETCONNECTIONOPERATION_RECEIVED,
     [messenger tag:@"operationId" val:m_operationId],
     [messenger tag:@"message" val:message],
     nil];
}

/**
 delegate act as server
 */
- (void)webSocketServer:(MBWebSocketServer *)webSocketServer didAcceptConnection:(GCDAsyncSocket *)connection {
    NSLog(@"開通確認");
}
- (void)webSocketServer:(MBWebSocketServer *)webSocketServer clientDisconnected:(GCDAsyncSocket *)connection {}
- (void)webSocketServer:(MBWebSocketServer *)webSocket didReceiveData:(NSData *)data fromConnection:(GCDAsyncSocket *)connection {
    NSString * message = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [self received:message];
}

- (void)webSocketServer:(MBWebSocketServer *)webSocketServer couldNotParseRawData:(NSData *)rawData fromConnection:(GCDAsyncSocket *)connection error:(NSError *)error {}


@end
