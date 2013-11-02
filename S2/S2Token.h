//
//  S2Token.h
//  S2
//
//  Created by sassembla on 2013/10/07.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

// defaut server path
#define S2_DEFAULT_ADDR         (@"ws://127/0/0/1:8824")


// S2 specific API triggers
#define S2_TRIGGER_PREFIX_LISTED   (@"listed")
#define S2_TRIGGER_PREFIX_PULLED   (@"pulled")
#define S2_TRIGGER_PREFIX_COMPILE  (@"compile")
#define S2_TRIGGER_PREFIX_UPDATED  (@"updated")


#define TRIGGER_DELIM   (@"@")

#define KEY_LISTED_DELIM    (@",")


#define S2_DEFAULT_CHAMBER_COUNT    (8)
#define S2_DEFAULT_SPINUP_TIME      (0.001)
#define S2_COMPILER_WAIT_TIME       (0.001)
#define S2_RESEND_DEPTH             (2)


#define S2_BASEPATH_SUFFIX          (@"build.gradle")

#define S2_COMPILER_KEYWORDS        (@[@"BUILD SUCCESSFUL", @"Total time: "])

#define S2_FILECACHE_PATH           (@"/Users/highvision/S2.fcache")
