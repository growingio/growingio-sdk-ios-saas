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


#import "GrowingEventListItem.h"

@implementation GrowingEventListChildItem

- (instancetype)copyWithZone:(NSZone *)zone
{
    typeof(self) retVal = [[[self class] allocWithZone:zone] init];
    retVal.eventType = self.eventType;
    retVal.element = [self.element copy];
    retVal.tm = [self.tm copy];
    return retVal;
}

@end

@implementation GrowingEventListItem

- (instancetype)init
{
    self = [super init];
    if (self)
    {
    }
    return self;
}

- (void)addMessageWord:(NSString *)word
{
    if (!_message)
    {
        _message = [[NSMutableString alloc] initWithString:word];
    }
    else
    {
        [_message appendFormat:@"%@",word];
    }
}

- (void)addChildItem:(GrowingEventListChildItem *)subItem
{
    if (!_childItems)
    {
        _childItems = [[NSMutableArray alloc] init];
    }
    [_childItems addObject:subItem];
}

- (NSArray<GrowingEventListChildItem*> *)childItems
{
    return _childItems;
}

- (NSString*)debugDescription
{
    return [NSString stringWithFormat:@"%@",self.title];
}

@end
