//
//  Emitter.m
//  S2
//
//  Created by sassembla on 2013/10/19.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "Emitter.h"

#import "TimeMine.h"


@implementation Emitter {
    NSRegularExpression * m_regex_blankLine;
    NSRegularExpression * m_regex_blankLine2;
    NSRegularExpression * m_regex_compileError;
    NSRegularExpression * m_regex_compileFailed;
}

- (id) init {
    if (self = [super init]) {
        m_regex_blankLine = [NSRegularExpression regularExpressionWithPattern:@"[ant:scalac]\n.*" options:0 error:nil];
        m_regex_blankLine2 = [NSRegularExpression regularExpressionWithPattern:@"\n.*" options:0 error:nil];
        m_regex_compileError = [NSRegularExpression regularExpressionWithPattern:@"[ant:scalac]\t(.*)" options:0 error:nil];
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

int i;

/**
 フィルタ、特定のキーワードを抜き出す。
 */
- (NSString * ) filtering:(NSString * )message {
    i++;
    NSLog(@"start %d",i);
    
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/30 19:57:13" withLimitSec:100000 withComment:@"compileFail時は２発で帰る。これは現在のTaskのせいなのかな？"];
    /*
     1)//これはワンセット、この行の何文字目、という。 7の18、とかが出せると良い。
     [ant:scalac] /Users/highvision/S2.fcache/S2Tests/TestResource/sampleProject_gradle/src/main/scala/com/kissaki/TestProject/TestProject_fail.scala:7: error: not found: type Samplaaae2,
     
     
     val b = new Samplaaae2()// typo here
     ^
     //
     
     */
    
    NSLog(@"end");
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
        @"^:compileTestScala.*",
        @"^:jar.*",
        @"^:testClasses.*",
        @"^Tasks to be executed: .*",
        @"^Included projects:.*",
        @"^Starting Build.*",
        @"^Projects loaded. Root project using build file (.*)[.].*",
        @"^Starting Gradle compiler daemon with fork options.*",
        @"^Started Gradle compiler daemon with fork options.*",
        @"^Executing.*",
        @"^:assemble",
        @"^:build",
        
        @"^Process .*",
        
        @"[[]*ant:scalac[]] .*"
        @"  No history is available.",
        @"Starting process.*",
        
        @"^Exception executing.*",
        @"^Compiling ([0-9.*]) Scala sources.*",
        
        @"BUILD FAILED",
        
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
    
    
    //empty line
    {
        NSArray * emptyLine_matches = [m_regex_blankLine matchesInString:message options:0 range:NSMakeRange(0, [message length])];
        
        if (0 < [emptyLine_matches count]) {
            return @"";
        }
        
        NSArray * emptyLine_matches2 = [m_regex_blankLine2 matchesInString:message options:0 range:NSMakeRange(0, [message length])];
        
        if (0 < [emptyLine_matches2 count]) {
            return @"";
        }
    }
    
    NSLog(@":message %@", message);
    
    
    //[ error:]
    {
        NSArray * compileError_matches = [m_regex_compileError matchesInString:message options:0 range:NSMakeRange(0, [message length])];
        for (NSTextCheckingResult * match in compileError_matches) {
            NSString * matchText = [message substringWithRange:[match range]];
        }
        
    }
    
    //[:compileScala FAILED]
    {
        NSArray * compileFailed_matches = [m_regex_compileFailed matchesInString:message options:0 range:NSMakeRange(0, [message length])];
        
        for (NSTextCheckingResult * match in compileFailed_matches) {
            NSLog(@"range range %lu / len %lu", (unsigned long)[match range].location, (unsigned long)[match range].length);
            NSString * matchText = [message substringWithRange:[match range]];
            
            NSLog(@"match: %@", matchText);
            
            NSRange group1 = [match rangeAtIndex:1];
            //        NSRange group2 = [match rangeAtIndex:2];
            NSLog(@"group1: %@", [message substringWithRange:group1]);
            //        NSLog(@"group2: %@", [message substringWithRange:group2]);
            
            
            return @"ss@showAtLog:{\"message\":\"S2 compile failed.\"}->showStatusMessage:{\"message\":\"S2 compile failed.\"}";
        }
    }
    return @"";
}

@end
