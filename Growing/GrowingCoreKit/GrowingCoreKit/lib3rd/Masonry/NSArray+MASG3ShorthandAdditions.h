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


#import "NSArray+MASG3Additions.h"

#ifdef MASG3_SHORTHAND


@interface NSArray (MASG3ShorthandAdditions)

- (NSArray *)makeConstraints:(void(^)(MASG3ConstraintMaker *make))block;
- (NSArray *)updateConstraints:(void(^)(MASG3ConstraintMaker *make))block;
- (NSArray *)remakeConstraints:(void(^)(MASG3ConstraintMaker *make))block;

@end

@implementation NSArray (MASG3ShorthandAdditions)

- (NSArray *)makeConstraints:(void(^)(MASG3ConstraintMaker *))block {
    return [self masG3_makeConstraints:block];
}

- (NSArray *)updateConstraints:(void(^)(MASG3ConstraintMaker *))block {
    return [self masG3_updateConstraints:block];
}

- (NSArray *)remakeConstraints:(void(^)(MASG3ConstraintMaker *))block {
    return [self masG3_remakeConstraints:block];
}

@end

#endif
