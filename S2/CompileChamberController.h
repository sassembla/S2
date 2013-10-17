//
//  CompileChamberController.h
//  S2
//
//  Created by sassembla on 2013/10/13.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#import <Foundation/Foundation.h>

#define S2_COMPILECHAMBERCONT   (@"S2_COMPILECHAMBERCONT")


enum S2_COMPILECHAMBERCONT_EXEC {
    S2_COMPILECHAMBERCONT_EXEC_INITIALIZE,
    S2_COMPILECHAMBERCONT_EXEC_INPUT,
    
    S2_COMPILECHAMBERCONT_EXEC_CHAMBER_IGNITED,
    S2_COMPILECHAMBERCONT_EXEC_CHAMBER_ABORTED,
    
};


@interface CompileChamberController : NSObject

- (id) initWithMasterNameAndId:(NSString * )masterNameAndId;

- (void) readyChamber:(int)count;

- (NSArray * ) spinuppingChambers;
- (NSArray * ) spinuppedChambers;
- (NSArray * ) ignitingChambers;

- (void) changeChamberStatus:(NSString * )chamberId to:(NSString * )state;
- (NSString * ) igniteIdleChamber:(NSString * )compileBasePath withContents:(NSDictionary * )idsAndContents;

- (void) close;

@end
