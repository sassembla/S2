//
//  S2TestSupportDefines.h
//  S2
//
//  Created by sassembla on 2013/10/07.
//  Copyright (c) 2013年 sassembla. All rights reserved.
//
#define TEST_REPEAT_COUNT   (2)
#define TEST_REPEAT_COUNT_2 (4)
#define TEST_REPEAT_COUNT_3 (8)
#define TEST_REPEAT_COUNT_4 (16)
#define TEST_REPEAT_COUNT_5 (32)

#define TEST_BASE_PATH  (@"./S2Tests/TestResource/")

// list用のダミー
#define TEST_LISTED_1   ([NSString stringWithFormat:@"%@%@", TEST_BASE_PATH, @"codes/TEST_LISTED_1.txt"])
#define TEST_LISTED_2   ([NSString stringWithFormat:@"%@%@", TEST_BASE_PATH, @"codes/TEST_LISTED_2.txt"])


// サンプルのScalaプロジェクト No.1
#define TEST_SAMPLEPROJECTPATH  ([NSString stringWithFormat:@"%@%@", TEST_BASE_PATH, @"sampleProject/"])

#define TEST_COMPILEBASEPATH    ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH, @"build.gradle"])
#define TEST_SCALA_1            ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH, @"src/main/scala/com/kissaki/TestProject/Sample.scala"])
#define TEST_SCALA_2            ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH, @"src/main/scala/com/kissaki/TestProject/Sample2.scala"])
#define TEST_SCALA_3            ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH, @"src/main/scala/com/kissaki/TestProject/TestProject.scala"])

///Users/highvision/Desktop/S2/S2Tests/TestResource/sampleProject/src/test/scala/MyTest.scala



#define TEST_TEMPPROJECT_OUTPUT_PATH ([NSString stringWithFormat:@"%@%@", TEST_BASE_PATH, @"tempProject/"])
