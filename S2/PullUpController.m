//
//  PullUpController.m
//  S2
//
//  Created by sassembla on 2013/10/07.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "PullUpController.h"

#import "KSMessenger.h"

#import "TimeMine.h"

@implementation PullUpController {
    KSMessenger * messenger;
    NSMutableArray * m_pullingIdList;
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
        case PULLUPCONT_LISTED:{
            NSAssert(dict[@"listOfSources"], @"listOfSources required");
            
            NSString * listOfSources = dict[@"listOfSources"];
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/08 0:10:44" withLimitSec:1000 withComment:@"arrayの内容セットが終わってない。"];
            
            NSArray * sourcesPathArray = @[];
            
            
            [self listed:sourcesPathArray];
            break;
        }
            
        case PULLUPCONT_PULLED:{
            [TimeMine setTimeMineLocalizedFormat:@"2013/10/08 0:59:19" withLimitSec:0 withComment:@"pullしたのが帰ってきたとこ、作ってない。"];
//            [self pulled:<#(NSString *)#> filePath:<#(NSString *)#> source:<#(NSString *)#>]
            break;
        }
            
    }
}


/**
 listを補完、pullUpContに伝達する
 */
- (NSDictionary * ) listed:(NSArray * )sourcesPathArray {
    // 特定のカウントずつpullする
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/09 9:13:46" withLimitSec:100000 withComment:@"とりあえず全部Pullしてたが100とかいくと不味くね？ リミッターをつけて、そのカウンタ分だけ回して、その数字を減らすように改造する、という必要があるかどうか。"];
    
    // renew
    m_pullingIdList = [[NSMutableArray alloc]init];
    
    NSMutableDictionary * currentPullingDict = [[NSMutableDictionary alloc]init];
    for (NSString * pullingPath in sourcesPathArray) {
        NSString * pullingId = [KSMessenger generateMID];
        
        [m_pullingIdList addObject:pullingId];
        
        [messenger callParent:PULLUPCONT_PULLING,
         [messenger tag:@"path" val:pullingPath],
         [messenger tag:@"connectionId" val:pullingId],
         nil];
        
        [currentPullingDict setValue:pullingId forKey:pullingPath];
    }
    
    return currentPullingDict;
}


/**
 pulledに対応する。
 masterへとpulledのデータを返す。
 */
- (void) pulled:(NSString * )pullingId filePath:(NSString * )path source:(NSString * )source {
    
    // remove
    [m_pullingIdList removeObject:pullingId];
    
    
    [messenger callParent:PULLUPCONT_FROMPULL_UPDATED,
     [messenger tag:@"path" val:path],
     [messenger tag:@"source" val:source],
     nil];
    
    // pull完了通知、compilableになる筈。
    if ([self isCompleted]) {
        [messenger callParent:PULLUPCONT_PULL_COMPLETED,
         nil];
    }
}

- (BOOL) isCompleted {
    if ([m_pullingIdList count] == 0) return true;
    return false;
}


- (void) close {
    [messenger closeConnection];
}


@end
