//
//  Emitter.m
//  S2
//
//  Created by sassembla on 2013/10/19.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "Emitter.h"

#import "TimeMine.h"

#define KEY_STACKTYPE   (@"KEY_STACKTYPE")
#define KEY_STACKLIMIT  (@"KEY_STACKLIMIT")

// defines of stack type
#define STACKTYPE_ERRORLINES        (@"STACKTYPE_ERRORLINES")
#define STACKTYPE_ERRORLINES_ZINC   (@"STACKTYPE_ERRORLINES_ZINC")


#define STRKEY_UPPER    (@"^")


@implementation Emitter {
    NSRegularExpression * m_regex_antscala;
    NSRegularExpression * m_regex_antscalaError;
    NSRegularExpression * m_regex_compileSucceeded;
    NSRegularExpression * m_regex_compileFailed;
    
    NSRegularExpression * m_regex_zincError;
    
    
    NSMutableDictionary * m_stackDict;
}

- (id) init {
    if (self = [super init]) {
        // gradle
        m_regex_antscala = [NSRegularExpression regularExpressionWithPattern:@".ant:scalac. (.*)" options:0 error:nil];
        m_regex_antscalaError = [NSRegularExpression regularExpressionWithPattern:@".ant:scalac. (.*):([0-9].*): error: (.*)" options:0 error:nil];
        m_regex_compileSucceeded = [NSRegularExpression regularExpressionWithPattern:@"^BUILD SUCCESSFUL.*" options:0 error:nil];
        m_regex_compileFailed = [NSRegularExpression regularExpressionWithPattern:@"^BUILD FAILED" options:0 error:nil];
        
        // gradle + zinc
        m_regex_zincError = [NSRegularExpression regularExpressionWithPattern:@"(.*):([0-9.*]): (.*)" options:0 error:nil];
    }
    return self;
}



- (NSString * ) generatePullMessage:(NSString * )emitId withPath:(NSString * )path {
    NSString * pullMessage = [[NSString alloc]initWithFormat:@"ss@readFileData:{\"path\":\"%@\"}->(data|message)monocastMessage:{\"target\":\"S2Client\",\"message\":\"replace\",\"header\":\"pulled,%@ \"}->showAtLog:{\"message\":\"pulled:%@\"}->showStatusMessage:{\"message\":\"pulled:%@\"}", path, emitId, path, path];

    NSLog(@"pullMessage %@", pullMessage);
    
    return pullMessage;
}

- (NSString * ) generateReadyMessage {
    return @"ss@showAtLog:{\"message\":\"S2 compileChamber spinup over.\"}->showStatusMessage:{\"message\":\"S2 compileChamber spinup over.\"}";
}

/**
 フィルタ、特定のキーワードを抜き出す。
 */
- (NSArray * ) filtering:(NSString * )message withSign:(NSString * )sign {
    NSLog(@"message:%@", message);
    
    // 改行だけなら逃げる
    if ([message isEqualToString:@"\n"]) {
        return nil;
    }
    
    
    // 本来必要ではないが、正規表現のupを見るためのチェックをしよう
    {
//        NSArray * ignoreMessages = @[
//                                     @"^Starting daemon process:.*",
//                                     @"^Connected to the daemon[.].*",
//                                     @"^The client will now receive all logging from the daemon.*",
//                                     @"^Settings evaluated using empty settings script[.].*",
//                                     @"^Evaluating root project.*",
//                                     @"^All projects evaluated[.].*",
//                                     @"^Selected primary task.*",
//                                     @"^Compiling with Ant scalac task[.].*",
//                                     @"^Compiling build file .*",
//                                     @".* Compiling.*",
//                                     @"^An attempt to initialize for well behaving parent process finished.",
//                                     @"^Successfully started process.*",
//
//                                     @"^:classes.*",
//                                     @"^:compileJava.*",
//                                     @"^:compileScala.*",
//                                     @"^:compileTestJava.*",
//                                     @"^:compileTestScala.*",
//                                     @"^:jar.*",
//                                     @"^:testClasses.*",
//                                     @"^:processTestResources.*",
//                                     @"^Tasks to be executed.*",
//                                     @"^Skipping task.*",
//                                     @"^Projects loaded. Root project using build file (.*)[.].*",
//                                     
//                                     @"^Included projects:.*",
//                                     @"^Starting Build.*",
//                                     @"^Starting Gradle compiler daemon with fork options.*",
//                                     @"^Starting Gradle daemon.*",
//                                     @"^Started Gradle compiler daemon with fork options.*",
//                                     @"^Executing.*",
//                                     @"^:assemble",
//                                     @"^:build",@"^:test.*",
//                                     @"^:processResources.*",
//                                     @"^:check.*",
//                                     @"^Received command.*",
//                                     @"^Process .*",
////                                     @"[[]ant:scalac[]] (.*)",
//
//                                     @"  No history is available.",
//                                     @"Starting process.*",
//
//                                     @"^Exception executing.*",
//                                     @"^Compiling ([0-9.*]) Scala sources.*",
//
//                                     @"^Executing build with daemon context:",
//
//                                     @"^file or directory .*",
//
//
//                                     @"^BUILD FAILED",
//                                     @"^BUILD SUCCESSFUL.*",
//                                     @"^Total time: (.*) secs.*",
//
//                                     // zinc error
////                                     @"(.*):([0-9].*): (.*)",
//
//                                     @"^Compiling with Zinc Scala compiler.*",
//                                     @"^FAILURE: Build failed with an exception.*",
//                                     @"^> Compilation failed.*",
//
//
//                                     @"^[*] Try:.*",
//                                     @"^Run with .*",
//                                     @"^[*] What went wrong:.*",
//
//                                     @"^Stopping [0-9].* Gradle compiler daemon[(]s[)].*",
//                                     @"^Stopped [0-9].* Gradle compiler daemon[(]s[)].*",
//                                     @"^Execution failed for task.*",
//                                     @"^> Compile failed with.*",
//                                     
//                                     @"empty"
//                                     ];
        
        /*
         [ant:scalac] /Users/highvision/Desktop/S2/S2Tests/TestResource/sampleProject_gradle/src/main/scala/com/kissaki/TestProject/TestProject_fail.scala:1: error: TestProject is already defined as object TestProject

         */
        
//        for (NSString * ignoreTarget in ignoreMessages) {
//            NSRegularExpression * e = [[NSRegularExpression alloc]initWithPattern:ignoreTarget options:0 error:nil];
//            NSArray * result = [e matchesInString:message options:0 range:NSMakeRange(0, [message length])];
//            
//            if ([result count]) {
//                return nil;
//            }
//        }
        
    }
    
    // gradle series
    {
        // gradle compile succeeded
        {
            // @"^BUILD SUCCESSFUL.*"
            {
                NSArray * re = [m_regex_compileSucceeded matchesInString:message options:0 range:NSMakeRange(0, [message length])];
                for (NSTextCheckingResult * match in re) {
                    NSDictionary * dict = @{@"message":@"S2 compile succeeded."};
                    return @[sign, dict];
                }
            }
        }
        
        // gradle compile error
        {
            // antscala error
            // [ant:scalac] /Users/highvision/S2.fcache/S2Tests/TestResource/sampleProject_gradle/src/main/scala/com/kissaki/TestProject/TestProject_fail.scala:7: error: not found: type Samplaaae2
            {
                NSArray * re = [m_regex_antscalaError matchesInString:message options:0 range:NSMakeRange(0, [message length])];
                for (NSTextCheckingResult * match in re) {
                    NSString * filePath = [message substringWithRange:[match rangeAtIndex:1]];
                    NSString * line = [message substringWithRange:[match rangeAtIndex:2]];
                    NSString * reason = [message substringWithRange:[match rangeAtIndex:3]];
                    
                    NSDictionary * dict = @{@"filePath":filePath,
                                            @"line":line,
                                            @"reason":reason};
                    
                    [self stack:dict withType:STACKTYPE_ERRORLINES withLimit:@2];
                    return nil;
                }
                
                if ([m_stackDict[KEY_STACKTYPE] isEqualToString:STACKTYPE_ERRORLINES]) {
                    NSArray * re2 = [m_regex_antscala matchesInString:message options:0 range:NSMakeRange(0, [message length])];
                    
                    // 残りの行の数で対応を変える
                    switch ([self countdown:STACKTYPE_ERRORLINES]) {
                        case 1:{
                            for (NSTextCheckingResult * match in re2) {
                                return nil;
                            }
                            break;
                        }
                        case 0:{
                            for (NSTextCheckingResult * match in re2) {
                                NSString * markerPosStr = [message substringWithRange:[match rangeAtIndex:1]];
                                //markerPosStr ^までの長さを測る
                                NSRange range = [markerPosStr rangeOfString:STRKEY_UPPER];
                                NSUInteger index = range.location;
                                NSDictionary * dict = @{@"index":[[NSString alloc]initWithFormat:@"%lu", (unsigned long)index]};
                                [self append:dict];
                                
                                NSDictionary * result = [self flush];
                                
                                return @[@"appendRegion", result];
                            }
                            break;
                        }
                            
                        default:
                            break;
                    }
                }
            }
            
            
            // gradleでのコンパイル失敗
            {
                NSArray * re = [m_regex_compileFailed matchesInString:message options:0 range:NSMakeRange(0, [message length])];
                
                for (NSTextCheckingResult * match in re) {
                    NSDictionary * dict = @{@"message":@"S2 compile failed."};
                    return @[sign, dict];
                }
            }
        }
    }
    
    // zinc series
    {
        // /Users/highvision/S2.fcache/S2Tests/TestResource/sampleProject_gradle_zinc/src/main/scala/com/kissaki/TestProject/Sample.scala:1:
        {
            NSArray * re = [m_regex_zincError matchesInString:message options:0 range:NSMakeRange(0, [message length])];
            for (NSTextCheckingResult * match in re) {
                NSString * filePath = [message substringWithRange:[match rangeAtIndex:1]];
                NSString * line = [message substringWithRange:[match rangeAtIndex:2]];
                NSString * reason = [message substringWithRange:[match rangeAtIndex:3]];
                
                NSDictionary * dict = @{@"filePath":filePath,
                                        @"line":line,
                                        @"reason":reason};
                
                [self stack:dict withType:STACKTYPE_ERRORLINES_ZINC withLimit:@2];
                return nil;
            }
            
            if ([m_stackDict[KEY_STACKTYPE] isEqualToString:STACKTYPE_ERRORLINES_ZINC]) {
                // 残りの行の数で対応を変える
                switch ([self countdown:STACKTYPE_ERRORLINES_ZINC]) {
                    case 1:{
                        return nil;
                    }
                    case 0:{
                        //markerPosStr ^までの長さを測る
                        NSRange range = [message rangeOfString:STRKEY_UPPER];
                        NSUInteger index = range.location;
                        NSDictionary * dict = @{@"index":[[NSString alloc]initWithFormat:@"%lu", (unsigned long)index]};
                        [self append:dict];
                        
                        NSDictionary * result = [self flush];
                        return @[@"appendRegion", result];
                    }
                        
                    default:
                        break;
                }
            }
            
            
        }
    }
    
    return nil;
}


/**
 emitterごとのstackシステム
 多重にネストすることを考慮しない。一つだけのキーを持つ。
 */
- (void) stack:(NSDictionary * )dict withType:(NSString * )type withLimit:(NSNumber * )count {
    m_stackDict = [[NSMutableDictionary alloc]initWithDictionary:dict];
    [m_stackDict setValue:type forKey:KEY_STACKTYPE];
    [m_stackDict setValue:count forKey:KEY_STACKLIMIT];
}

- (void) append:(NSDictionary * )dict {
    for (NSString * key in [dict allKeys]) {
        [m_stackDict setValue:[[NSString alloc]initWithString:dict[key]] forKey:key];
    }
}

- (int) countdown:(NSString * )type {
    if (m_stackDict && [m_stackDict[KEY_STACKTYPE] isEqualToString:type]) {
        int limit = [m_stackDict[KEY_STACKLIMIT] intValue];
        limit--;
        
        // update
        [m_stackDict setValue:[NSNumber numberWithInt:limit] forKey:KEY_STACKLIMIT];
        
        return limit;
    }
    return -1;
}


- (NSDictionary * ) flush {
    [m_stackDict removeObjectForKey:KEY_STACKTYPE];
    return m_stackDict;
}


- (NSString * ) generateShowMessage:(NSString * )message {
    return [[NSString alloc]initWithFormat:@"showAtLog:{\"message\":\"%@\"}->showStatusMessage:{\"message\":\"%@\"}", message, message];
}


- (NSString * ) generateMessage:(NSDictionary * )messageParam priority:(int)priority {
    NSAssert(0 <= priority, @"not positive or 0, %d", priority);
    
    if (messageParam[@"reason"] && messageParam[@"filePath"] && messageParam[@"line"]) {
        
        // priorityに応じて表示カラーを変更
        NSString * priorityStr = nil;
        
        switch (priority) {
            case 0:{
                priorityStr = @"keyword";
                break;
            }
            case 1:{
                priorityStr = @"keyword";
                break;
            }
            case 2:{
                priorityStr = @"keyword";
                break;
            }
        }
        
        return [[NSString alloc]initWithFormat:@"appendRegion:{\"line\":\"%@\",\"message\":\"%@\",\"view\":\"%@\",\"condition\":\"%@\"}", messageParam[@"line"], messageParam[@"reason"], messageParam[@"filePath"], priorityStr];
    }
    
    if (messageParam[@"message"]) {
        
        return [self generateShowMessage:messageParam[@"message"]];
    }
    
    return nil;
}


/**
 SublimeSocket用のshowを用意する
 */
- (NSString * ) combineMessages:(NSArray * )messageArray {
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/30 14:38:56" withLimitSec:10000 withComment:@"未完成、arrayにしておいて->でつなぐ。"];
    return nil;
}

@end
