//
//  Emitter.h
//  S2
//
//  Created by sassembla on 2013/10/19.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>


enum EMITTER_MESSAGE_TYPE {
    EMITTER_MESSAGE_TYPE_CONTROL,
    EMITTER_MESSAGE_TYPE_MESSAGE,
    EMITTER_MESSAGE_TYPE_APPENDREGION,
};



@interface Emitter : NSObject

- (NSString * ) generatePullMessage:(NSString * )emitId withPath:(NSString * )path;
- (NSString * ) generateMessage:(int)type withParam:(NSDictionary * )messageParam priority:(int)priority;

- (NSString * ) generateReadyMessage;

- (NSArray * ) filtering:(NSString * )message;

- (NSString * ) combineMessages:(NSArray * )messageArray;
@end
