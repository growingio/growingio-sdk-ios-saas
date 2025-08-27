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


#import "GrowingNodeCompareManager.h"

@interface GrowingNodeCompareNode : NSObject
@property (nonatomic, assign) BOOL      pathEnd;
@property (nonatomic, retain) NSString  *name;
@property (nonatomic, retain) NSMutableDictionary *childNodes;
@end


@implementation GrowingNodeCompareNode

- (GrowingNodeCompareNode*)nodeForKey:(NSString*)key
{
    return self.childNodes[key];
}

- (void)addSetNode:(GrowingNodeCompareNode*)node forKey:(NSString*)key
{
    if (!self.childNodes)
    {
        self.childNodes = [[NSMutableDictionary alloc] init];
    }
    self.childNodes[key] = node;
}

@end


@interface GrowingNodeCompareManager()
@property (nonatomic, retain) GrowingNodeCompareNode *rootNode;
@property (nonatomic, retain) NSMutableArray *curNodesStack;
@property (nonatomic, retain) NSArray *curNodes;
@end

@implementation GrowingNodeCompareManager

+ (instancetype)managerWithPathList:(NSArray *)pathList
{
    GrowingNodeCompareManager *manager = [[GrowingNodeCompareManager alloc] init];
    [manager loadpathList:pathList];
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.rootNode = [[GrowingNodeCompareNode alloc] init];
        self.curNodes = [[NSMutableArray alloc] initWithObjects:self.rootNode, nil];
    }
    return self;
}

- (void)loadpathList:(NSArray*)pathList
{
    for (NSString *path in pathList)
    {
        NSArray *pathComponents = [path pathComponents];
        [self addNodeWithPathComponents:pathComponents];
    }
}

- (void)addNodeWithPathComponents:(NSArray*)pathComponents
{
    GrowingNodeCompareNode *curNode = self.rootNode;
    for (NSString *path in pathComponents)
    {
        GrowingNodeCompareNode *node = [curNode nodeForKey:path];
        if (!node)
        {
            node = [[GrowingNodeCompareNode alloc] init];
            node.name = path;
            [curNode addSetNode:node forKey:path];
        }
        curNode = node;
    }
    curNode.pathEnd = YES;
}

- (void)moveToChild:(NSString *)childPath
{
    NSMutableArray *childNodes = [[NSMutableArray alloc] init];
    
    [self.curNodes enumerateObjectsUsingBlock:^(GrowingNodeCompareNode* node, NSUInteger idx, BOOL *stop) {
        
        GrowingNodeCompareNode *childNode1 = [node nodeForKey:childPath];
        if (childNode1)
        {
            [childNodes addObject:childNode1];
        }
        
        GrowingNodeCompareNode *childNode2 = [node nodeForKey:@"*"];
        if (childNode2)
        {
            [childNodes addObject:childNode2];
        }
        
        if ([childPath hasSuffix:@"]"])
        {
            NSRange rangeStart = [childPath rangeOfString:@"[" options:NSBackwardsSearch];
            if (rangeStart.length)
            {
                NSRange range = NSMakeRange(rangeStart.location + 1,
                                            childPath.length - 1 - rangeStart.location - 1);
                NSString *allIndexPath = [childPath stringByReplacingCharactersInRange:range
                                                                                 withString:@"*"];
                GrowingNodeCompareNode *childNode3 = [node nodeForKey:allIndexPath];
                if (childNode3)
                {
                    [childNodes addObject:childNode3];
                }
            }
        }
        
        if ([node.name isEqualToString:@"*"])
        {
            [childNodes addObject:self];
        }
    }];
    
    [self.curNodesStack addObject:childNodes];
    self.curNodes = childNodes;
}

- (void)moveToParent
{
    [self.curNodesStack removeLastObject];
    self.curNodes = self.curNodesStack.lastObject;
}

- (BOOL)curNodeIsLeaf
{
    for (GrowingNodeCompareNode *node in self.curNodes)
    {
        if (node.pathEnd)
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)curNodeIsEmpty
{
    return self.curNodes.count == 0;
}

@end
