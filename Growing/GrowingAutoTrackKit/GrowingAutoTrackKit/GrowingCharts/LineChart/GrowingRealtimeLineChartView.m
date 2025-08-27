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


#import "GrowingRealtimeLineChartView.h"
#import "NSData+GrowingHelper.h"

@interface GrowingRealtimeLineChartView ()

@property (nonatomic, copy) NSString *requestID;

@end

@implementation GrowingRealtimeLineChartView

- (void)loadElement:(GrowingElement *)element
{
    [self setBusy];
    __weak GrowingRealtimeLineChartView *wself = self;
    NSString *uuid = [NSUUID UUID].UUIDString;
    self.requestID = uuid;
    id succeedBlock = ^(GrowingRealTimeData *data)
    {
        if (![wself.requestID isEqualToString:uuid])
        {
            return ;
        }
        wself.data = data;
        if (![wself loadData:data])
        {
            [self setText:@"暂无数据"];
        }
        [wself onLoadFinish:YES];
    };
    
    id failBlock = ^(NSString *error) {
        [wself onLoadFinish:NO];
        [wself loadData:nil];
    };
    
    [[GrowingLocalCircleModel sdkInstance] realTimeDataByElement:element
                                                         succeed:succeedBlock
                                                            fail:failBlock];
}

- (void)onLoadFinish:(BOOL)succeed
{
    self.requestID = nil;
    if (self.onLoadFinish)
    {
        self.onLoadFinish(succeed);
    }
    
    if (!succeed)
    {
        [self setText:@"加载失败"];
    }
}

@end
