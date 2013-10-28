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
#define STACKTYPE_ERRORLINES    (@"STACKTYPE_ERRORLINES")


#define STRKEY_UPPER    (@"^")



@implementation Emitter {
    NSRegularExpression * m_regex_antscala;
    NSRegularExpression * m_regex_antscalaError;
    NSRegularExpression * m_regex_compileSucceeded;
    NSRegularExpression * m_regex_compileError;
    NSRegularExpression * m_regex_compileFailed;
    
    NSMutableDictionary * m_stackDict;
}

- (id) init {
    if (self = [super init]) {
        m_regex_antscala = [NSRegularExpression regularExpressionWithPattern:@".ant:scalac. (.*)" options:0 error:nil];
        m_regex_antscalaError = [NSRegularExpression regularExpressionWithPattern:@".ant:scalac. (.*):([0-9].*): error: (.*)" options:0 error:nil];
        m_regex_compileSucceeded = [NSRegularExpression regularExpressionWithPattern:@"^BUILD SUCCESSFUL.*" options:0 error:nil];
        m_regex_compileError = [NSRegularExpression regularExpressionWithPattern:@"[[]ant:scalac[]](.*)" options:0 error:nil];
        m_regex_compileFailed = [NSRegularExpression regularExpressionWithPattern:@"(:compileScala FAILED)" options:0 error:nil];
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


- (NSString * ) genereateFilteredMessage:(NSString * )message withPriority:(int)priority {
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/30 20:06:45" withLimitSec:100000 withComment:@"直にラインを光らせる処理とか、、は、ちょっとあとで。負荷がかかるけどフィルタを流す。ss@つけるとか。上っ面の処理を施す。キーが増える予感がする。その場合は分けるか。typeを持つ。"];
    
    return message;
}

/**
 フィルタ、特定のキーワードを抜き出す。
 */
- (NSArray * ) filtering:(NSString * )message withSign:(NSString * )sign {
    NSLog(@"message %@", message);
    
    
    // 改行だけなら逃げる
    if ([message isEqualToString:@"\n"]) {
        return nil;
    }
    
    // 改行で始まっているなら最初の改行を取り除く
    if ([message hasPrefix:@"\n"]) {
        return [self filtering:[message substringFromIndex:1] withSign:sign];
    }
    
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/30 19:57:13" withLimitSec:100000 withComment:@"compileFail時は２発で帰る。これは現在のTaskのせいなのかな？"];
    /*
     1)//これはワンセット、この行の何文字目、という。 7の18、とかが出せると良い。
     [ant:scalac] /Users/highvision/S2.fcache/S2Tests/TestResource/sampleProject_gradle/src/main/scala/com/kissaki/TestProject/TestProject_fail.scala:7: error: not found: type Samplaaae2,
     
     
     val b = new Samplaaae2()// typo here
     ^
     //
     
     */
    
    
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/30 19:57:31" withLimitSec:100000 withComment:@"プライオリティが0でなければ出ない、みたいなのが必要。"];
    
    
    // 本来必要ではないが、正規表現のupを見るためのチェックをしよう
    {
        NSArray * ignoreMessages = @[
        @"^Connected to the daemon[.].*",
        @"^The client will now receive all logging from the daemon.*",
        @"^Settings evaluated using empty settings script[.].*",
        @"^Evaluating root project.*",
        @"^All projects evaluated[.].*",
        @"^Selected primary task.*",
        @"^Compiling with Ant scalac task[.].*",
        @"^Compiling build file .*",
        @".* Compiling.*",
        
        
        @"^:classes.*",
        @"^:compileJava.*",
        @"^:compileScala.*",
        @"^:compileTestJava.*",
        @"^:compileTestScala.*",
        @"^:jar.*",
        @"^:testClasses.*",
        @"^:processTestResources.*",
        
        @"^Tasks to be executed.*",
        
        @"^Skipping task.*",
        @"^Projects loaded. Root project using build file (.*)[.].*",
        
        
        @"^Included projects:.*",
        @"^Starting Build.*",
        @"^Starting Gradle compiler daemon with fork options.*",
        @"^Starting Gradle daemon.*",
        @"^Started Gradle compiler daemon with fork options.*",
        @"^Executing.*",
        @"^:assemble",
        @"^:build",
        @"^:test.*",
        @"^:processResources.*",
        @"^:check.*",
        @"^Received command.*",
        
        @"^Process .*",
        
//        @"[[]ant:scalac[]] (.*)",//これで貫通しなくなる。
        
        @"  No history is available.",
        @"Starting process.*",
        
        @"^Exception executing.*",
        @"^Compiling ([0-9.*]) Scala sources.*",
        
        @"^Executing build with daemon context:",
        
        @"^file or directory .*",
        
        
//        @"^BUILD FAILED",
//        @"^BUILD SUCCESSFUL.*",
        @"^Total time: (.*) secs.*",
        
        @"empty"];
        
        /*
         [ant:scalac] /Users/highvision/Desktop/S2/S2Tests/TestResource/sampleProject_gradle/src/main/scala/com/kissaki/TestProject/TestProject_fail.scala:1: error: TestProject is already defined as object TestProject

         */
        
        for (NSString * ignoreTarget in ignoreMessages) {
            NSRegularExpression * e = [[NSRegularExpression alloc]initWithPattern:ignoreTarget options:0 error:nil];
            NSArray * result = [e matchesInString:message options:0 range:NSMakeRange(0, [message length])];
            
            if ([result count]) {
                return nil;
            }
        }
        
    }
    
    
    // @"^BUILD SUCCESSFUL.*"
    {
        NSArray * re = [m_regex_compileSucceeded matchesInString:message options:0 range:NSMakeRange(0, [message length])];
        for (NSTextCheckingResult * match in re) {
            return @[sign, @"BUILD SUCCESSFUL"];
        }
    }
    
    NSLog(@"message is %@", message);
    
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
                        
                        // 表示列を光らせるメッセージを直撃で返す
                        NSString * message = [[NSString alloc] initWithFormat:@"ss@showStatusMessage:{\"message\":\"%@\"}->showAtLog:{\"message\":\"%@\"}->appendRegion:{\"line\":\"%@\",\"message\":\"%@\",\"view\":\"%@\",\"condition\":\"keyword\"}", result[@"reason"], result[@"reason"], result[@"line"], result[@"reason"], result[@"filePath"]];
                        
                        return @[message];
                    }
                    break;
                }
                    
                default:
                    break;
            }
        }
    }
    
    NSLog(@"message 2 is %@", message);
    
    // [:compileScala FAILED]
    {
        NSArray * re = [m_regex_compileFailed matchesInString:message options:0 range:NSMakeRange(0, [message length])];
        
        for (NSTextCheckingResult * match in re) {
            NSLog(@"range range %lu / len %lu", (unsigned long)[match range].location, (unsigned long)[match range].length);
            NSString * matchText = [message substringWithRange:[match range]];
            
            NSLog(@"match: %@", matchText);
            
            NSRange group1 = [match rangeAtIndex:1];
            //        NSRange group2 = [match rangeAtIndex:2];
            NSLog(@"group1: %@", [message substringWithRange:group1]);
            //        NSLog(@"group2: %@", [message substringWithRange:group2]);
            
            return @[@"ss@showAtLog:{\"message\":\"S2 compile failed.\"}->showStatusMessage:{\"message\":\"S2 compile failed.\"}"];
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
    return m_stackDict;
}

@end
