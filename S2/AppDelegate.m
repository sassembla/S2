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


#define KEY_XCTEST  (@"-XCTest")


#define S2_DELEGATE	(@"S2_DELEGATE")


/**
 ApplicationのDelegate
 起動のみを担当する。
 */
@implementation AppDelegate {
	KSMessenger * messenger;
}

- (id) initWithParams:(NSDictionary * )params {
    
    if (params[KEY_XCTEST]) {
        return nil;
    }
    
    
    if (self = [super init]) {
        
    }
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:S2_DELEGATE];
	
    
    // App main controller with WebSocketServer
//    S2Controller * cont = [[S2Controller alloc]initWithDict:paramDict withMasterName:[messenger myNameAndMID]];

    
    
}




- (void) receiver:(NSNotification * )notif {
	NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
}


@end
