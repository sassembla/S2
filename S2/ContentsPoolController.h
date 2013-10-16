//
//  ContentsPoolController.h
//  S2
//
//  Created by sassembla on 2013/10/13.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>

#define S2_CONTENTSPOOLCONT (@"S2_CONTENTSPOOLCONT")

enum S2_CONTENTSPOOLCONT_EXEC {
    S2_CONTENTSPOOLCONT_EXEC_FILL,
    S2_CONTENTSPOOLCONT_EXEC_DRAIN,
    S2_CONTENTSPOOLCONT_EXEC_PURGE,
};
@interface ContentsPoolController : NSObject

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId;

- (void) close;

@end
