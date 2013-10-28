//
//  Emitter.h
//  S2
//
//  Created by sassembla on 2013/10/19.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Emitter : NSObject

- (NSString * ) generatePullMessage:(NSString * )emitId withPath:(NSString * )path;
- (NSString * ) generateReadyMessage;
- (NSString * ) genereateFilteredMessage:(NSString * )message withPriority:(int)priority;

- (NSArray * ) filtering:(NSString * )message withSign:(NSString * )sign;

@end
