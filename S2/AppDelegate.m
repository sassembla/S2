//
//  AppDelegate.m
//  S2
//
//  Created by sassembla on 2013/09/21.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "AppDelegate.h"
#import "KSMessenger.h"

#import "WebSocketConnectionOperation.h"

#define S2_MASTER	(@"S2_MASTER")

enum S2_EXEC {
	EXEC_START_WEBSOCKET
};


@implementation AppDelegate {
	KSMessenger * messenger;
	
	WebSocketConnectionOperation * server;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:S2_MASTER];
	
	/*
     WebSocketServerを起動
	 */
	[messenger callMyself:EXEC_START_WEBSOCKET, nil];
}




- (void) receiver:(NSNotification * )notif {
	NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
	
	switch ([messenger execFrom:S2_MASTER viaNotification:notif]) {
		case EXEC_START_WEBSOCKET:{
			server = [[WebSocketConnectionOperation alloc]initWebSocketConnectionOperationWithMaster:[messenger myNameAndMID] withConnectionTarget:@"ws://:8824" withConnectionIdentity:@"TEST" withOption:nil];
			break;
		}
			
		default:
			break;
	}
}

/**
 親を呼ぶ(テスト時のみ使用)
 */
- (void) callParentIfExist:(int)exec {
	if ([messenger hasParent]) {
		[messenger callParent:exec, nil];
	}
}

@end
