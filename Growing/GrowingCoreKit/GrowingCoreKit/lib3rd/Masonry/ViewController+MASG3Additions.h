//
//  GrowingAnalytics
//  Copyright (C) 2025 Beijing Yishu Technology Co., Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


#import "MASG3Utilities.h"
#import "MASG3ConstraintMaker.h"
#import "MASG3ViewAttribute.h"

#ifdef MASG3_VIEW_CONTROLLER

@interface MASG3_VIEW_CONTROLLER (MASG3Additions)


@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_topLayoutGuide;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_bottomLayoutGuide;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_topLayoutGuideTop;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_topLayoutGuideBottom;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_bottomLayoutGuideTop;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_bottomLayoutGuideBottom;


@end

#endif
