//
//  S2Controller.h
//  S2
//
//  Created by sassembla on 2013/09/22.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>



#define S2_MASTER   (@"S2_MASTER")

enum S2_STATE {
    STATE_NONE,
    STATE_IGNITED
};

enum S2_CONT_EXEC {
    S2_CONT_EXEC_CONNECTED,
    S2_CONT_EXEC_DISCONNECTED,
    
    S2_CONT_EXEC_PULLINGSTARTED,
    S2_CONT_EXEC_PULLINGCOMPLETED,
    
    S2_CONT_EXEC_SPINUPPED,
    
    S2_CONT_EXEC_IGNITED,
    
    S2_CONT_EXEC_TICK,
    
    S2_CONT_EXEC_RESENDED,
    
    S2_CONT_EXEC_COMPILED,
};

#define KEY_WEBSOCKETSERVER_ADDRESS (@"-s")


@interface S2Controller : NSObject

- (id) initWithDict:(NSDictionary * )params withMasterName:(NSString * )masterNameAndId;

- (void) setCompilerSettings:(NSDictionary * )settingsDict;

- (int) state;

- (void) callToMaster:(int)exec withMessageDict:(NSDictionary * )messageDict;
- (int) updatedCount;

- (NSDictionary * )compileChamberControllersMessageBuffer;

- (void) shutDown;
@end
