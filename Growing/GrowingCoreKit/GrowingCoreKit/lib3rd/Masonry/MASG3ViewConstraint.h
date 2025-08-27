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


#import "MASG3ViewAttribute.h"
#import "MASG3Constraint.h"
#import "MASG3LayoutConstraint.h"
#import "MASG3Utilities.h"


@interface MASG3ViewConstraint : MASG3Constraint <NSCopying>


@property (nonatomic, strong, readonly) MASG3ViewAttribute *firstViewAttribute;


@property (nonatomic, strong, readonly) MASG3ViewAttribute *secondViewAttribute;


- (id)initWithFirstViewAttribute:(MASG3ViewAttribute *)firstViewAttribute;


+ (NSArray *)installedConstraintsForView:(MASG3_VIEW *)view;

@end
