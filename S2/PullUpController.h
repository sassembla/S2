//
//  CompileChamberController.h
//  S2
//
//  Created by sassembla on 2013/10/07.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>

#define S2_PULLUPCONT  (@"S2_PULLUPCONT")

enum S2_PULLUPCONT_EXEC {
    S2_PULLUPCONT_LISTED,
    
    S2_PULLUPCONT_PULLING,
    S2_PULLUPCONT_PULLED,
    
    S2_PULLUPCONT_FROMPULL_UPDATED,
    S2_PULLUPCONT_PULL_COMPLETED
};

@interface PullUpController : NSObject

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId;

- (void) listed:(NSArray * )sourcesPathArray;
- (void) pulled:(NSString * )path source:(NSString * )source;


- (NSDictionary * )pullingPathList;

- (BOOL) isCompleted;

- (void) close;
@end
