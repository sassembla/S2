//
//  ContentsPoolController.m
//  S2
//
//  Created by sassembla on 2013/10/13.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "ContentsPoolController.h"
#import "KSMessenger.h"

#import "TimeMine.h"

@implementation ContentsPoolController {
    KSMessenger * messenger;
}
- (id) initWithMasterNameAndId:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:S2_CONTENTSPOOLCONT];
        [messenger connectParent:masterNameAndId];
    }
    return self;
}


- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
        case S2_CONTENTSPOOLCONT_EXEC_DRAIN:{
            [self drain:notif];
            break;
        }
    }
}

- (void) drain:(NSNotification * )notif {
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/14 16:41:43" withLimitSec:10000 withComment:@"drain時のパラメータを返す。まるっと渡す"];
    NSDictionary * dict = [[NSDictionary alloc]init];
    
    [messenger callback:notif,
     [messenger tag:@"compileBasePath" val:@"dummy"],
     [messenger tag:@"idsAndContents" val:dict],
     nil];
}


- (void) close {
    [messenger closeConnection];
}
@end
