//
//  PullUpController.m
//  S2
//
//  Created by sassembla on 2013/10/07.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "PullUpController.h"
#import "S2Token.h"

#import "KSMessenger.h"

#import "TimeMine.h"

@implementation PullUpController {
    KSMessenger * messenger;
    NSMutableDictionary * m_pullingPathDict;
}

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:S2_PULLUPCONT];
        [messenger connectParent:masterNameAndId];
    }
    return self;
}

- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
            
        // 内容のセット
        case S2_PULLUPCONT_LISTED:{
            NSAssert(dict[@"listOfSources"], @"listOfSources required");
            
            [self listed:dict[@"listOfSources"]];
            break;
        }
            
        case S2_PULLUPCONT_PULLED:{
            NSAssert(dict[@"pulledId"], @"pulledId required");
            NSAssert(dict[@"source"], @"source required");
            
            [self pulled:dict[@"pulledId"] source:dict[@"source"]];
            break;
        }
    }
}


/**
 listを補完、pullUpContに伝達する
 */
- (void) listed:(NSArray * )sourcesPathArray {
    NSAssert(0 < [sourcesPathArray count], @"empty sourcesPathArray.");
    
    // 特定のカウントずつpullする
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/30 16:24:50" withLimitSec:100000 withComment:@"とりあえず全部Pullしてたが100とかいくと不味くね？ リミッターをつけて、そのカウンタ分だけ回して、その数字を減らすように改造する、という必要があるかどうか。"];
    
    
    // renew
    m_pullingPathDict = [[NSMutableDictionary alloc]init];
    
    for (NSString * pullingPath in sourcesPathArray) {
        if ([pullingPath hasSuffix:@".gradle"] || [pullingPath hasSuffix:@".scala"]) {
            NSString * pullingId = [KSMessenger generateMID];

            [m_pullingPathDict setValue:pullingPath forKey:pullingId];
            
            [messenger callParent:S2_PULLUPCONT_PULLING,
             [messenger tag:@"pullingId" val:pullingId],
             [messenger tag:@"sourcePath" val:pullingPath],
             nil];
        }
    }
}


/**
 pulledに対応する。
 masterへとpulledのデータを返す。
 */
- (void) pulled:(NSString * )pulledId source:(NSString * )source {
    
    if (m_pullingPathDict[pulledId]) {
        NSString * path = [[NSString alloc] initWithFormat:@"%@", m_pullingPathDict[pulledId]];
        [m_pullingPathDict removeObjectForKey:pulledId];
        
        [messenger callParent:S2_PULLUPCONT_PULLUP,
         [messenger tag:@"path" val:path],
         [messenger tag:@"source" val:source],
         nil];
        
        // pull完了通知、compilableになる筈。
        if ([self isCompleted]) {
            [messenger callParent:S2_PULLUPCONT_PULL_COMPLETED,
             nil];
        }
    } else {
        NSLog(@"no connection id found, ignored. %@", pulledId);
        return;
    }
}

- (NSDictionary * )pullingPathList {
    return m_pullingPathDict;
}


- (BOOL) isCompleted {
    if ([m_pullingPathDict count] == 0) return true;
    return false;
}


- (void) close {
    [messenger closeConnection];
}


@end
