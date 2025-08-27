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


#import "GrowingHeatMapModel.h"
#import "GrowingDeviceInfo.h"
#import "GrowingInstance.h"
#import "NSData+GrowingHelper.h"
#import "NSDictionary+GrowingHelper.h"
#import "GrowingLoginModel.h"
#import "GrowingLoginMenu.h"

@implementation GrowingHeatMapModelItem
- (NSString*)description
{
    return
    [NSString stringWithFormat:@"<v:%@ , x:%@ , idx:%@ , percent:%f , count:%d , brightLv:%f>",
                                self.content,
                                self.xpath,
                                self.index,
                                self.percent,
                                (int)self.count,
                                self.brightLevel];
}
@end

@implementation GrowingHeatMapModel

- (void)authorityVerification:(NSMutableURLRequest *)request
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

- (void)requestDataByPageName:(NSString *)pageName succeed:(void (^)(NSArray<GrowingHeatMapModelItem *> *))succeed fail:(void (^)(NSString *))fail
{
    NSMutableDictionary *requestDict = [[NSMutableDictionary alloc] init];
    requestDict[@"domain"] = [GrowingDeviceInfo currentDeviceInfo].bundleID;
    requestDict[@"path"] = pageName;
    requestDict[@"beginTime"] = GROWGetTimestampFromTimeInterval([[NSDate date] timeIntervalSince1970] - 24 * 60 * 60 *3);
    requestDict[@"endTime"] = GROWGetTimestamp();
    requestDict[@"metric"] = @"clck";
    requestDict[@"withIndex"] = [NSNumber numberWithBool:YES];
    
    succeed = [succeed copy];
    fail = [fail copy];
    
    [self startTaskWithURL:kGrowingHeatMap
                httpMethod:@"POST"
                parameters:requestDict
                   success:^(NSHTTPURLResponse *httpResponse, NSData *data) {
                       NSMutableArray *heatMaps = [[NSMutableArray alloc] init];
                       
                       NSArray *dicts = [[data growingHelper_dictionaryObject] valueForKey:@"data"];
                       CGFloat maxPercent = 0;
                       for (NSDictionary *dict in dicts)
                       {
                           NSArray *items = dict[@"items"];
                           for (NSDictionary *item in items)
                           {
                               GrowingHeatMapModelItem *heatMap = [[GrowingHeatMapModelItem alloc] init];
                               
                               
                               heatMap.xpath = dict[@"x"];
                               NSString *content = dict[@"v"];
                               if (content.length)
                               {
                                   heatMap.content = content;
                               }
                            
                               
                               heatMap.index = [item growingHelper_numberWithKey:@"idx"];
                               
                               
                               heatMap.count = [[item growingHelper_numberWithKey:@"cnt"] integerValue];
                               
                               
                               double percent = [[item growingHelper_numberWithKey:@"percent"] doubleValue];
                               heatMap.percent = percent;
                               maxPercent = MAX(percent, maxPercent);
                               
                               [heatMaps addObject:heatMap];
                           }
                       }
                       
                       for (GrowingHeatMapModelItem *item in heatMaps)
                       {
                           item.brightLevel = item.percent / maxPercent;
                       }
                       
                       succeed(heatMaps);
                       
                   } failure:^(NSHTTPURLResponse *httpResponse, NSData *data, NSError *error) {
                       NSDictionary *dataDict = [data growingHelper_dictionaryObject];
                       NSString *errorString = dataDict[@"reason"];
                       if (!errorString.length)
                       {
                           errorString = error.description;
                       }
                       fail(errorString);
                   }];
}

@end
