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


#import "ViewController+MASG3Additions.h"

#ifdef MASG3_VIEW_CONTROLLER

@implementation MASG3_VIEW_CONTROLLER (MASG3Additions)

- (MASG3ViewAttribute *)masG3_topLayoutGuide {
    return [[MASG3ViewAttribute alloc] initWithView:self.view item:self.topLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}
- (MASG3ViewAttribute *)masG3_topLayoutGuideTop {
    return [[MASG3ViewAttribute alloc] initWithView:self.view item:self.topLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}
- (MASG3ViewAttribute *)masG3_topLayoutGuideBottom {
    return [[MASG3ViewAttribute alloc] initWithView:self.view item:self.topLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}

- (MASG3ViewAttribute *)masG3_bottomLayoutGuide {
    return [[MASG3ViewAttribute alloc] initWithView:self.view item:self.bottomLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}
- (MASG3ViewAttribute *)masG3_bottomLayoutGuideTop {
    return [[MASG3ViewAttribute alloc] initWithView:self.view item:self.bottomLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}
- (MASG3ViewAttribute *)masG3_bottomLayoutGuideBottom {
    return [[MASG3ViewAttribute alloc] initWithView:self.view item:self.bottomLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}



@end

#endif
