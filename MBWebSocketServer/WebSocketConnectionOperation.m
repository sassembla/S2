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

#import "TimeMine.h"



@implementation WebSocketConnectionOperation {
    KSMessenger * messenger;
        
    //behave as server
    MBWebSocketServer * m_server;
}

- (id) initWebSocketConnectionOperationWithMaster:(NSString * )masterNameAndId withAddressAndPort:(NSString * )addr {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:KS_WEBSOCKETCONNECTIONOPERATION];
        
        [messenger connectParent:masterNameAndId];
        
        
        //initialize
        NSInteger port = 0;
        

        NSArray * addrAndPortArray = [addr componentsSeparatedByString:@":"];
        NSAssert1([addrAndPortArray count] == 3, @"shortage of ':', %@", addr);

        port = [addrAndPortArray[2] integerValue];
        
        
        m_server = [[MBWebSocketServer alloc]initWithPort:port delegate:self];
        NSAssert(m_server, @"failed to start serving, @ %@", addr);
        
        
        [messenger callParent:KS_WEBSOCKETCONNECTIONOPERATION_OPENED, nil];
    }
    return self;
}




- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
        case KS_WEBSOCKETCONNECTIONOPERATION_PUSH:{
            NSAssert(dict[@"message"], @"message required");
            [m_server send:dict[@"message"]];
            //どうかなーsend時に対応しないと行けないよなー
            break;
        }
    }
}





/**
 delegate act as server
 */
- (void)webSocketServer:(MBWebSocketServer * )webSocketServer didAcceptConnection:(GCDAsyncSocket *)connection {
    
    NSString * addrAndPort = [[NSString alloc]initWithFormat:@"%@:%hu", [connection connectedHost], [connection connectedPort]];
    [messenger callParent:KS_WEBSOCKETCONNECTIONOPERATION_ESTABLISHED,
     [messenger tag:@"clientAddr:port" val:addrAndPort],
     nil];
}
- (void)webSocketServer:(MBWebSocketServer * )webSocketServer clientDisconnected:(GCDAsyncSocket *)connection {
    if ([messenger hasParent]) {
        [messenger callParent:KS_WEBSOCKETCONNECTIONOPERATION_DISCONNECTED, nil];
    }
}
- (void)webSocketServer:(MBWebSocketServer * )webSocket didReceiveData:(NSData *)data fromConnection:(GCDAsyncSocket *)connection {
   [messenger callParent:KS_WEBSOCKETCONNECTIONOPERATION_RECEIVED,
     [messenger tag:@"data" val:data],
     nil];
}

- (void)webSocketServer:(MBWebSocketServer *)webSocketServer couldNotParseRawData:(NSData *)rawData fromConnection:(GCDAsyncSocket *)connection error:(NSError *)error {}



- (void) shutDown {
    [m_server disconnect];
    [messenger closeConnection];
}

@end
