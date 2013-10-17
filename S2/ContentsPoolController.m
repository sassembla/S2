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
    
    NSString * m_placePath;
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

            [self pool:dict[@"path"] withContents:dict[@"source"]];
            [self drain:dict[@"path"] withContents:dict[@"source"] backTo:notif];
            
            break;
        }
        case S2_CONTENTSPOOLCONT_EXEC_PURGE:{
            [self close];
            break;
        }
    }
}


- (void) pool:(NSString * )path withContents:(NSString * )contents {
    // file outputを行う
}


- (void) drain:(NSString * )index withContents:(NSString * )contents backTo:(NSNotification * )notif {
    if ([index hasSuffix:S2_BASEPATH_SUFFIX]) {
        m_compileBasePath = [[NSString alloc]initWithString:index];
    }
    
    // dictionaryとしてset/update
    [m_contentsDict setValue:contents forKey:index];
    
    
    // 特定箇所にgenerate
    [self generateFiles:@{index:contents} to:@"/Users/highvision/1_36_38"];
    
    
    // そのまま内容を返信 or 何もしない
    if (m_compileBasePath) {
        [messenger callback:notif,
         [messenger tag:@"compileBasePath" val:m_compileBasePath],
         nil];
    } else {
        NSLog(@"basepath not yet appears in:%@", m_contentsDict);
        return;
    }
}


/**
 ファイル作成(メモリ上のものを使う場合は不要)
 */
- (void) generateFiles:(NSDictionary * )pathAndSources to:(NSString * )generateTargetPath {
    
    NSError * error;
    NSFileManager * fMan = [[NSFileManager alloc]init];
    [fMan createDirectoryAtPath:generateTargetPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    //ファイル出力
    for (NSString * path in [pathAndSources allKeys]) {
        NSString * targetPath;
        
        //フォルダ生成
        targetPath = [NSString stringWithFormat:@"%@%@", generateTargetPath, path];
        [fMan createDirectoryAtPath:[targetPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        
        //ファイル生成
        bool result = [fMan createFileAtPath:targetPath contents:[pathAndSources[path] dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        
        if (result) {
            NSLog(@"generated:%@", targetPath);
        } else {
            NSLog(@"fail to generate:%@", targetPath);
        }
        
        NSFileHandle * writeHandle = [NSFileHandle fileHandleForUpdatingAtPath:targetPath];
        [writeHandle writeData:[pathAndSources[path] dataUsingEncoding:NSUTF8StringEncoding]];
    }
}



- (void) close {
    [messenger closeConnection];
}
@end
