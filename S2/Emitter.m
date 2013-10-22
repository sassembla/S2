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
    NSRegularExpression * m_regex_compileFailed;
}

- (id) init {
    if (self = [super init]) {
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
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/19 13:58:04" withLimitSec:10000 withComment:@"直にラインを光らせる処理とか、、は、ちょっとあとで。負荷がかかるけどフィルタを流す。ss@つけるとか。上っ面の処理を施す。キーが増える予感がする。その場合は分けるか。typeを持つ。"];
    
    return message;
}

- (void) filtering:(NSString * )message {
    
    /*
     1)//これはワンセット、この行の何文字目、という。 7の18、とかが出せると良い。
     [ant:scalac] /Users/highvision/S2.fcache/S2Tests/TestResource/sampleProject_gradle/src/main/scala/com/kissaki/TestProject/TestProject_fail.scala:7: error: not found: type Samplaaae2,
     
     
     val b = new Samplaaae2()// typo here
     ^
     //
     
     */
    [TimeMine setTimeMineLocalizedFormat:@"2013/10/23 1:49:26" withLimitSec:10000 withComment:@"プライオリティが0でなければ出ない、みたいなのが必要。"];
    
    
    //:compileScala FAILED
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

}

@end
