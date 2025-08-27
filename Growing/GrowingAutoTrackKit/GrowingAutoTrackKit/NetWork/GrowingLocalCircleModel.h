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
#import <UIKit/UIKit.h>
#import "GrowingBaseModel.h"
#import "GrowingNode.h"


#define FAKE_DATA_AGENT 1

@interface GrowingElement : NSObject<NSCopying>

@property (nonatomic, copy) NSString *page;
@property (nonatomic, copy) NSString *pageGroup;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *xpath;

@property (nonatomic, assign) NSInteger index;


@property (nonatomic, copy) NSString *patternXPath;
@property (nonatomic, retain) NSString *domain;
@property (nonatomic, retain) NSString *query; 
@property (nonatomic, retain) NSString *href; 


@property (nonatomic, assign) BOOL isContentEncoded;

@property (nonatomic, assign) BOOL isHybridTrackingEditText;


- (void)fromDict:(NSDictionary *)dict;
- (NSDictionary *)toDict;


@property (nonatomic, readonly) GrowingElement *deletePage;
@property (nonatomic, readonly) GrowingElement *deleteContent;
@property (nonatomic, readonly) GrowingElement *deleteIndex;


@end

@interface GrowingLocalCircleValueCountItem : NSObject

@property (nonatomic, copy) NSString *value;
@property (nonatomic, assign) NSInteger count;

@end

@interface GrowingRealTimeData : NSObject

- (NSInteger)lineCount;
- (NSInteger)valueCount;
- (NSString*)nameForLineIndex:(NSInteger)index;
- (UIColor*)colorForLineIndex:(NSInteger)index;
- (NSString*)titleForValueIndex:(NSInteger)vIndex;
- (NSInteger)valueForValueIndex:(NSInteger)vIndex lineIndex:(NSInteger)lineIndex;

@end


@interface GrowingTagItem : GrowingElement

- (instancetype)initWithName:(NSString *)name
                    andTagId:(NSString *)tagId
                andIsPageTag:(BOOL)isPageTag
            andOriginElement:(GrowingElement *)originElement;

- (instancetype)initPageTagWithName:(NSString *)name
                            andPage:(NSString *)page
                           andQuery:(NSString *)query;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *tagId;
@property (nonatomic, readonly) BOOL isPageTag;



@property (nonatomic, retain, readonly) GrowingElement * originElement;

@end

@interface GrowingLocalCircleModel : GrowingBaseModel

@property (nonatomic, readonly) NSArray<GrowingTagItem*> *cacheTagItems;
- (void)requestAllTagItemsSucceed:(void(^)(NSArray<GrowingTagItem*>* items))succeed
                             fail:(void(^)(NSString* errorMsg))fail;

- (NSString *)getControllerTagedName:(NSString *)vcName;
- (NSString *)getH5TagedName:(NSDictionary *)pageData;

- (void)realTimeDataByElement:(GrowingElement*)element
                      succeed:(void(^)(GrowingRealTimeData* realTimeData))succeedBlock
                         fail:(void(^)(NSString* errorMessage))failBlock;


- (void)addOrUpdateTagById:(NSString *)aId
                      name:(NSString *)name
               origElement:(GrowingElement*)origElement
             filterElement:(GrowingElement*)filterElement
                 viewImage:(UIImage *)vImage
               screenImage:(UIImage *)sImage
                  viewRect:(CGRect)vRect
                   succeed:(GROWNetworkSuccessBlock)succeedBlock
                      fail:(GROWNetworkFailureBlock)failBlock;

- (void)requestValueCountsByElement:(GrowingElement *)element
                            succeed:(void(^)(NSArray<GrowingLocalCircleValueCountItem *> *))succeedBlock
                               fail:(GROWNetworkFailureBlock)failBlock;

- (void)postWSUrl:(NSString *)url
          pairKey:(NSString *)pairKey
          succeed:(GROWNetworkSuccessBlock)succeedBlock
             fail:(GROWNetworkFailureBlock)failBlock;

@end
