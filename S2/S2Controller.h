//
//  S2Controller.h
//  S2
//
//  Created by sassembla on 2013/09/22.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>


#define S2_MASTER   (@"S2_MASTER")

enum S2_STATE {
    STATE_NONE,
    STATE_IGNITED,
    STATE_CONNECTED
};

#define KEY_WEBSOCKETSERVER_ADDRESS (@"-s")


@interface S2Controller : NSObject

- (id) initWithDict:(NSDictionary * )params withMasterName:(NSString * )masterNameAndId;

- (int) state;
- (void) shutDown;
@end
