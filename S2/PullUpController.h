//
//  CompileChamberController.h
//  S2
//
//  Created by sassembla on 2013/10/07.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>

#define S2_PULLUPCONT  (@"S2_PULLUPCONT")

enum PULLUPCONT_EXEC {
    PULLUPCONT_LISTED,
    
    PULLUPCONT_PULLING,
    PULLUPCONT_PULLED,
    
    PULLUPCONT_FROMPULL_UPDATED,
    PULLUPCONT_PULL_COMPLETED
};

@interface PullUpController : NSObject

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId;


- (NSDictionary * ) listed:(NSArray * )sourcesPathArray;
- (void) pulled:(NSString * )pullingId filePath:(NSString * )path source:(NSString * )source;

- (BOOL) isCompleted;

- (void) close;
@end
