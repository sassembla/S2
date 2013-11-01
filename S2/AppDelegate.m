//
//  AppDelegate.m
//  S2
//
//  Created by sassembla on 2013/09/21.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "AppDelegate.h"
#import "KSMessenger.h"

#import "S2Controller.h"

#import "S2Token.h"


#define S2_DELEGATE	(@"S2_DELEGATE")


/**
 ApplicationのDelegate
 起動のみを担当する。
 */
@implementation AppDelegate {
	KSMessenger * messenger;
}

- (id) initAppDelegateWithParam:(NSDictionary * )dict {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:S2_DELEGATE];
        
        if (dict[@"-XCTest"]) {}
        else {
            // set default server path
            NSDictionary * paramDict = @{KEY_WEBSOCKETSERVER_ADDRESS:S2_DEFAULT_ADDR};
            
            // App main controller with WebSocketServer
            S2Controller * cont = [[S2Controller alloc]initWithDict:paramDict withMasterName:[messenger myNameAndMID]];
        }
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {}

- (void) receiver:(NSNotification * )notif {}


@end
