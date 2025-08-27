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


#import <UIKit/UIKit.h>
#import "FoAspectPrivate.h"

@protocol FoAspectToken <NSObject>
- (void)remove;
@end

@interface foAspectIMPItem : NSObject

@property(nullable) IMP oldIMP;
@property(copy, nonatomic) NSString * _Nullable selName;

@end

@interface NSObject(foAspect)

- (_Nullable id<FoAspectToken>)foAspectAfterSeletorNoAddMethod;
- (_Nullable id<FoAspectToken>)foAspectAfterSeletor;
- (_Nullable id<FoAspectToken>)foAspectBeforeSeletorNoAddMethod;
- (_Nullable id<FoAspectToken>)foAspectBeforeSeletor;

+ (_Nullable id<FoAspectToken>)foAspectAfterSeletorNoAddMethod;
+ (_Nullable id<FoAspectToken>)foAspectAfterSeletor;
+ (_Nullable id<FoAspectToken>)foAspectBeforeSeletorNoAddMethod;
+ (_Nullable id<FoAspectToken>)foAspectBeforeSeletor;

@end
