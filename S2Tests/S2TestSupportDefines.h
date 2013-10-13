//
//  S2TestSupportDefines.h
//  S2
//
//  Created by sassembla on 2013/10/07.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//

#define TEST_BASE_PATH  (@"./S2Tests/TestResource/")

// list用のダミー
#define TEST_LISTED_1   ([NSString stringWithFormat:@"%@%@", TEST_BASE_PATH, @"codes/TEST_LISTED_1.txt"])
#define TEST_LISTED_2   ([NSString stringWithFormat:@"%@%@", TEST_BASE_PATH, @"codes/TEST_LISTED_2.txt"])



// サンプルのScalaプロジェクト
#define TEST_SAMPLEPROJECTPATH  ([NSString stringWithFormat:@"%@%@", TEST_BASE_PATH, @"sampleProject/")

#define TEST_COMPILEBASEPATH    ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH, @"build.gradle")
#define TEST_SCALA_1            ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH, @"build.gradle")
