//
//  Emitter.h
//  S2
//
//  Created by sassembla on 2013/10/19.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>

enum S2_EMITTER_EXEC {
    S2_EMITTER_EXEC_OUTPUT
};

enum EMITTER_MESSAGE_TYPE {
    EMITTER_MESSAGE_TYPE_CONTROL,
    EMITTER_MESSAGE_TYPE_MESSAGE,
    EMITTER_MESSAGE_TYPE_APPENDREGION,
};



@interface Emitter : NSObject

- (id) init;
- (id) initWithMasterName:(NSString * )masterNameAndId as:(NSString * )name;

- (NSString * ) generatePullMessage:(NSString * )emitId withPath:(NSString * )path;
- (NSString * ) generateMessage:(int)type withParam:(NSDictionary * )messageParam priority:(int)priority;

- (NSString * ) generateReadyMessage;

- (void) filtering:(NSString * )message withChamberId:(NSString * )chamberId;

- (NSString * ) combineMessages:(NSArray * )messageArray;

- (void) close;
@end
