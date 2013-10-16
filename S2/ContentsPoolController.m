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
    
    NSString * m_compileBasePath;
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
        case S2_CONTENTSPOOLCONT_EXEC_FILL:{
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/17 0:02:17" withLimitSec:10000 withComment:@"fill要素を考える。テストが先だね。"];
//            [self fill];
            break;
        }
        case S2_CONTENTSPOOLCONT_EXEC_DRAIN:{
            [self drain:notif];
            break;
        }
        case S2_CONTENTSPOOLCONT_EXEC_PURGE:{
            [self close];
            break;
        }
    }
}

- (void) fill {
    
}

- (void) drain:(NSNotification * )notif {
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/16 23:59:31" withLimitSec:10000 withComment:@"ファイルが存在していること、また、特定のBasePathが確定できていること、が条件"];
    
    NSString * compileBasePath = m_compileBasePath;
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
