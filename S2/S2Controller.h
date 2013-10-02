//
//  S2Controller.h
//  S2
//
//  Created by sassembla on 2013/09/22.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>


#define S2_MASTER   (@"S2_MASTER")

enum S2_EXEC {
    EXEC_INITIALIZED,
};


@interface S2Controller : NSObject

- (id) initWithDict:(NSDictionary * )data;

- (void) shutDown;
@end
