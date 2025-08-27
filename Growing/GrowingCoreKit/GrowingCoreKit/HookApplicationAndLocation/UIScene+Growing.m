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


#import "UIScene+Growing.h"
#import "UIApplication+Growing.h"
#import "GrowingCocoaLumberjack.h"

@interface GrowingSceneAppLifecycle : NSObject

@end

@implementation GrowingSceneAppLifecycle

+ (instancetype)sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}

+ (void)setup {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[self sharedInstance] addSceneNotification];
    });
}

- (void)addSceneNotification {
    NSDictionary *sceneManifestDict = [[NSBundle mainBundle] infoDictionary][@"UIApplicationSceneManifest"];
    if (!sceneManifestDict) {
        return;
    }
    if (UIDevice.currentDevice.systemVersion.doubleValue < 13.0) {
        return;
    }
    
    if (@available(iOS 13, *)) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        
        
        
        [nc addObserver:self
               selector:@selector(dispatchApplicationWillResignActive)
                   name:@"UISceneWillDeactivateNotification"
                 object:nil];

        [nc addObserver:self
               selector:@selector(dispatchApplicationDidBecomeActive)
                   name:@"UISceneDidActivateNotification"
                 object:nil];

        [nc addObserver:self
               selector:@selector(dispatchApplicationWillEnterForeground)
                   name:@"UISceneWillEnterForegroundNotification"
                 object:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dispatchApplicationDidBecomeActive {
    GIOLogDebug(@"sceneDidBecomeActive");
    growingDidBecomeActive();
}

- (void)dispatchApplicationWillResignActive {
    GIOLogDebug(@"sceneWillResignActive");
    growingWillResignActive();
}

- (void)dispatchApplicationWillEnterForeground {
    GIOLogDebug(@"sceneWillEnterForeground");
    growingWillEnterForeground();
}

@end

@interface NSNull (fosetup____fo_function1)
@end

@implementation NSNull (fosetup____fo_function1)

+ (void)load {
    
    
    
    
    [GrowingSceneAppLifecycle setup];
}

@end
