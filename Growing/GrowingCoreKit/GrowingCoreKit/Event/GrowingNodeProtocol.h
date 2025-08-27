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


typedef NS_OPTIONS(NSUInteger, GrowingElementEventCategory)
{
    GrowingElementEventCategoryImpression = 1,
    GrowingElementEventCategoryClick = 2,
    GrowingElementEventCategoryContentChange = 4,
    
    GrowingElementEventCategorySubmit = 8,
    
    GrowingElementEventCategoryAll = 15,
};


@protocol GrowingNode <NSObject>

@required


- (void)growingNodeOutContainerChilds:(NSMutableArray*)childs
                             outPaths:(NSMutableArray*)paths
                      filterChildNode:(id<GrowingNode>)aNode;

- (void)growingNodeOutChilds:(NSMutableArray*)childs
                    outPaths:(NSMutableArray*)paths
             filterChildNode:(id<GrowingNode>)aNode;


- (id<GrowingNode>)growingNodeParent;

- (BOOL)growingNodeDonotTrack;
- (BOOL)growingNodeDonotTrackImp;
- (BOOL)growingNodeDonotCircle;


- (BOOL)growingNodeUserInteraction;

- (NSString*)growingNodeName;
- (NSString*)growingNodeContent;

- (NSDictionary*)growingNodeDataDict;

- (UIWindow*)growingNodeWindow;

- (id<GrowingNode>)growingNodeAttachedInfoNode;


- (void)growingNodeHighLight:(BOOL)highLight
             withBorderColor:(UIColor *)borderColor
          andBackgroundColor:(UIColor *)backgroundColor;
- (CGRect)growingNodeFrame;


- (UIImage*)growingNodeScreenShot:(UIImage *)fullScreenImage;
- (UIImage*)growingNodeScreenShotWithScale:(CGFloat)maxScale;



- (id)growingNodeAttribute:(NSString*)attrbute;
- (id)growingNodeAttribute:(NSString*)attrbute forChild:(id<GrowingNode>)node;

- (id )growingNodeAsyncNativeHandler;

@optional


- (GrowingElementEventCategory)growingNodeEligibleEventCategory;

- (BOOL)growingImpNodeIsVisible;

@end
