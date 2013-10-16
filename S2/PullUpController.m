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
            
        // 内容のセット
        case PULLUPCONT_LISTED:{
            NSAssert(dict[@"listOfSources"], @"listOfSources required");
            
            
            NSString * keyAndListOfSourcesStr = dict[@"listOfSources"];
            
            // keyデリミタvalueデリミタ...ってなってるので、デリミタで割る。
            NSArray * keyAndListOfSourcesArray = [keyAndListOfSourcesStr componentsSeparatedByString:KEY_LISTED_DELIM];

            NSRange theRange;
            
            theRange.location = 1;
            theRange.length = [keyAndListOfSourcesArray count]-1;
            NSArray * listOfSourcesArray = [keyAndListOfSourcesArray subarrayWithRange:theRange];
            
            [self listed:listOfSourcesArray];
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
    NSAssert(0 < [sourcesPathArray count], @"empty sourcesPathArray.");
    
    // 特定のカウントずつpullする
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/16 12:08:16" withLimitSec:100000 withComment:@"とりあえず全部Pullしてたが100とかいくと不味くね？ リミッターをつけて、そのカウンタ分だけ回して、その数字を減らすように改造する、という必要があるかどうか。"];
    
    // renew
    m_pullingIdList = [[NSMutableArray alloc]init];
    
    NSMutableDictionary * currentPullingDict = [[NSMutableDictionary alloc]init];
    for (NSString * pullingPath in sourcesPathArray) {
        NSString * pullingId = [KSMessenger generateMID];
        
        [m_pullingIdList addObject:pullingId];
        
        [messenger callParent:PULLUPCONT_PULLING,
         [messenger tag:@"sourcePath" val:pullingPath],
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
