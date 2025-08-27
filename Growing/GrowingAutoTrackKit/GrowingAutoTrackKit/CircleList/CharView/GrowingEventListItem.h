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

#import "GrowingEventManager.h"
#import "GrowingLocalCircleModel.h"
#import "GrowingImageCache.h"

@interface GrowingEventListChildItem : NSObject<NSCopying>

@property (nonatomic, assign) GrowingEventType eventType;
@property (nonatomic, retain) GrowingElement *element;
@property (nonatomic, retain) NSNumber *tm;

@end

@interface GrowingEventListItem : NSObject
{
    NSMutableArray *_childItems;
}

@property (nonatomic, assign)   NSTimeInterval   timeInterval;

@property (nonatomic, copy)     NSString            *title;
@property (nonatomic, readonly) NSMutableString     *message;





@property (nonatomic, retain) GrowingImageCacheImage *cacheImage;

@property (nonatomic, assign)   GrowingEventType    eventType;

@property (nonatomic, readonly) NSArray<GrowingEventListChildItem*> *childItems;

- (void)addChildItem:(GrowingEventListChildItem*)subItem;
- (void)addMessageWord:(NSString*)word;

@end
