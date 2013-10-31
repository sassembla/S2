//
//  CompilerSettingController.m
//  S2
//
//  Created by sassembla on 2013/10/31.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "CompileSettingController.h"
#import "S2Token.h"

#import "CompileChamber.h"

#import "KSMessenger.h"

@implementation CompileSettingController {
    KSMessenger * messenger;
    NSDictionary * m_settingsDict;
}

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:S2_COMPILERSETTINGCONTROLLER];
        [messenger connectParent:masterNameAndId];
    }
    
    return self;
}

- (void) receiver:(NSNotification * )notif {
    switch ([messenger execFrom:S2_COMPILECHAMBER viaNotification:notif]) {
        case S2_COMPILECHAMBER_EXEC_READ_SETTINGS:{
            
            if (m_settingsDict) {
                [messenger callback:notif,
                 [messenger tag:@"settingsDict" val:m_settingsDict],
                 nil];
            } else {
                // return empty dict
                [messenger callback:notif,
                 [messenger tag:@"settingsDict" val:@{}],
                 nil];
            }
            
            break;
        }
            
        default:
            break;
    }
}

- (void) close {
    [messenger closeConnection];
}


@end
