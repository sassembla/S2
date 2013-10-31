//
//  CompileSettingController.h
//  S2
//
//  Created by sassembla on 2013/10/31.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>

#define S2_COMPILERSETTINGCONTROLLER    (@"S2_COMPILERSETTINGCONTROLLER")

enum S2_COMPILERSETTINGCONTROLLER_EXEC {
    S2_COMPILERSETTINGCONTROLLER_EXEC_SET,
};


@interface CompileSettingController : NSObject
- (id) initWithMasterNameAndId:(NSString * )masterNameAndId;
- (void)close;
@end
