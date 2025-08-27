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


#import <Foundation/NSValue.h>
#import <Foundation/NSObjCRuntime.h>

@class NSString;

typedef struct _GrowingDDRange {
    UInt64 location;
    UInt64 length;
} GrowingDDRange;

typedef GrowingDDRange *GrowingDDRangePointer;

NS_INLINE GrowingDDRange GrowingDDMakeRange(UInt64 loc, UInt64 len) {
    GrowingDDRange r;
    r.location = loc;
    r.length = len;
    return r;
}

NS_INLINE UInt64 GrowingDDMaxRange(GrowingDDRange range) {
    return (range.location + range.length);
}

NS_INLINE BOOL GrowingDDLocationInRange(UInt64 loc, GrowingDDRange range) {
    return (loc - range.location < range.length);
}

NS_INLINE BOOL GrowingDDEqualRanges(GrowingDDRange range1, GrowingDDRange range2) {
    return ((range1.location == range2.location) && (range1.length == range2.length));
}

FOUNDATION_EXPORT GrowingDDRange GrowingDDUnionRange(GrowingDDRange range1, GrowingDDRange range2);
FOUNDATION_EXPORT GrowingDDRange GrowingDDIntersectionRange(GrowingDDRange range1, GrowingDDRange range2);
FOUNDATION_EXPORT NSString *GrowingDDStringFromRange(GrowingDDRange range);
FOUNDATION_EXPORT GrowingDDRange GrowingDDRangeFromString(NSString *aString);

NSInteger GrowingDDRangeCompare(GrowingDDRangePointer pGrowingDDRange1, GrowingDDRangePointer pGrowingDDRange2);

@interface NSValue (NSValueGrowingDDRangeExtensions)

+ (NSValue *)valueWithGrowingDDRange:(GrowingDDRange)range;
- (GrowingDDRange)GrowingDDRangeValue;

- (NSInteger)GrowingDDRangeCompare:(NSValue *)GrowingDDRangeValue;

@end
