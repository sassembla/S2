//
//  CompilerSettingController.m
//  S2
//
//  Created by sassembla on 2013/10/31.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import "CompileSettingController.h"

#import "CompileChamber.h"
#import "CompileChamberController.h"

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
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
        case S2_COMPILERSETTINGCONTROLLER_EXEC_SET:{
            NSAssert(dict[@"settingsDict"], @"settingsDict required");
            m_settingsDict = [[NSDictionary alloc]initWithDictionary:dict[@"settingsDict"]];
            
            for (NSString * childName in [[messenger childrenDict] allValues]) {
                [messenger call:childName withExec:S2_COMPILERSETTINGCONTROLLER_EXEC_UPDATED,
                 [messenger tag:@"settingsDict" val:m_settingsDict],
                 nil];
            }
            break;
        }
    }
    
    switch ([messenger execFrom:S2_COMPILECHAMBER_SETTINGRECEIVER viaNotification:notif]) {
        case S2_COMPILECHAMBER_SETTINGRECEIVER_EXEC_GET:{
            
            if (m_settingsDict) {
                [messenger callback:notif,
                 [messenger tag:@"settingsDict" val:m_settingsDict],
                 nil];
            } else {
                // return empty dict as default
                [messenger callback:notif,
                 [messenger tag:@"settingsDict" val:@{}],
                 nil];
            }
            
            break;
        }
    }
}

- (void) close {
    [messenger closeConnection];
}


@end
