//
//  Emitter.m
//  S2
//
//  Created by sassembla on 2013/10/19.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "Emitter.h"
#import "TimeMine.h"

@implementation Emitter

- (NSString * ) generatePullMessage:(NSString * )emitId withPath:(NSString * )path {
    NSString * pullMessage = [[NSString alloc]initWithFormat:@"ss@readFileData:{\"path\":\"%@\"}->(data|message)monocastMessage:{\"target\":\"S2Client\",\"message\":\"replace\",\"header\":\"pulled,%@ \"}->showAtLog:{\"message\":\"pulled:%@\"}->showStatusMessage:{\"message\":\"pulled:%@\"}", path, emitId, path, path];

    NSLog(@"pullMessage %@", pullMessage);
    
    return pullMessage;
}

- (NSString * ) generateReadyMessage {
    return @"ss@showAtLog:{\"message\":\"S2 compileChamber spinup over.\"}->showStatusMessage:{\"message\":\"S2 compileChamber spinup over.\"}";
}


- (NSString * ) genereateFilteredMessage:(NSString * )message withPriority:(int)priority {
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/19 13:58:04" withLimitSec:10000 withComment:@"直にラインを光らせる処理とか、、は、ちょっとあとで。負荷がかかるけどフィルタを流す。"];
    return [NSString stringWithFormat:@"ss@filtering:{\"name\":\"scala\",\"source\":\"%@\"}", message];
//    return message;
}

@end
