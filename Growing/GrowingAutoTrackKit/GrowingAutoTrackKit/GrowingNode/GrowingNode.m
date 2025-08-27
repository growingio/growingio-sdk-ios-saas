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


#import "GrowingNode.h"
#import "FoDefineProperty.h"
#import "UIApplication+GrowingHelper.h"
#import "UIApplication+GrowingNode.h"
#import "UIWindow+GrowingNode.h"
#import "UIWindow+Growing.h"
#import "UIViewController+GrowingNode.h"
#import "UIViewController+Growing.h"
#import "UIImage+GrowingHelper.h"


@implementation NSObject(GrowingNode)

static char growingNodeIsBadNodeKey;
- (BOOL)growingNodeIsBadNode
{
    return objc_getAssociatedObject(self, &growingNodeIsBadNodeKey) != nil;
}

- (void)setGrowingNodeIsBadNode:(BOOL)growingNodeIsBadNode
{
    objc_setAssociatedObject(self,
                             &growingNodeIsBadNodeKey,
                             growingNodeIsBadNode ? @"yes" : nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation GrowingRootNode

- (id)growingNodeAttribute:(NSString *)attrbute
{
    return nil;
}

- (id)growingNodeAttribute:(NSString *)attrbute forChild:(id<GrowingNode>)node
{
    return nil;
}

- (UIImage*)growingNodeScreenShot:(UIImage *)fullScreenImage
{
    return nil;
}

- (UIImage*)growingNodeScreenShotWithScale:(CGFloat)maxScale
{
    return nil;
}

+ (instancetype)rootNode
{
    static id node = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        node = [[self alloc] init];
    });
    return node;
}

- (void)growingNodeOutChilds:(NSMutableArray *)childs outPaths:(NSMutableArray *)paths filterChildNode:(id<GrowingNode>)aNode
{
    NSArray *windows = [[UIApplication sharedApplication] growingHelper_allWindowsSortedByWindowLevel];
    UIWindow *mainWindow = [[UIApplication sharedApplication] growingMainWindow];
    
    for (UIWindow *win in windows)
    {
        if (win == mainWindow)
        {
            GrowingAddChildNode(win,
                                (nil));
        }
        else if (win.superview == nil)
        {
            GrowingAddChildNode(win,
                                (NSStringFromClass(win.class),(NSInteger)win.windowLevel));
        }
    }
}

- (void)growingNodeOutContainerChilds:(NSMutableArray *)childs
                             outPaths:(NSMutableArray *)paths
                      filterChildNode:(id<GrowingNode>)aNode
{
    
}




- (id<GrowingNode>)growingNodeParent
{
    return nil;
}

- (BOOL)growingNodeDonotTrack
{
    return NO;
}
- (BOOL)growingNodeDonotTrackImp
{
    return NO;
}

- (BOOL)growingNodeDonotCircle
{
    return NO;
}


- (BOOL)growingNodeUserInteraction
{
    return NO;
}
- (NSString*)growingNodeName
{
    return @"根节点";
}
- (NSString*)growingNodeContent
{
    return nil;
}

- (NSDictionary*)growingNodeDataDict
{
    return [[[[UIApplication sharedApplication] growingMainWindow] growingHook_curViewController] growingNodeDataDict];
}

- (UIWindow*)growingNodeWindow
{
    return nil;
}

- (id<GrowingNode>)growingNodeAttachedInfoNode
{
    return nil;
}

- (CGRect)growingNodeFrame
{
    return CGRectZero;
}

- (void)growingNodeHighLight:(BOOL)highLight
             withBorderColor:(UIColor *)borderColor
          andBackgroundColor:(UIColor *)backgroundColor
{
    
}

- (id<GrowingNodeAsyncNativeHandler>)growingNodeAsyncNativeHandler
{
    return nil;
}

@end

@interface GrowingDullNode ()



@property (nonatomic, weak)   id<GrowingNode> growingNodeParent;
@property (nonatomic, assign) BOOL growingNodeDonotTrack;
@property (nonatomic, assign) BOOL growingNodeDonotTrackImp;
@property (nonatomic, assign) BOOL growingNodeDonotCircle;
@property (nonatomic, assign) BOOL growingNodeUserInteraction;
@property (nonatomic, copy)   NSString * growingNodeName;
@property (nonatomic, copy)   NSString * growingNodeContent;
@property (nonatomic, weak)   NSNumber * growingNodeIndex;
@property (nonatomic, weak)   NSDictionary * growingNodeDataDict;
@property (nonatomic, weak)   UIWindow * growingNodeWindow;
@property (nonatomic, assign) CGRect growingNodeFrame;
@property (nonatomic, weak)   id<GrowingNodeAsyncNativeHandler> growingNodeAsyncNativeHandler;

@property (nonatomic, copy)   NSString * growingNodeXPath;
@property (nonatomic, copy)   NSString * growingNodePatternXPath;
@property (nonatomic, assign) NSInteger growingNodeKeyIndex;
@property (nonatomic, copy) NSString * growingNodeHyperlink;
@property (nonatomic, copy) NSString * growingNodeType;
@property (nonatomic, copy) NSString * growingAttributesInfo;

@end

@implementation GrowingDullNode

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
    isHybridTrackingEditText:(BOOL)isHybridTrackingEditText
{
    self = [super init];
    if (self)
    {
        self.growingNodeParent = nil;
        self.growingNodeDonotTrack = NO;
        self.growingNodeDonotTrackImp = NO;
        self.growingNodeDonotCircle = NO;
        self.growingNodeUserInteraction = userInteraction;
        self.growingNodeName = name;
        self.growingNodeContent = content;
        self.growingNodeIndex = nil;
        self.growingNodeDataDict = nil;
        self.growingNodeWindow = nil;
        self.growingNodeFrame = frame;
        self.growingNodeAsyncNativeHandler = nil;
        self.growingNodeXPath = xPath;
        self.growingNodePatternXPath = patternXPath;
        self.growingNodeKeyIndex = keyIndex;
        self.growingNodeHyperlink = hyperlink;
        self.growingNodeType = nodeType;
        self.growingAttributesInfo = nodeAttributesInfo;
        self.safeAreaInsetsValue = safeAreaInsetsValue;
        self.isHybridTrackingEditText = isHybridTrackingEditText;
    }
    return self;
}

- (void)growingNodeOutContainerChilds:(NSMutableArray*)childs
                             outPaths:(NSMutableArray*)paths
                      filterChildNode:(id<GrowingNode>)aNode
{
    
}

- (void)growingNodeOutChilds:(NSMutableArray*)childs
                    outPaths:(NSMutableArray*)paths
             filterChildNode:(id<GrowingNode>)aNode
{
    
}

- (void)growingNodeHighLight:(BOOL)highLight
             withBorderColor:(UIColor *)borderColor
          andBackgroundColor:(UIColor *)backgroundColor
{
    
}


- (UIImage*)growingNodeScreenShot:(UIImage *)fullScreenImage
{
    CGRect frame = [self growingNodeFrame];
    if (self.safeAreaInsetsValue) {
        UIEdgeInsets safeAreaInsets = self.safeAreaInsetsValue.UIEdgeInsetsValue;
        frame.origin.y += safeAreaInsets.top;
    }
    UIImage *image = [fullScreenImage growingHelper_getSubImage:frame];
    return image;
}

- (UIImage*)growingNodeScreenShotWithScale:(CGFloat)maxScale
{
    return nil;
}

- (id)growingNodeAttribute:(NSString *)attrbute
{
    return nil;
}

- (id)growingNodeAttribute:(NSString *)attrbute forChild:(id<GrowingNode>)node
{
    return nil;
}

- (id<GrowingNode>)growingNodeAttachedInfoNode
{
    return nil;
}

@end
