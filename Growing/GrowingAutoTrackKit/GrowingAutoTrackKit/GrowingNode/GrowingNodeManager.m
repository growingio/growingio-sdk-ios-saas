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


#import "GrowingNodeManager.h"
#import "NSString+GrowingHelper.h"
#import "GrowingJavascriptCore.h"

#define parentIndexNull NSUIntegerMax

@interface GrowingNodeManagerEnumerateContext()
@property (nonatomic, assign) BOOL stopAll;
@property (nonatomic, assign) BOOL stopChilds;
@property (nonatomic, retain) NSMutableArray *didEndNodeBlocks;
@property (nonatomic, retain) GrowingNodeManager *manager;

@end

@interface GrowingNodeManagerDataItem : NSObject

@property (nonatomic, copy) NSString *nodeFullPath;    
@property (nonatomic, copy) NSString *nodePatchedPath; 
@property (nonatomic, assign) NSInteger keyIndex; 
@property (nonatomic, retain) id<GrowingNode> node;
@property (nonatomic, retain) NSArray<GrowingNodeItemComponent*> *pathComponents;

@end

@implementation GrowingNodeManagerDataItem
- (NSString*)description
{
    return NSStringFromClass([self.node class]);
}
@end


@interface GrowingNodeManager()

@property (nonatomic, retain) id<GrowingNode> enumItem;
@property (nonatomic, retain) NSMutableArray<GrowingNodeManagerDataItem*> *allItems;
@property (nonatomic, retain) NSMutableArray<id<GrowingNode>> *allNodes;
@property (nonatomic, assign) BOOL needUpdateAllItems;
@property (nonatomic, assign) NSInteger needUpdatePathIndex;

@property (nonatomic, copy)   BOOL(^checkBlock)(id<GrowingNode> node);

@end

@implementation GrowingNodeManager

- (instancetype)init
{
    return nil;
}
- (instancetype)initWithNodeAndParent:(id<GrowingNode>)aNode
{
    return nil;
}

- (instancetype)initWithNodeAndParent:(id<GrowingNode>)aNode
                           checkBlock:(BOOL (^)(id<GrowingNode>))checkBlock
{
    self = [super init];
    if (self)
    {
        self.allItems = [[NSMutableArray alloc] initWithCapacity:7];
        self.checkBlock = checkBlock;
        
        id<GrowingNode> curNode = aNode;
        while (curNode)
        {
            [self addNodeAtFront:curNode];
            curNode = [curNode growingNodeParent];
        }
        [self updateAllItems];
        
        if (!self.allItems.count)
        {
            return nil;
        }
        
        for (GrowingNodeManagerDataItem *item in self.allItems)
        {
            if (checkBlock && !checkBlock(item.node))
            {
                return nil;
            }
        }
    }
    return self;
}

- (void)enumerateChildrenUsingBlock:(void (^)(id<GrowingNode>, GrowingNodeManagerEnumerateContext *))block
{
    [self enumerateChildrenUsingBlock:block
                   withCompareManager:nil];
}

- (void)enumerateChildrenUsingBlock:(void (^)(id<GrowingNode>, GrowingNodeManagerEnumerateContext *))block withCompareManager:(GrowingNodeCompareManager *)compareManager
{
    if (!block || self.allItems.count == 0)
    {
        return;
    }
    self.enumItem = self.allItems.lastObject.node;
    
    [self updateAllItems];
    if (compareManager)
    {
        
        for (GrowingNodeManagerDataItem *item in self.allItems)
        {
            for (NSString *path in item.pathComponents)
            {
                [compareManager moveToChild:path];
            }
        }
    }
    
    
    NSMapTable *containerChildNodeChains = [[NSMapTable alloc] initWithKeyOptions:NSMapTableObjectPointerPersonality
                                                                     valueOptions:NSMapTableStrongMemory
                                                                         capacity:20];
    
    NSMutableArray *containerChildArr = [[NSMutableArray alloc] init];
    __strong NSMutableArray *strongContainerChildArr = containerChildArr;
    NSMutableArray *curItems = [[NSMutableArray alloc] init];
    for (NSInteger i = 0 ; i < self.allItems.count - 1; i++)
    {
        GrowingNodeManagerDataItem *item = self.allItems[i];
        [curItems addObject:item];
        [strongContainerChildArr removeAllObjects];
        [item.node growingNodeOutContainerChilds:strongContainerChildArr
                                        outPaths:nil
                                 filterChildNode:nil];
        
        for (id<GrowingNode> node in strongContainerChildArr)
        {
            
            
            if (!self.checkBlock || self.checkBlock(node))
            {
                if (![containerChildNodeChains objectForKey:node])
                {
                    [containerChildNodeChains setObject:[curItems mutableCopy]
                                                 forKey:node];
                }
            }
        }
    }
    
    [self _enumerateChildrenUsingBlock:block
                        compareManager:compareManager
              containerChildNodeChains:containerChildNodeChains];
    self.enumItem = nil;
}

- (GrowingNodeManagerEnumerateContext*)_enumerateChildrenUsingBlock:(void (^)(id<GrowingNode>,
                                                                              GrowingNodeManagerEnumerateContext *))block
                                                     compareManager:(GrowingNodeCompareManager*)compareManager
                                           containerChildNodeChains:(NSMapTable*)containerChildNodeChains
{
    
    NSUInteger endIndex = self.allItems.count - 1;
    GrowingNodeManagerDataItem *endItem = self.allItems[endIndex];
    
    GrowingNodeManagerEnumerateContext *context = [[GrowingNodeManagerEnumerateContext alloc] init];
    context.manager = self;
    
    block(endItem.node,context);
    
    if (context.stopAll || context.stopChilds)
    {
        return context;
    }

    NSMutableArray *containerChildArr = [[NSMutableArray alloc] init];
    __strong NSMutableArray *strongContainerChildArr = containerChildArr;
    NSMutableArray *childArr = [[NSMutableArray alloc] init];
    
    [endItem.node growingNodeOutContainerChilds:strongContainerChildArr
                                       outPaths:nil
                                filterChildNode:nil];
    [endItem.node growingNodeOutChilds:childArr
                              outPaths:nil
                       filterChildNode:nil];
    
    for (id<GrowingNode> node in strongContainerChildArr)
    {
        if (self.checkBlock && !self.checkBlock(node))
        {
            continue;
        }
        
        if ([containerChildNodeChains objectForKey:node])
        {
            continue;
        }
        
        [containerChildNodeChains setObject:[self.allItems mutableCopy] forKey:node];
    }

    for (NSArray *childs in @[childArr,strongContainerChildArr])
    {
        for (id<GrowingNode> node in childs)
        {
            if (self.checkBlock && !self.checkBlock(node))
            {
                continue;
            }
            NSMutableArray<GrowingNodeManagerDataItem*> *backupAllItems = nil;
            if (childs == childArr)
            {
                NSMutableArray<GrowingNodeManagerDataItem*> * items = [containerChildNodeChains objectForKey:node];
                if (items)
                {
                    backupAllItems = [self replaceAllItems:items];
                    if (backupAllItems == nil)
                    {
                        
                        continue;
                    }
                }
            }
            else
            {
                if ([containerChildNodeChains objectForKey:node] == nil)
                {
                    
                    continue;
                }
            }

            
            
            
            
            
            
            [containerChildNodeChains removeObjectForKey:node];

            [self addNodeAtEnd:node];
             GrowingNodeManagerEnumerateContext *childContext =
            [self _enumerateChildrenUsingBlock:block
                                compareManager:compareManager
                      containerChildNodeChains:containerChildNodeChains];
            [self removeNodeItemAtEnd];

            if (backupAllItems != nil)
            {
                [self replaceAllItems:backupAllItems];
            }

            [childContext.didEndNodeBlocks enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                void(^finishBlockkkk)(id<GrowingNode>) = obj;
                finishBlockkkk(node);
            }];
            
            if (childContext.stopAll)
            {
                context.stopAll = YES;
                return context;
            }
        }
    }
    return context;
}

+ (id)recursiveAttributeValueOfNode:(id<GrowingNode>)aNode forKey:(NSString *)key
{
    GrowingNodeManager *manager = [[self alloc] initWithNodeAndParent:aNode];
    __block id attribute = nil;
    [manager enumerateChildrenUsingBlock:^(id<GrowingNode> aNode, GrowingNodeManagerEnumerateContext *context) {
        [context stop];
        attribute = [context attributeValueForKey:key];
    }];
    return attribute;
}

#pragma mark - 添加删除


- (void)addNodeAtFront:(id<GrowingNode>)aNode
{
    GrowingNodeManagerDataItem *item = [[GrowingNodeManagerDataItem alloc] init];
    item.node = aNode;
    [self.allItems insertObject:item
                        atIndex:0];
    self.needUpdateAllItems = YES;
}

- (void)addNodeAtEnd:(id<GrowingNode>)aNode
{
    [self updateAllItems];
    
    GrowingNodeManagerDataItem *dataItem = [[GrowingNodeManagerDataItem alloc] init];
    dataItem.node = aNode;
    [self.allItems addObject:dataItem];
    self.needUpdatePathIndex = MIN(self.needUpdatePathIndex, self.allItems.count - 1);
}

- (void)updateAllItemXpath
{
    [self updateAllItemXpathByIndex:self.needUpdatePathIndex];
}

- (void)updateAllItemXpathByIndex:(NSUInteger)index
{
    if (index >= self.allItems.count)
    {
        return;
    }
    self.needUpdatePathIndex = self.allItems.count;
    
    

    
    
    NSMutableString *lastNodeFullPath = [[NSMutableString alloc] initWithString:@""];
    NSMutableString *lastNodePatchedPath = [[NSMutableString alloc] initWithString:@""];
    NSInteger keyIndex = [GrowingNodeItemComponent indexNotDefine];
    if (index > 0)
    {
        NSString *lastItemFullPath = [self.allItems[index - 1] nodeFullPath];
        if (lastItemFullPath.length)
        {
            [lastNodeFullPath appendString:lastItemFullPath];
        }
        NSString *lastItemPatchedPath = [self.allItems[index - 1] nodePatchedPath];
        if (lastItemPatchedPath.length)
        {
            [lastNodePatchedPath appendString:lastItemPatchedPath];
        }
        keyIndex = [self.allItems[index - 1] keyIndex];
    }
    else
    {
        GrowingNodeManagerDataItem *headDataItem = self.allItems.firstObject;
        GrowingNodeItemComponent *cp = [[GrowingNodeItemComponent alloc] init];
        cp.pathComponent = nil;
        headDataItem.pathComponents = @[cp];
        headDataItem.keyIndex = [GrowingNodeItemComponent indexNotDefine];
    }
    
    NSMutableArray *temppathComponentsArr = [[NSMutableArray alloc] init];

    NSInteger indexNotDefined = [GrowingNodeItemComponent indexNotDefine];
    for (NSUInteger i = MAX(1, index) ; i < self.allItems.count ; i ++)
    {
        GrowingNodeManagerDataItem *dataItem = self.allItems[i];
        if (!dataItem.pathComponents)
        {
            
            GrowingNodeManagerDataItem *parentItem = self.allItems[i - 1];
            [temppathComponentsArr removeAllObjects];
            [parentItem.node growingNodeOutContainerChilds:nil
                                                  outPaths:temppathComponentsArr
                                           filterChildNode:dataItem.node];
            if (!temppathComponentsArr.count)
            {
                [parentItem.node growingNodeOutChilds:nil
                                             outPaths:temppathComponentsArr
                                      filterChildNode:dataItem.node];
            }
            dataItem.pathComponents = temppathComponentsArr.firstObject;
        }
        
        
        NSArray * dataItemPathComponents = dataItem.pathComponents;
        NSInteger indexOfKeyIndex = indexNotDefined;
        for (NSInteger ci = dataItemPathComponents.count - 1; ci >= 0; ci--)
        {
            if ([dataItemPathComponents[ci] isKeyIndex])
            {
                indexOfKeyIndex = ci;
                break;
            }
        }

        for (NSInteger ci = 0; ci < dataItemPathComponents.count; ci++)
        {
            GrowingNodeItemComponent * cp = dataItemPathComponents[ci];
            NSString * userDefinedTag = (cp.userDefinedTag.length == 0 ? @"" : [NSString stringWithFormat:@"#%@", cp.userDefinedTag]);
            if (cp.pathComponent.length)
            {
                if (cp.index == indexNotDefined)
                {
                    [lastNodePatchedPath appendFormat:@"/%@%@",cp.pathComponent,userDefinedTag];
                }
                else
                {
                    if (ci != indexOfKeyIndex)
                    {
                        [lastNodePatchedPath appendFormat:@"/%@[%d]%@",cp.pathComponent,(int)cp.index,userDefinedTag];
                    }
                    else
                    {
                        [lastNodePatchedPath setString:lastNodeFullPath];
                        [lastNodePatchedPath appendFormat:@"/%@[-]%@",cp.pathComponent,userDefinedTag];
                        keyIndex = cp.index;
                    }
                }
                if (cp.index == indexNotDefined)
                {
                    [lastNodeFullPath appendFormat:@"/%@%@",cp.pathComponent,userDefinedTag];
                }
                else
                {
                    [lastNodeFullPath appendFormat:@"/%@[%d]%@",cp.pathComponent,(int)cp.index,userDefinedTag];
                }
            }
        }
        
        dataItem.nodeFullPath = lastNodeFullPath;
        dataItem.nodePatchedPath = lastNodePatchedPath;
        dataItem.keyIndex = keyIndex;
    }
}


- (void)removeNodeItemAtEnd
{
    [self.allItems removeLastObject];
}

- (NSMutableArray<GrowingNodeManagerDataItem*> *)replaceAllItems:(NSMutableArray<GrowingNodeManagerDataItem*> *)newAllItems
{
    NSMutableArray<GrowingNodeManagerDataItem*> * oldAllItems = self.allItems;
    self.allItems = newAllItems;

    self.needUpdateAllItems = YES;
    [self updateAllItems];
    if (self.allItems.count == 0)
    {
        self.allItems = oldAllItems;
        return nil;
    }

    self.needUpdatePathIndex = 0;
    [self updateAllItemXpath];

    return oldAllItems;
}

- (NSUInteger)nodeCount
{
    return self.allItems.count;
}

- (NSString*)nodePathAtEnd
{
    [self updateAllItems];
    [self updateAllItemXpath];
    return [self.allItems.lastObject nodePatchedPath];
}

- (NSString*)nodeFullPathAtEnd
{
    [self updateAllItems];
    [self updateAllItemXpath];
    return [self.allItems.lastObject nodeFullPath];
}

- (NSInteger)nodeKeyIndexAtEnd
{
    [self updateAllItems];
    [self updateAllItemXpath];
    return [self.allItems.lastObject keyIndex];
}

- (NSString*)nodePathAtIndex:(NSUInteger)index
{
    [self updateAllItems];
    [self updateAllItemXpath];
    return [self.allItems[index] nodePatchedPath];
}

- (GrowingNodeManagerDataItem*)itemAtIndex:(NSUInteger)index
{
    [self updateAllItems];
    return self.allItems[index];
}

- (GrowingNodeManagerDataItem*)itemAtEnd
{
    [self updateAllItems];
    return self.allItems.lastObject;
}

- (GrowingNodeManagerDataItem*)itemAtFirst
{
    [self updateAllItems];
    return self.allItems.firstObject;
}

- (id<GrowingNode>)nodeAtFirst
{
    return [[self itemAtFirst] node];
}

- (void)updateAllItems
{
    if (!self.needUpdateAllItems)
    {
        return;
    }
    self.needUpdateAllItems = NO;
    
    NSInteger i = 0;
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    while (i < self.allItems.count)
    {
        GrowingNodeManagerDataItem *item = self.allItems[i];

        
        for (NSInteger j = i + 1; j < self.allItems.count ; j ++)
        {
            GrowingNodeManagerDataItem *child = self.allItems[j];

            [tempArray removeAllObjects];
            [item.node growingNodeOutContainerChilds:tempArray
                                            outPaths:nil
                                     filterChildNode:child.node];
            
            if (tempArray.count)
            {
                for (NSInteger k = j - 1 ; k >= i+1 ; k--)
                {
                    [self.allItems removeObjectAtIndex:k];
                }
                goto breakLoop;
            }
        }
        
        
        if (i != self.allItems.count - 1)
        {
            GrowingNodeManagerDataItem *child = self.allItems[i + 1];
            [tempArray removeAllObjects];
            [item.node growingNodeOutChilds:tempArray
                                   outPaths:nil
                            filterChildNode:child.node];
            
            if (tempArray.count)
            {
                goto breakLoop;
            }
            
            else
            {
                [self.allItems removeAllObjects];
                return;
            }
        }
        
breakLoop:
        i ++;
    }
    
    self.needUpdatePathIndex = 0;
}










+ (BOOL)isElementXPath:(NSString *)elementXPath
   orElementPlainXPath:(NSString *)elementPlainXPath
       matchToTagXPath:(NSString *)tagXPath
 updatePlainXPathBlock:(void (^)(NSString * plainXPath))updatePlainXPathBlock
{
    if (elementXPath.length == 0 || tagXPath.length == 0)
    {
        return NO;
    }
    NSMutableString * fieldA = [[NSMutableString alloc] initWithString:@""];
    NSMutableString * fieldB = [[NSMutableString alloc] initWithString:@""];
    NSString * elementXPathBackup = elementXPath;
    BOOL hasFieldSeparator = [GrowingJavascriptCore parseJointField:elementXPath toFieldA:fieldA toFieldB:fieldB];
    if (hasFieldSeparator)
    {
        elementXPath = fieldA;
    }
    if ([elementXPath rangeOfString:@"#"].location != NSNotFound && elementPlainXPath.length == 0)
    {
        
        const char * input = elementXPath.UTF8String;
        const int length = (int)elementXPath.length;
        char * output = (char *)malloc(length + 1);
        const char * p = input;
        char * q = output;
        int i = 0;
        bool skip = false;
        while (i < length)
        {
            if (!skip)
            {
                if (*p == '#')
                {
                    skip = YES;
                    p++, i++;
                }
                else
                {
                    *q = *p;
                    p++, q++, i++;
                }
            }
            else
            {
                if (*p == '/')
                {
                    skip = NO;
                    
                }
                else if (*p == ':' && i + 1 < length && *(p+1) == ':')
                {
                    
                    skip = NO;
                    
                }
                else
                {
                    p++, i++;
                }
            }
        }
        *q = '\0';
        NSData * data = [NSData dataWithBytesNoCopy:output length:(q - output) freeWhenDone:YES];
        NSString * plainXPath = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (hasFieldSeparator)
        {
            plainXPath = [GrowingJavascriptCore jointField:plainXPath withField:fieldB];
        }
        if (updatePlainXPathBlock != nil)
        {
            updatePlainXPathBlock(plainXPath);
        }
        elementPlainXPath = plainXPath;
    }
    elementXPath = elementXPathBackup;

    return [elementXPath growingHelper_matchWildly:tagXPath] || (elementPlainXPath.length > 0 && [elementPlainXPath growingHelper_matchWildly:tagXPath]);
}

@end

@implementation GrowingNodeManagerEnumerateContext

- (id)attributeValueForKey:(NSString *)key
{
    NSArray *nodes = [self allNodes];
    id ret = nil;
    id<GrowingNode> lastNode = nil;
    id<GrowingNode> curNode = nil;
    for (NSInteger i = nodes.count - 1; i >= 0 ; i--)
    {
        curNode = nodes[i];
        ret = [curNode growingNodeAttribute:key];
        if (ret)
        {
            break;
        }
        if (lastNode)
        {
            ret = [curNode growingNodeAttribute:key forChild:lastNode];
            if (ret)
            {
                break;
            }
        }
        
        lastNode = curNode;
    }
    return ret;
}

- (NSArray<id<GrowingNode>>*)allNodes
{
    NSMutableArray *nodes = [[NSMutableArray alloc] init];
    [self.manager.allItems enumerateObjectsUsingBlock:^(GrowingNodeManagerDataItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [nodes addObject:obj.node];
    }];
    return nodes;
}

- (id<GrowingNode>)startNode
{
    return self.manager.enumItem;
}

- (void)stop
{
    self.stopAll = YES;
}

- (void)skipThisChilds
{
    self.stopChilds = YES;
}

- (void)onNodeFinish:(void (^)(id<GrowingNode>))finishBlock
{
    if (!self.didEndNodeBlocks)
    {
        self.didEndNodeBlocks = [[NSMutableArray alloc] init];
    }
    [self.didEndNodeBlocks addObject:finishBlock];
}

- (NSString*)xpath
{
    return [self.manager nodePathAtEnd];
}

- (NSString*)fullPath
{
    return [self.manager nodeFullPathAtEnd];
}

- (NSInteger)nodeKeyIndex
{
    return [self.manager nodeKeyIndexAtEnd];
}

@end
