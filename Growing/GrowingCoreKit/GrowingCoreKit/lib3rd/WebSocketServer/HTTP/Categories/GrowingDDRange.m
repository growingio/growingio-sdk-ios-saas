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


#import "GrowingDDRange.h"
#import "GrowingDDNumber.h"

GrowingDDRange GrowingDDUnionRange(GrowingDDRange range1, GrowingDDRange range2)
{
	GrowingDDRange result;
	
	result.location = MIN(range1.location, range2.location);
	result.length   = MAX(GrowingDDMaxRange(range1), GrowingDDMaxRange(range2)) - result.location;
	
	return result;
}

GrowingDDRange GrowingDDIntersectionRange(GrowingDDRange range1, GrowingDDRange range2)
{
	GrowingDDRange result;
	
	if((GrowingDDMaxRange(range1) < range2.location) || (GrowingDDMaxRange(range2) < range1.location))
	{
		return GrowingDDMakeRange(0, 0);
	}
	
	result.location = MAX(range1.location, range2.location);
	result.length   = MIN(GrowingDDMaxRange(range1), GrowingDDMaxRange(range2)) - result.location;
	
	return result;
}

NSString *GrowingDDStringFromRange(GrowingDDRange range)
{
	return [NSString stringWithFormat:@"{%qu, %qu}", range.location, range.length];
}

GrowingDDRange GrowingDDRangeFromString(NSString *aString)
{
	GrowingDDRange result = GrowingDDMakeRange(0, 0);
	
	
	NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"+0123456789"];
	
	NSScanner *scanner = [NSScanner scannerWithString:aString];
	[scanner setCharactersToBeSkipped:[cset invertedSet]];
	
	NSString *str1 = nil;
	NSString *str2 = nil;
	
	BOOL found1 = [scanner scanCharactersFromSet:cset intoString:&str1];
	BOOL found2 = [scanner scanCharactersFromSet:cset intoString:&str2];
	
	if(found1) [NSNumber growing_parseString:str1 intoUInt64:&result.location];
	if(found2) [NSNumber growing_parseString:str2 intoUInt64:&result.length];
	
	return result;
}

NSInteger GrowingDDRangeCompare(GrowingDDRangePointer pGrowingDDRange1, GrowingDDRangePointer pGrowingDDRange2)
{
	
	
	
	
	if(pGrowingDDRange1->location < pGrowingDDRange2->location)
	{
		return NSOrderedAscending;
	}
	if(pGrowingDDRange1->location > pGrowingDDRange2->location)
	{
		return NSOrderedDescending;
	}
	if(pGrowingDDRange1->length < pGrowingDDRange2->length)
	{
		return NSOrderedAscending;
	}
	if(pGrowingDDRange1->length > pGrowingDDRange2->length)
	{
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

@implementation NSValue (NSValueGrowingDDRangeExtensions)

+ (NSValue *)valueWithGrowingDDRange:(GrowingDDRange)range
{
	return [NSValue valueWithBytes:&range objCType:@encode(GrowingDDRange)];
}

- (GrowingDDRange)GrowingDDRangeValue
{
	GrowingDDRange result;
	[self getValue:&result];
	return result;
}

- (NSInteger)GrowingDDRangeCompare:(NSValue *)other
{
	GrowingDDRange r1 = [self GrowingDDRangeValue];
	GrowingDDRange r2 = [other GrowingDDRangeValue];
	
	return GrowingDDRangeCompare(&r1, &r2);
}

@end
