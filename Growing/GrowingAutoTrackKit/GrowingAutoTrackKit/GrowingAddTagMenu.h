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
#import "GrowingLocalCircleModel.h"

@interface GrowingSelectViewMenuItem : NSObject

@property (nonatomic, assign)  BOOL     isPage;
@property (nonatomic, assign)  BOOL     isH5Page; 
@property (nonatomic, copy)    NSString *pageTitle;
@property (nonatomic, copy)    NSString *pageQuery;
@property (nonatomic, copy)    NSString *pageDomainH5;
@property (nonatomic, copy)    NSString *pageGroup;

@property (nonatomic, assign)  BOOL     doNotTrack;
@property (nonatomic, assign)  BOOL     isIgnorePage;
@property (nonatomic, assign)  BOOL     isTextInput;
@property (nonatomic, assign)  CGFloat  fontSize;
@property (nonatomic, assign)  BOOL     isInHorizontalTableView;
@property (nonatomic, assign)  BOOL     isWideEnough;
@property (nonatomic, retain)  UIImage  *snapshot;
@property (nonatomic, copy)    NSString *name;
@property (nonatomic, assign)  CGRect   frame;
@property (nonatomic, assign)  BOOL     isH5Tag;
@property (nonatomic, copy)    NSString *href;
@property (nonatomic, assign)  BOOL     isContainer;
@property (nonatomic, copy)    NSString *parentXPath;
@property (nonatomic, copy)    NSArray<GrowingTagItem *> *h5PageCandidates;

@property (nonatomic, assign)  NSInteger visiableIndex;

@property (nonatomic, retain, readonly) GrowingElement *growingElement;
@property (nonatomic, readonly ) NSArray<GrowingSelectViewMenuItem*> *childMenuItems;

- (instancetype)initWithElement:(GrowingElement*)element NS_DESIGNATED_INITIALIZER;

- (void)addChildItem:(GrowingSelectViewMenuItem*)childItem;

- (void)sortChildItemsAccordingToFontSize;

@end


@interface GrowingAddTagMenu : NSObject

+ (void)showFirstOfAllViewMenuItems:(NSArray<GrowingSelectViewMenuItem *> *)allItems
                     andWindowImage:(UIImage *)windowImage;

+ (WKWebView *)sharedWebViewSingleton;

@end
