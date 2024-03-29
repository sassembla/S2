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
        case S2_CONTENTSPOOLCONT_EXEC_ADD_DRAIN:{
            NSAssert(dict[@"path"], @"path required");
            NSAssert(dict[@"source"], @"source required");

            [self pool:dict[@"path"] withContents:dict[@"source"]];
            [self drain:dict[@"path"] backTo:notif];
            
            break;
        }
        case S2_CONTENTSPOOLCONT_EXEC_DRAIN:{
            [self drain:dict[@"path"] backTo:notif];
            break;
        }
        case S2_CONTENTSPOOLCONT_EXEC_PURGE:{
            [self close];
            break;
        }
    }
}

/**
 特定箇所にファイルを吐き出す。
 */
- (void) pool:(NSString * )path withContents:(NSString * )contents {
    // 特定箇所にgenerate
    [self generateFileCache:@{path:contents} to:S2_DEFAULT_FILECACHE_PATH];
}


- (void) drain:(NSString * )path backTo:(NSNotification * )notif {
    if ([path hasSuffix:S2_BASEPATH_SUFFIX]) {
        m_compileBasePath = [[NSString alloc]initWithString:[self absoluteCachePath:path toTargetPath:S2_DEFAULT_FILECACHE_PATH]];
    }
    
    // そのまま内容を返信 or 何もしない
    if (m_compileBasePath) {
        [messenger callback:notif,
         [messenger tag:@"compileBasePath" val:m_compileBasePath],
         nil];
    } else {
        NSLog(@"basepath not yet appears, %@", path);
        return;
    }
}

- (NSString * ) absoluteCachePath:(NSString * )path toTargetPath:(NSString * )targetPath {
    NSString * resultPath = nil;
    
    if ([path hasPrefix:@"./"]) resultPath = [[NSString alloc]initWithFormat:@"%@%@", targetPath, [path substringFromIndex:1]];
    else if ([path hasPrefix:@"/"]) resultPath = [[NSString alloc]initWithFormat:@"%@%@", targetPath, path];
    else resultPath = [[NSString alloc]initWithFormat:@"%@/%@", targetPath, path];
    
    return resultPath;
}


/**
 ファイル作成(メモリ上のものを使う場合は不要)
 */
- (void) generateFileCache:(NSDictionary * )pathAndSources to:(NSString * )generateTargetPath {
    
    NSError * error;
    NSFileManager * fMan = [[NSFileManager alloc]init];
    [fMan createDirectoryAtPath:generateTargetPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    //ファイル出力
    for (NSString * path in [pathAndSources allKeys]) {
        
        
        //フォルダ生成
        NSString * targetPath = [self absoluteCachePath:path toTargetPath:generateTargetPath];
        
        [fMan createDirectoryAtPath:[targetPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        
        //ファイル生成
        bool result = [fMan createFileAtPath:targetPath contents:[pathAndSources[path] dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        
        if (result) {
            [TimeMine setTimeMineLocalizedFormat:@"2013/11/30 20:01:06" withLimitSec:100000 withComment:@"pool generated"];
//            NSLog(@":%@", targetPath);
        } else {
            [TimeMine setTimeMineLocalizedFormat:@"2013/11/30 20:01:09" withLimitSec:100000 withComment:@"pool failed to generate"];
//            NSLog(@"fail to generate:%@", targetPath);
        }
        
        NSFileHandle * writeHandle = [NSFileHandle fileHandleForUpdatingAtPath:targetPath];
        [writeHandle writeData:[pathAndSources[path] dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void) deleteFileCache:(NSString * )deleteTargetPath {
    NSError * error;
    NSFileManager * fMan = [[NSFileManager alloc]init];
    [fMan removeItemAtPath:deleteTargetPath error:&error];
}



- (void) close {
    [self deleteFileCache:S2_DEFAULT_FILECACHE_PATH];
    [messenger closeConnection];
}
@end
