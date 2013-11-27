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
#define TEST_REPEAT_COUNT_6 (64)

#define TEST_BASE_PATH  (@"./S2Tests/TestResource/")

// list用のダミー
#define TEST_LISTED_1   ([NSString stringWithFormat:@"%@%@", TEST_BASE_PATH, @"codes/TEST_LISTED_1.scala"])
#define TEST_LISTED_2   ([NSString stringWithFormat:@"%@%@", TEST_BASE_PATH, @"codes/TEST_LISTED_2.scala"])


// サンプルのScalaプロジェクト gradle
#define TEST_SAMPLEPROJECTPATH  ([NSString stringWithFormat:@"%@%@", TEST_BASE_PATH, @"sampleProject_gradle/"])

#define TEST_COMPILEBASEPATH    ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH, @"build.gradle"])
#define TEST_SCALA_1            ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH, @"src/main/scala/com/kissaki/TestProject/Sample.scala"])
#define TEST_SCALA_2            ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH, @"src/main/scala/com/kissaki/TestProject/Sample2.scala"])
#define TEST_SCALA_3            ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH, @"src/main/scala/com/kissaki/TestProject/TestProject.scala"])

#define TEST_SCALA_3_FAIL       ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH, @"src/main/scala/com/kissaki/TestProject/TestProject_fail.scala"])


// サンプルのScalaプロジェクト gradle + zinc
#define TEST_SAMPLEPROJECTPATH_ZINC  ([NSString stringWithFormat:@"%@%@", TEST_BASE_PATH, @"sampleProject_gradle_zinc/"])

#define TEST_COMPILEBASEPATH_ZINC    ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH_ZINC, @"build.gradle"])
#define TEST_SCALA_1_ZINC            ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH_ZINC, @"src/main/scala/com/kissaki/TestProject/Sample.scala"])
#define TEST_SCALA_2_ZINC            ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH_ZINC, @"src/main/scala/com/kissaki/TestProject/Sample2.scala"])
#define TEST_SCALA_3_ZINC            ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH_ZINC, @"src/main/scala/com/kissaki/TestProject/TestProject.scala"])

#define TEST_SCALA_3_FAIL_ZINC       ([NSString stringWithFormat:@"%@%@", TEST_SAMPLEPROJECTPATH_ZINC, @"src/main/scala/com/kissaki/TestProject/TestProject_fail.scala"])



#define TEST_TEMPPROJECT_OUTPUT_PATH ([NSString stringWithFormat:@"%@%@", TEST_BASE_PATH, @"tempProject/"])
