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


#import "GrowingLocalCircleModel.h"
#import "GrowingJavascriptCore.h"
#import "GrowingInstance.h"
#import "UIImage+GrowingHelper.h"
#import "NSData+GrowingHelper.h"
#import "GrowingDeviceInfo.h"
#import "GrowingTaggedViews.h"
#import "GrowingUIConfig.h"
#import "GrowingLoginModel.h"
#import "GrowingLoginMenu.h"


@interface GrowingChartViewLine : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) UIColor *color;
@property (nonatomic, retain) NSDictionary *dataDict;
@property (nonatomic, retain) NSArray *dataArr;
@end

@implementation GrowingChartViewLine
@end

@interface GrowingRealTimeData()
@property (nonatomic, retain) NSArray<GrowingChartViewLine*> *allLineData;
@property (nonatomic, retain) NSArray *allTitle;
@end

@implementation GrowingRealTimeData

- (NSString*)nameForLineIndex:(NSInteger)index
{
    return self.allLineData[index].name;
}

- (NSInteger)lineCount
{
    return self.allLineData.count;
}
- (NSInteger)valueCount
{
    return self.allLineData.firstObject.dataArr.count;
}
- (UIColor*)colorForLineIndex:(NSInteger)index
{

    int colors[] = {
        0x19AC9E,
        0xFABE7C,
        0xF88977,
        0xBDD67D,
        0x9EA6DB,
         0x7EBFDD};
    
    
    switch (index) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
            return [GrowingUIConfig colorWithHex:colors[index]];
        default:
            return [GrowingUIConfig colorWithHex:colors[5]];
    }
}
- (NSString*)titleForValueIndex:(NSInteger)vIndex
{
    return self.allTitle[vIndex];
}
- (NSInteger)valueForValueIndex:(NSInteger)vIndex lineIndex:(NSInteger)lineIndex
{
    return [self.allLineData[lineIndex].dataArr[vIndex] integerValue] * FAKE_DATA_AGENT;
}

- (void)buildData:(NSArray*)objects
{
    if (![objects isKindOfClass:[NSArray class]])
    {
        return;
    }
    
    NSMutableDictionary *xIndexDict = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *allLine = [[NSMutableArray alloc] init];
    self.allLineData = allLine;
    for (NSDictionary *lineDict in objects)
    {
        GrowingChartViewLine *line = [[GrowingChartViewLine alloc] init];
        [allLine addObject:line];
        line.name = lineDict[@"label"];
        NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] init];
        line.dataDict = dataDict;
        
        NSArray *dataArr = lineDict[@"data"];
        for (NSDictionary *data in dataArr)
        {
            NSNumber *x = data[@"x"];
            NSNumber *y = data[@"y"];
            
            NSString *xstring = [x stringValue];
            [dataDict setValue:y forKey:xstring];
            [xIndexDict setValue:@YES forKey:xstring];
        }
    }
    
    NSArray *xIndexArr = [xIndexDict.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        if (obj1.longLongValue < obj2.longLongValue)
        {
            return NSOrderedAscending;
        }
        else
        {
            return NSOrderedDescending;
        }
    }];
    
    
    if (xIndexArr.count < 7 && xIndexArr.count > 0)
    {
        NSMutableArray *tempXIndexArr = [[NSMutableArray alloc] initWithArray:xIndexArr];
        long long firstValue = [[xIndexArr firstObject] longLongValue];
        for (NSUInteger i = 0 ; i < 7 - xIndexArr.count ; i ++)
        {
            long long time = firstValue - (24*60*60)*(i+1) * 1000;
            [tempXIndexArr insertObject:[NSString stringWithFormat:@"%lld",time]
                                atIndex:0];
        }
        xIndexArr = tempXIndexArr;
    }
    
    for (GrowingChartViewLine *line in self.allLineData)
    {
        NSMutableArray *values =[[NSMutableArray alloc] init];
        [xIndexArr enumerateObjectsUsingBlock:^(NSString *timestamp, NSUInteger idx, BOOL *stop) {
            NSNumber *n = line.dataDict[timestamp];
            if (!n)
            {
                n = [NSNumber numberWithInteger:0];
            }
            [values addObject:[NSString stringWithFormat:@"%lld", (long long int)[n integerValue]]];
        }];
        
        line.dataArr = values;
        line.dataDict = nil;
    }
    self.allTitle = xIndexArr;
}

@end

@interface GrowingLocalCircleModel()
@property (nonatomic, retain) NSMutableArray *allTagsArray;
@end


@implementation GrowingLocalCircleValueCountItem

@end




@implementation GrowingElement

- (instancetype)copyWithZone:(NSZone *)zone
{
    typeof(self) retVal = [[[self class] allocWithZone:zone] init];
    retVal.page = self.page;
    retVal.pageGroup = self.pageGroup;
    retVal.content = self.content;
    retVal.xpath = self.xpath;
    retVal.patternXPath = self.patternXPath;
    retVal.index = self.index;
    retVal.domain = self.domain;
    retVal.query = self.query;
    retVal.isContentEncoded = self.isContentEncoded;
    return retVal;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.index = [GrowingNodeItemComponent indexNotDefine];
    }
    return self;
}

- (NSString*)elementType
{
    if (self.page
        && self.index == [GrowingNodeItemComponent indexNotDefine]
        && !self.xpath
        && !self.content)
    {
        return @"page";
    }
    else
    {
        return @"elem";
    }
}

- (NSDictionary*)toDict
{
    GrowingElement * element = self;
    NSMutableDictionary *attrDict = [[NSMutableDictionary alloc] init];
    if (element.page)
    {
        attrDict[@"path"] = element.page;
    }
    if (element.pageGroup)
    {
        attrDict[@"pg"] = element.pageGroup;
    }
    if (element.content)
    {
        attrDict[@"content"] = element.content;
    }
    if (element.xpath)
    {
        attrDict[@"xpath"] = element.xpath;
    }
    if (element.patternXPath)
    {
        attrDict[@"patternXPath"] = element.patternXPath;
    }
    if (element.index != [GrowingNodeItemComponent indexNotDefine])
    {
        attrDict[@"index"] = [NSString stringWithFormat:@"%d",(int)element.index];
    }
    if (element.query)
    {
        attrDict[@"query"] = element.query;
    }
    if (element.href)
    {
        attrDict[@"href"] = element.href;
    }
    if (element.domain.length > 0)
    {
        attrDict[@"domain"] = element.domain;
    }
    attrDict[@"isContentEncoded"] = [NSNumber numberWithBool:element.isContentEncoded];

    return attrDict;
}

- (void)fromDict:(NSDictionary *)dict
{
    self.page = dict[@"path"];
    
    self.pageGroup = dict[@"pg"];

    self.content = dict[@"content"];

    NSString *keyIndexString = dict[@"index"];
    self.index = (  keyIndexString.length == 0
                  ? [GrowingNodeItemComponent indexNotDefine]
                  : [keyIndexString integerValue]);

    self.xpath = dict[@"xpath"];
    
    self.patternXPath = dict[@"patternXPath"];

    self.domain = dict[@"d"] ?: dict[@"domain"];

    self.query = dict[@"query"];

    self.href = dict[@"href"];
    
    self.isContentEncoded = [dict[@"isContentEncoded"] boolValue];
}



- (NSString*)domain
{
    if (_domain.length)
    {
        return _domain;
    }
    else
    {
        return [GrowingDeviceInfo currentDeviceInfo].bundleID;
    }
}

- (NSString*)debugDescription
{
    NSString *str = [[NSString alloc] initWithFormat:
                     @"page:%@\n pageGroup:%@\n content:%@\n xpath:%@\n patternXPath:%@\n index:%d\n domain:%@",
                     self.page,
                     self.pageGroup,
                     self.content,
                     self.patternXPath,
                     self.xpath,
                     (int)self.index,
                     self.domain];
    return str;
}

@end




@implementation GrowingTagItem



- (instancetype)initWithDict:(NSDictionary*)dict
{
    self = [super init];
    if (self)
    {




























        
        _name = dict[@"name"];
        _isPageTag = [dict[@"eventType"] isEqualToString:@"page"];
        _tagId = dict[@"id"];
        [super fromDict:dict[@"filter"]];
        if (dict[@"attrs"] != nil)
        {
            _originElement = [[GrowingElement alloc] init];
            [_originElement fromDict:dict[@"attrs"]];
        }
    }
    return self;
}


- (instancetype)initWithName:(NSString *)name
                    andTagId:(NSString *)tagId
                andIsPageTag:(BOOL)isPageTag
            andOriginElement:(GrowingElement *)originElement

{
    self = [super init];
    if (self)
    {
        _name = name;
        _tagId = tagId;
        _isPageTag = isPageTag;
        _originElement = originElement;
    }
    return self;
}

- (instancetype)initPageTagWithName:(NSString *)name
                            andPage:(NSString *)page
                           andQuery:(NSString *)query
{
    self = [super init];
    if (self)
    {
        _name = name;
        _isPageTag = YES;
        super.page = page;
        super.query = query;
    }
    return self;
}

@end


@implementation GrowingLocalCircleModel

- (void)authorityVerification:request
{
    switch (self.modelType) {
        case GrowingModelTypeSDKCircle:
        {
            if ([GrowingLoginModel sdkInstance].token)
            {
                [request setValue:[GrowingLoginModel sdkInstance].token
                    forHTTPHeaderField:@"token"];
            }
            NSString *ai = [GrowingInstance sharedInstance].accountID;
            if (ai.length)
            {
                [request setValue:ai forHTTPHeaderField:@"accountId"];
            }
        }
            break;
        default:
            break;
    }
}

- (BOOL)authorityErrorHandle:(void (^)(BOOL))finishBlock
{
    switch (self.modelType)
    {
        case GrowingModelTypeSDKCircle:
        {
            [GrowingLoginMenu showWithSucceed:^{
                finishBlock(YES);
            } fail:^{
                [[GrowingLoginModel sdkInstance] logout];
                finishBlock(NO);
            }];
        }
            return YES;
        default:
            finishBlock = nil;
            return NO;
    }
}

- (NSArray<GrowingTagItem*> *)cacheTagItems
{
    return self.allTagsArray;
}

- (void)cacheAllTags:(NSArray*)allTags
{
    if (!self.allTagsArray)
    {
        self.allTagsArray = [[NSMutableArray alloc] init];
    }
    [self.allTagsArray removeAllObjects];
    NSArray<GrowingTagItem *> * allTagItems = allTags;
    NSMutableArray<GrowingTagItem *> * patternTagItems = [[NSMutableArray alloc] initWithCapacity:allTagItems.count];
    for (GrowingTagItem * item in allTagItems)
    {
        if (item.xpath
            && [item.xpath rangeOfString:@","].location != NSNotFound
            && [item.xpath rangeOfString:FIELD_SEPARATOR].location == NSNotFound)
        {
            NSArray * xpaths = [item.xpath componentsSeparatedByString:@","];
            for (NSString * xpath in xpaths)
            {
                GrowingTagItem * cItem =[item copy];
                cItem.xpath = xpath;
                [patternTagItems addObject:cItem];
            }
        }
        else
        {
           [patternTagItems addObject:item];
        }
    }
    [self.allTagsArray addObjectsFromArray:patternTagItems];
    [[GrowingTaggedViews shareInstance] setNeedShow];
}

- (void)addNewTag:(NSArray*)tag
{
    if (!self.allTagsArray)
    {
        self.allTagsArray = [[NSMutableArray alloc] init];
    }
    if (tag)
    {
        [self.allTagsArray addObjectsFromArray:tag];
        [[GrowingTaggedViews shareInstance] setNeedShow];
    }
}

- (void)requestAllTagItemsSucceed:(void (^)(NSArray<GrowingTagItem *> *))succeed
                             fail:(void (^)(NSString *))fail
{
    __weak GrowingLocalCircleModel *wself = self;
    [self startTaskWithURL:kGrowingTagApi
                httpMethod:@"GET"
                parameters:nil
                   success:^(NSHTTPURLResponse *httpResponse, NSData *data) {
                       NSArray *all = [data growingHelper_arrayObject];
                       NSMutableArray *allItemDict = [[NSMutableArray alloc] init];
                       for (NSDictionary *dict in all)
                       {
                           if (dict[@"status"] && ![[dict[@"status"] lowercaseString] isEqualToString:@"activated"])
                           {
                               continue;
                           }
                           if (dict[@"platform"] && ![dict[@"platform"] isEqualToString:@"iOS"])
                           {
                               continue;
                           }
                           [allItemDict addObject:dict];
                       }
                       [allItemDict sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
                           CGFloat o1 = [obj1[@"created_at"] floatValue];
                           CGFloat o2 = [obj2[@"created_at"] floatValue];
                           return o1 > o2 ? NSOrderedAscending : NSOrderedDescending;
                       }];
                       
                       
                       NSMutableArray *allTagItems = [[NSMutableArray alloc] initWithCapacity:allItemDict.count];
                       [allItemDict enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                           [allTagItems addObject:[[GrowingTagItem alloc] initWithDict:obj]];
                       }];
                       
                       [wself cacheAllTags:allTagItems];
                       if (succeed)
                       {
                           succeed(allTagItems);
                       }
                   }
                   failure:^(NSHTTPURLResponse *httpResponse, NSData *data, NSError *error) {
                       NSString *string = error.domain;
                       if (!string)
                       {
                           string = [[data growingHelper_dictionaryObject] valueForKey:@"error"];
                       }
                       if (fail)
                       {
                           fail(string);
                       }
                   }];
}



- (void)realTimeViewByElement:(GrowingElement *)element
                      succeed:(GROWNetworkSuccessBlock)succeedBlock
                         fail:(GROWNetworkFailureBlock)failBlock
{
    [self viewTagByAPIPath:kGrowingRealtimeApi
                httpMethod:@"POST"
                 eventType:[element elementType]
                        id:@""
                      name:@""
               origElement:element
             filterElement:element
                 viewImage:nil
               screenImage:nil
                  viewRect:CGRectZero
                   succeed:succeedBlock
                      fail:failBlock];
    
}

- (void)realTimeDataByElement:(GrowingElement *)element
                      succeed:(void (^)(GrowingRealTimeData *))succeedBlock
                         fail:(void (^)(NSString *))failBlock
{
    succeedBlock = [succeedBlock copy];
    failBlock = [failBlock copy];
    [self realTimeViewByElement:element
                        succeed:^(NSHTTPURLResponse *httpResponse, NSData *data) {
                            GrowingRealTimeData *realtimeData = [[GrowingRealTimeData alloc] init];
                            [realtimeData buildData:[data growingHelper_arrayObject]];
                            succeedBlock(realtimeData);
                        }
                           fail:^(NSHTTPURLResponse *httpResponse, NSData *data, NSError *error) {
                               failBlock(@"错误");
                           }];
}

- (void)addOrUpdateTagById:(NSString *)aId
                      name:(NSString *)name
               origElement:(GrowingElement *)origElement
             filterElement:(GrowingElement *)filterElement
                 viewImage:(UIImage *)vImage
               screenImage:(UIImage *)sImage
                  viewRect:(CGRect)vRect
                   succeed:(GROWNetworkSuccessBlock)succeedBlock
                      fail:(GROWNetworkFailureBlock)failBlock
{
    [self viewTagByAPIPath:kGrowingTagApi
                httpMethod:aId.length ? @"PUT" : @"POST"
                 eventType:[origElement elementType]
                        id:aId
                      name:name
               origElement:origElement
             filterElement:filterElement
                 viewImage:vImage
               screenImage:sImage
                  viewRect:vRect
                   succeed:succeedBlock
                      fail:failBlock];
}

- (void)viewTagByAPIPath:(NSString *)apiPath
              httpMethod:(NSString *)httpMethod
               eventType:(NSString *)eventType
                      id:(NSString *)aId
                    name:(NSString *)name
             origElement:(GrowingElement *)origElement
           filterElement:(GrowingElement *)filterElement
               viewImage:(UIImage *)vImage
             screenImage:(UIImage *)sImage
                viewRect:(CGRect)vRect
                 succeed:(GROWNetworkSuccessBlock)succeedBlock
                    fail:(GROWNetworkFailureBlock)failBlock
{
    NSMutableDictionary *origDict = [[ NSMutableDictionary alloc] init];
    origDict[@"ai"] = [GrowingInstance sharedInstance].accountID;
    
    if (aId.length)
    {
        origDict[@"id"] = aId;
    }
    if (name)
    {
        origDict[@"name"] = name;
    }
    origDict[@"platform"] = @"iOS";
    
    
    origDict[@"attrs"] = [origElement toDict];
    if (origDict[@"attrs"][@"domain"] == nil)
    {
        origDict[@"attrs"][@"domain"] = [GrowingDeviceInfo currentDeviceInfo].bundleID;
    }

    origDict[@"filter"] = [filterElement toDict];
    if (origDict[@"filter"][@"domain"] == nil)
    {
        origDict[@"filter"][@"domain"] = [GrowingDeviceInfo currentDeviceInfo].bundleID;
    }
    
    origDict[@"eventType"] = eventType;
    origDict[@"appVersion"] = [GrowingDeviceInfo currentDeviceInfo].appFullVersion;
    origDict[@"sdkVersion"] = [Growing sdkVersion];
    origDict[@"source"] = @"app_circle";
    
    NSMutableDictionary *screenshotDict = [[NSMutableDictionary alloc] init];

    screenshotDict[@"x"] = [@(vRect.origin.x) stringValue];
    screenshotDict[@"y"] = [@(vRect.origin.y) stringValue];
    screenshotDict[@"w"] = [@(vRect.size.width) stringValue];
    screenshotDict[@"h"] = [@(vRect.size.height) stringValue];
    
    NSString *vImgString = vImage ? [vImage growingHelper_Base64JPEG:0.8] : @"MQ==";
    NSString *sImgString = sImage ? [sImage growingHelper_Base64JPEG:0.8] : @"MQ==";
    
    screenshotDict[@"target"] = [@"data:image/jpeg;base64," stringByAppendingString:vImgString];
    screenshotDict[@"viewport"] = [@"data:image/jpeg;base64," stringByAppendingString:sImgString];
    
    origDict[@"screenshot"] = screenshotDict;

    
    
    __weak GrowingLocalCircleModel *wself = self;
    
    [self startTaskWithURL:apiPath
                httpMethod:httpMethod
                parameters:origDict
                   success:^(NSHTTPURLResponse *httpResponse, NSData *data) {
                       NSDictionary *dict = [data growingHelper_dictionaryObject];
                       if (dict)
                       {
                           [wself addNewTag:@[[[GrowingTagItem alloc] initWithDict:dict]]];
                       }
                       
                       if (succeedBlock)
                       {
                           succeedBlock(httpResponse,data);
                       }
                   } failure:^(NSHTTPURLResponse *httpResponse, NSData *data, NSError *error) {
                       if (failBlock)
                       {
                           failBlock(httpResponse,data,error);
                       }
                   }];
}

- (void)fetchXRank:(NSArray<GrowingElement *> *)elements
           succeed:(GROWNetworkSuccessBlock)succeedBlock
              fail:(GROWNetworkFailureBlock)failBlock
{
    if (elements.count == 0)
    {
        if (failBlock)
        {
            failBlock(nil, nil, [NSError errorWithDomain:@"Internal parameter error!" code:0 userInfo:nil]);
        }
        return;
    }
    
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    dict[@"domain"] = elements.firstObject.domain;
    dict[@"path"] = elements.firstObject.page;
    NSMutableArray * xPathArray = [[NSMutableArray alloc] init];
    for (GrowingElement * element in elements)
    {
        [xPathArray addObject:element.xpath];
    }
    dict[@"xpath"] = xPathArray;
    NSInteger nowInMS = (NSUInteger)([[NSDate date] timeIntervalSince1970] * 1000);
    dict[@"range"] = [NSString stringWithFormat:@"abs:%ld,%ld",(long)(nowInMS - (NSUInteger)1000*60*60*24), (long)nowInMS];

    [self startTaskWithURL:kGrowingXRankQuery
                httpMethod:@"POST"
                parameters:dict
          timeoutInSeconds:3
                   success:succeedBlock
                   failure:failBlock];
}

- (void)requestValueCountsByElement:(GrowingElement *)element
                            succeed:(void(^)(NSArray<GrowingLocalCircleValueCountItem *> *))succeedBlock
                               fail:(GROWNetworkFailureBlock)failBlock
{
    if (!element)
    {
        if (failBlock)
        {
            failBlock(nil, nil, [NSError errorWithDomain:@"Internal parameter error!" code:0 userInfo:nil]);
        }
        return;
    }
    
    
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    dict[@"domain"] = element.domain;
    if (element.index != [GrowingNodeItemComponent indexNotDefine] )
    {
        dict[@"index"] = @(element.index);
    }
    dict[@"path"] = element.page;
    dict[@"xpath"] = element.xpath;
    dict[@"v"] = element.content;
    
    
    
    GROWNetworkSuccessBlock succeeBlock = ^(NSHTTPURLResponse *httpResponse, NSData *data) {
        if (succeedBlock)
        {
            NSArray *arr = [data growingHelper_jsonObject];
            
            if ([arr isKindOfClass:[NSArray class]])
            {
                BOOL hasContent = NO;
                NSMutableArray *retArr = [[NSMutableArray alloc] initWithCapacity:arr.count];
                for (NSDictionary *dict in arr)
                {
                    GrowingLocalCircleValueCountItem *item = [[GrowingLocalCircleValueCountItem alloc] init];
                    item.value = dict[@"value"];
                    item.count = [dict[@"rank"] integerValue] * FAKE_DATA_AGENT;
                    [retArr addObject:item];
                    if (hasContent == NO && [item.value isEqualToString:element.content])
                    {
                        hasContent = YES;
                    }
                }
                
                if (hasContent == NO)
                {
                    GrowingLocalCircleValueCountItem *item = [[GrowingLocalCircleValueCountItem alloc] init];
                    item.value = element.content;
                    item.count = 0;
                    [retArr addObject:item];
                }
                succeedBlock(retArr);
            }
            else
            {
                failBlock(nil, nil, [NSError errorWithDomain:@"format error!" code:0 userInfo:nil]);
            }
        }
    };

    
    [self startTaskWithURL:kGrowingVRankQuery
                httpMethod:@"POST"
                parameters:dict
          timeoutInSeconds:3
                   success:succeeBlock
                   failure:failBlock];
    
}

- (void)postWSUrl:(NSString *)url
        pairKey:(NSString *)pairKey
          succeed:(GROWNetworkSuccessBlock)succeedBlock
             fail:(GROWNetworkFailureBlock)failBlock
{
    [self startTaskWithURL:kGrowingWebCircleWSPost
                httpMethod:@"POST"
                parameters:@{@"wsUrl":url, @"pairKey":pairKey}
                   success:succeedBlock
                   failure:failBlock];
}


- (NSString *)getControllerTagedName:(NSString *)vcName
{
    for (GrowingTagItem *item in self.allTagsArray)
    {
        if (item.isPageTag && [item.page isEqualToString:vcName])
        {
            return item.name;
        }
    }
    return nil;
}

- (NSString *)getH5TagedName:(NSDictionary *)pageData
{
    NSString * p = pageData[@"p"];
    NSString * q = pageData[@"q"];
    for (GrowingTagItem *item in self.allTagsArray)
    {
        if (item.isPageTag)
        {
            if (item.page == nil || [item.page isEqualToString:p])
            {
                if (item.query == nil || [item.query isEqualToString:q])
                {
                    return item.name;
                }
            }
        }
    }
    return nil;
}

@end
