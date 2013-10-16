//
//  ContentsPoolController.m
//  S2
//
//  Created by sassembla on 2013/10/13.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "ContentsPoolController.h"
#import "KSMessenger.h"

#import "S2Token.h"

#import "TimeMine.h"


@implementation ContentsPoolController {
    KSMessenger * messenger;
    
    NSString * m_compileBasePath;
    NSMutableDictionary * m_contentsDict;
}

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:S2_CONTENTSPOOLCONT];
        [messenger connectParent:masterNameAndId];
        
        m_contentsDict = [[NSMutableDictionary alloc]init];
    }
    return self;
}


- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
        case S2_CONTENTSPOOLCONT_EXEC_DRAIN:{
            NSAssert(dict[@"path"], @"path required");
            NSAssert(dict[@"source"], @"source required");
        
            [self drain:dict[@"path"] withContents:dict[@"source"] backTo:notif];
            break;
        }
        case S2_CONTENTSPOOLCONT_EXEC_PURGE:{
            [self close];
            break;
        }
    }
}


- (void) drain:(NSString * )index withContents:(NSString * )contents backTo:(NSNotification * )notif {
    if ([index hasSuffix:S2_BASEPATH_SUFFIX]) {
        m_compileBasePath = [[NSString alloc]initWithString:index];
    }
    
    // ファイルとしてset/update
    [m_contentsDict setValue:contents forKey:index];
    
    
    // そのまま内容を返信 or 何もしない
    if (m_compileBasePath) {
        [messenger callback:notif,
         [messenger tag:@"compileBasePath" val:m_compileBasePath],
         [messenger tag:@"idsAndContents" val:m_contentsDict],
         nil];
    } else {
        NSLog(@"basepath not yet appears in:%@", m_contentsDict);
        return;
    }
}


- (void) close {
    [messenger closeConnection];
}
@end
