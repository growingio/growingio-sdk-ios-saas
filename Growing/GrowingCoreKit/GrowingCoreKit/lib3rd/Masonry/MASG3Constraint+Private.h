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


#import "MASG3Constraint.h"

@protocol MASG3ConstraintDelegate;


@interface MASG3Constraint ()


@property (nonatomic, assign) BOOL updateExisting;


@property (nonatomic, weak) id<MASG3ConstraintDelegate> delegate;


- (void)setLayoutConstantWithValue:(NSValue *)value;

@end


@interface MASG3Constraint (Abstract)


- (MASG3Constraint * (^)(id, NSLayoutRelation))equalToWithRelation;


- (MASG3Constraint *)addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute;

@end


@protocol MASG3ConstraintDelegate <NSObject>


- (void)constraint:(MASG3Constraint *)constraint shouldBeReplacedWithConstraint:(MASG3Constraint *)replacementConstraint;

- (MASG3Constraint *)constraint:(MASG3Constraint *)constraint addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute;

@end
