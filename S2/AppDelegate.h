//
//  AppDelegate.h
//  S2
//
//  Created by sassembla on 2013/09/22.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

- (id) initAppDelegateWithParam:(NSDictionary * )dict;

@property (assign) IBOutlet NSWindow *window;

@end
