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


#import "GrowingEBApplicationEvent.h"

@implementation GrowingEBApplicationEvent

- (instancetype)initWithData:(NSDictionary *)data lifeType:(GrowingApplication)lifeType
{
    if (self = [super initWithData:data]) {
        _lifeType = lifeType;
    }
    return self;
}

- (instancetype)initWithLifeType:(GrowingApplication)lifeType
{
    if (self = [super initWithData:nil]) {
        _lifeType = lifeType;
    }
    return self;
}

@end
