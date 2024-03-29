//
//  CompileChamberController.h
//  S2
//
//  Created by sassembla on 2013/10/13.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>

#define S2_COMPILECHAMBERCONT   (@"S2_COMPILECHAMBERCONT")

#define COMPILECHAMBERCONT_BUFFFERED_MESSAGETYPE    (@"COMPILECHAMBERCONT_BUFFFERED_MESSAGETYPE")

enum S2_COMPILECHAMBERCONT_EXEC {
    S2_COMPILECHAMBERCONT_EXEC_INITIALIZE,
    
    S2_COMPILECHAMBERCONT_EXEC_POOL,
    
    S2_COMPILECHAMBERCONT_EXEC_INPUT,
    S2_COMPILECHAMBERCONT_EXEC_COMPILE,
    
    S2_COMPILECHAMBERCONT_EXEC_CAHMBERSPINUPPED,
    
    S2_COMPILECHAMBERCONT_EXEC_CHAMBER_IGNITED,
    S2_COMPILECHAMBERCONT_EXEC_CHAMBER_ABORTED,
    
    S2_COMPILECHAMBERCONT_EXEC_ALLCHAMBERS_FILLED,
    
    S2_COMPILECHAMBERCONT_EXEC_OUTPUT,
    
    S2_COMPILECHAMBERCONT_EXEC_RESEND,
    S2_COMPILECHAMBERCONT_EXEC_MESSAGEBUFFER,
    
    S2_COMPILECHAMBERCONT_EXEC_CHAMBER_COMPILED,
};

#define S2_COMPILECHAMBERCONT_SETTINGRECEIVER (@"S2_COMPILECHAMBERCONT_SETTINGRECEIVER")




@interface CompileChamberController : NSObject

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId;

- (void) readyChamber:(int)count;

- (NSArray * ) spinuppingChambers;
- (NSArray * ) spinuppedChambers;
- (NSArray * ) compilingChambers;

- (void) changeChamberStatus:(NSString * )chamberId to:(NSString * )state;
- (NSString * ) igniteIdleChamber:(NSString * )compileBasePath;
- (void) setChamberPriorityFirst:(NSString * )chamberId;

- (void) bufferMessage:(NSDictionary * )messageDict withType:(NSNumber * )type to:(NSString * )chamberId;
- (void) resendFrom:(int)index length:(int)len;

- (void) close;

@end
