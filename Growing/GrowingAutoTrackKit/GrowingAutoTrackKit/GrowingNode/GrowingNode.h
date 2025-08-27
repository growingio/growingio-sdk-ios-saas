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
#import <GrowingCoreKit/GrowingCorekit.h>
#import <GrowingAutoTrackKit/GrowingAutoTrackKit.h>
#import "GrowingNodeItem.h"
#import "GrowingNodeProtocol.h"

#define GrowingAddChildNode(...) GrowingAddChildNodeWithReturnBlock(nil, __VA_ARGS__)

#define GrowingAddChildNodeWithReturnBlock(returnBlock, ...)                                                    \
{                                                                                                               \
        id __macro_curNode = metamacro_head(__VA_ARGS__);                                                       \
        if (__macro_curNode && ( !aNode || aNode == __macro_curNode )) {                                        \
            if (childs) {                                                                                       \
                [childs addObject:__macro_curNode];                                                             \
            }                                                                                                   \
            if (paths) {                                                                                        \
                [paths addObject:@[ metamacro_foreach(GrowingNodeForeach, ,metamacro_tail(__VA_ARGS__)) ]];     \
                ((GrowingNodeItemComponent *)[[paths lastObject] lastObject]).userDefinedTag =                  \
                    [__macro_curNode isKindOfClass:[UIView class]]                                              \
                        ? [((UIView *)__macro_curNode) growingAttributesUniqueTag] : nil;                       \
                NSString *accessibilityId = nil;                                                                \
                if ([__macro_curNode isKindOfClass:[UIView class]]) {                                           \
                    accessibilityId = ((UIView *)__macro_curNode).accessibilityIdentifier;                      \
                } else if ([__macro_curNode isKindOfClass:[UIBarItem class]]) {                                 \
                    accessibilityId = ((UIBarItem *)__macro_curNode).accessibilityIdentifier;                   \
                } else if ([__macro_curNode isKindOfClass:[UIImage class]]) {                                   \
                    accessibilityId = ((UIImage *)__macro_curNode).accessibilityIdentifier;                     \
                }                                                                                               \
                ((GrowingNodeItemComponent *)[[paths lastObject] lastObject]).growingAccessibilityID =          \
                    accessibilityId;                                                                            \
            }                                                                                                   \
            if (aNode) {                                                                                        \
                if (returnBlock != nil) {                                                                       \
                    ((void(^)(void))returnBlock)();                                                                 \
                }                                                                                               \
                return;                                                                                         \
            }                                                                                                   \
        }                                                                                                       \
}                                                                                                               \

@interface NSObject(GrowingNode)
@property (nonatomic, assign) BOOL growingNodeIsBadNode;
@end

@class GrowingDullNode;

@protocol GrowingNodeAsyncNativeHandler <NSObject>
@required
- (void)refreshContext;
- (void)highlightElementAtPoint:(CGPoint)point; 
- (void)findNodeAtPoint:(CGPoint)point 
           withCallback:(void(^)(NSArray<GrowingDullNode *> * nodes, NSDictionary * pageData))callback;
- (void)cancelHighlight;
- (void)impressAllChildren;
- (void)getAllNode:(void(^)(NSArray<GrowingDullNode *> * nodes, NSDictionary * pageData))callback;
- (void)setLastPoint:(CGPoint)point;
- (BOOL)isResponsive;
- (void)setShouldDisplayTaggedViews:(BOOL)shouldDisplayTaggedViews;
- (void)setCircledTags:(NSArray *)tags onFinish:(void(^)(void))onFinish;
- (void)getPageInfoWithCallback:(void(^)(NSDictionary * pageData))callback;
@end

@interface GrowingRootNode : NSObject<GrowingNode>
+ (instancetype)rootNode;
@end


@interface GrowingDullNode : NSObject<GrowingNode>
@property (nonatomic, copy, readonly) NSString * growingNodeXPath;
@property (nonatomic, copy, readonly) NSString * growingNodePatternXPath;
@property (nonatomic, assign, readonly) NSInteger growingNodeKeyIndex;
@property (nonatomic, copy, readonly) NSString * growingNodeHyperlink;
@property (nonatomic, copy, readonly) NSString * growingNodeType;
@property (nonatomic, copy, readonly) NSString * growingAttributesInfo;

@property (nonatomic, strong) NSValue *safeAreaInsetsValue;
@property (nonatomic, assign) BOOL isHybridTrackingEditText;


- (instancetype)initWithName:(NSString *)name
                  andContent:(NSString *)content
          andUserInteraction:(BOOL)userInteraction
                    andFrame:(CGRect)frame
                 andKeyIndex:(NSInteger)keyIndex
                    andXPath:(NSString *)xPath
             andPatternXPath:(NSString *)patternXPath
                andHyperlink:(NSString *)hyperlink
                 andNodeType:(NSString *)nodeType
        andNodAttributesInfo:(NSString *)nodeAttributesInfo
      andSafeAreaInsetsValue:(NSValue *)safeAreaInsetsValue
    isHybridTrackingEditText:(BOOL)isHybridTrackingEditText;

@end
