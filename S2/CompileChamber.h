//
//  CompileChamber.h
//  S2
//
//  Created by sassembla on 2013/10/13.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>

#define S2_COMPILECHAMBER   (@"S2_COMPILECHAMBER")


enum S2_COMPILECHAMBER_EXEC {
    S2_COMPILECHAMBER_EXEC_SPINUP,
    S2_COMPILECHAMBER_EXEC_SPINUP_WITH_ASYNC,
    S2_COMPILECHAMBER_EXEC_SPINUPPED,
    S2_COMPILECHAMBER_EXEC_IGNITE,
    S2_COMPILECHAMBER_EXEC_IGNITED,
    S2_COMPILECHAMBER_EXEC_COMPILED,
    S2_COMPILECHAMBER_EXEC_ABORTED,
    
    S2_COMPILECHAMBER_EXEC_TICK,
    
    S2_COMPILECHAMBER_EXEC_PURGE,
};



#define STATE_STR_ARRAY (@[@"STATE_SPINUPPING", @"STATE_SPINUPPED", @"STATE_COMPILING", @"STATE_COMPILE_ABORTED", @"STATE_COMPILE_FAILED", @"STATE_COMPILED", @"STATE_ABORTED"])

enum STATE {
    STATE_SPINUPPING,
    STATE_SPINUPPED,
    STATE_COMPILING,
    STATE_COMPILE_ABORTED,
    STATE_COMPILE_FAILED,
    STATE_COMPILED,
    STATE_ABORTED
};



@interface CompileChamber : NSObject

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId;

- (NSString * ) state;
- (NSString * ) chamberId;

- (BOOL) isCompiling;

- (void) ignite:(NSString * )compileBasePath withCodes:(NSDictionary * )idsAndContents;
- (void) abort;


- (void) close;

@end
