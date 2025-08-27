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


#import "WKWebView+GrowingNode.h"
#import "WKWebView+Growing.h"


void _growingNodeOutChilds(UIView *_self, SEL _cmd, NSMutableArray *childs, NSMutableArray *paths, id <GrowingNode> aNode) {
    
}


void _growingNodeOutContainerChilds(UIView *_self, SEL _cmd, NSMutableArray *childs, NSMutableArray *paths, id <GrowingNode> aNode) {
    
}


id <GrowingNodeAsyncNativeHandler> _growingNodeAsyncNativeHandler(UIView *_self, SEL _cmd) {
    return _self.growingHook_JavascriptCore;
}




void _growingNodeHighLight(UIView *_self, SEL _cmd, BOOL highLight, UIColor *borderColor, UIColor *backgroundColor) {
    if (highLight) {
        [_self.growingHook_JavascriptCore highlightElementAtPoint:_self.growingHook_JavascriptCore.lastPoint];
    } else {
        [_self.growingHook_JavascriptCore cancelHighlight];
    }
}

void loadAllWKWebViewMethod() {
    Class WKWebViewClass = [GrowingJavascriptCore WKWebViewClass];
    if (WKWebViewClass != nil) {
        
        class_addMethod(WKWebViewClass, @selector(growingNodeOutChilds:outPaths:filterChildNode:), (IMP) _growingNodeOutChilds, "v@@@");

        
        class_addMethod(WKWebViewClass, @selector(growingNodeOutContainerChilds:outPaths:filterChildNode:), (IMP) _growingNodeOutContainerChilds, "v@@@");

        
        class_addMethod(WKWebViewClass, @selector(growingNodeAsyncNativeHandler), (IMP) _growingNodeAsyncNativeHandler, "@");

        
        
        
        class_addMethod(WKWebViewClass, @selector(growingNodeHighLight:withBorderColor:andBackgroundColor:), (IMP) _growingNodeHighLight, "vB@@");
    }
}

static void *const GROWING_WK_WEB_VIEW_IS_TRACKED = "GROWING_WK_WEB_VIEW_IS_TRACKED";

@implementation WKWebView (GrowingAttributes)
- (void)setGrowingAttributesIsTracked:(BOOL)growingAttributesIsTracked {
    objc_setAssociatedObject(self, GROWING_WK_WEB_VIEW_IS_TRACKED, @(growingAttributesIsTracked), OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)growingAttributesIsTracked {
    return [objc_getAssociatedObject(self, GROWING_WK_WEB_VIEW_IS_TRACKED) boolValue];
}
@end
