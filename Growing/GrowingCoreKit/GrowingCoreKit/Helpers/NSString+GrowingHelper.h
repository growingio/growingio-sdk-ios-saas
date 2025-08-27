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
#import "GrowingGlobal.h"
typedef  NSString*(^growingVisiableNumberStringBlock)(long long number);

@interface NSString (GrowingHelper)

- (NSData*)growingHelper_uft8Data;
- (id)growingHelper_jsonObject;
- (NSDictionary *)growingHelper_dictionaryObject;
- (NSString*)growingHelper_safeSubStringWithLength:(NSInteger)length;
- (UIImage*)growingHelper_imageWithEdge:(UIEdgeInsets)edge;
- (NSString*)growingHelper_stringWithXmlConformed;
- (NSString*)growingHelper_stringWithUrlDecode;
- (NSString*)growingHelper_stringByRemovingSpace;
- (NSString *)growingHelper_sha1;
- (BOOL)growingHelper_matchWildly:(NSString *)wildPattern;
- (BOOL)growingHelper_isLegal;
- (BOOL)growingHelper_isValidU;

- (NSString *)growingHelper_encryptString;

- (BOOL)isValidKey;
- (BOOL)isValidIdentifier;
- (instancetype)initWithJsonObject_growingHelper:(id)obj;

- (void)growingHelper_debugOutput;

+ (NSString *)growingHelper_join:(NSString *)first, ...;

@end
