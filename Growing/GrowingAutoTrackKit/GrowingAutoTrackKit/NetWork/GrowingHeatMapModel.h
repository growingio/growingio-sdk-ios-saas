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


#import <Foundation/Foundation.h>
#import "GrowingBaseModel.h"
#import "GrowingLocalCircleModel.h"

@interface GrowingHeatMapModelItem : NSObject
@property (nonatomic, assign) CGFloat percent;
@property (nonatomic, assign) NSInteger count;

@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *xpath;
@property (nonatomic, retain) NSNumber *index;

@property (nonatomic, assign) CGFloat brightLevel;

@end

@interface GrowingHeatMapModel : GrowingBaseModel

- (void)requestDataByPageName:(NSString*)pageName
                      succeed:(void(^)(NSArray<GrowingHeatMapModelItem*>* items))succeed
                         fail:(void(^)(NSString* error))fail;

@end
