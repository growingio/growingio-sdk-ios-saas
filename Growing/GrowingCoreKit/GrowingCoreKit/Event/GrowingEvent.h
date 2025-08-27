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
#import "GrowingNodeProtocol.h"
#import "GrowingMenuView.h"
#import "GrowingAddEventContextProtocal.h"
#import <CoreLocation/CoreLocation.h>






























#define GROWING_EVENT_LIST(MACRO)                                       \
    MACRO(NotInit                   , = 0       , @"未初始化")           \
    MACRO(AppLifeCycle              , = 1       , @"生命周期")           \
    MACRO(AppLifeCycleAppOpen       , = 10001   , @"APP打开")           \
    MACRO(AppLifeCycleAppClose      ,           , @"APP关闭")           \
    MACRO(AppLifeCycleAppActive     ,           , @"APP激活")           \
    MACRO(AppLifeCycleAppInactive   ,           , @"APP非激活")         \
    MACRO(AppLifeCycleAppNewVisit   ,           , @"一次新访问")        \
    MACRO(Page                      , = 2       , @"新页面")           \
    MACRO(PageNewPage               , = 20001   , @"新页面")           \
    MACRO(PageNewH5Page             ,           , @"新H5页面")         \
    MACRO(PageResendPage            ,           , @"重发页面")          \
    MACRO(PageResendH5Page          ,           , @"重发H5页面")        \
    MACRO(UserInteraction           , = 3       , @"用户操作")         \
    MACRO(ButtonClick               , = 30001   , @"按钮点击")         \
    MACRO(ButtonTouchDown           ,           , @"按钮按下")         \
    MACRO(ButtonTouchUp             ,           , @"按钮按下并抬起")    \
    MACRO(SegmentControlSelect      ,           , @"多选控件点击")      \
    MACRO(RowSelected               ,           , @"点击一行")         \
    MACRO(AlertSelected             ,           , @"点击对话框")        \
    MACRO(TapGest                   ,           , @"单击")             \
    MACRO(DoubleTapGest             ,           , @"双击")             \
    MACRO(LongPressGest             ,           , @"长按")             \
    MACRO(H5ElementClick            ,           , @"点击H5元素")        \
    MACRO(H5ElementSubmit           ,           , @"H5 Submit 表单")   \
    MACRO(UI                        , = 4       , @"UI更新")           \
    MACRO(UISetAlpha                , = 40001   , @"设置透明度")        \
    MACRO(UISetHidden               ,           , @"设置显示")          \
    MACRO(UIAddSubView              ,           , @"添加新View")       \
    MACRO(UIPageShow                ,           , @"新页面显示UI")      \
    MACRO(UIPageResend              ,           , @"重发上个页面UI元素")  \
    MACRO(UIChangeText              ,           , @"文本变更")          \
    MACRO(UISetText                 ,           , @"设置文本")          \
    MACRO(UINewRow                  ,           , @"显示新行")          \
    MACRO(UINewRowHeader            ,           , @"显示行Header")      \
    MACRO(UIAlertShow               ,           , @"弹出对话框")         \
    MACRO(SegmentAddTitle           ,           , @"多选控件添加文本")    \
    MACRO(SegmentAddImage           ,           , @"多选控件添加图片")    \
    MACRO(SegmentSetTitle           ,           , @"多选控件更新文本")    \
    MACRO(SegmentSetImage           ,           , @"多选控件更新")       \
    MACRO(H5Element                 ,           , @"H5元素显示")        \
    MACRO(H5ElementChangeText       ,           , @"H5文本变更")        \
    MACRO(NetWork                   , = 5       , @"网络访问")          \
    MACRO(UIHidden                  , = 6       , @"UI隐藏")           \
    MACRO(UIHiddenCellReuse         , = 60001   , @"列表行重用")        \
    MACRO(UIHiddenSetAlpha          ,           , @"透明度设置0")        \
    MACRO(MainEventCount            , = 7       , @"事件数量")          \




#define GROWING_TYPE_MACRO(NAME,ENUMVALUE,DESP) \
            GrowingEventType ## NAME   ENUMVALUE ,

typedef NS_ENUM(NSInteger,GrowingEventType)
{
    GROWING_EVENT_LIST(GROWING_TYPE_MACRO)
};


CG_INLINE BOOL GrowingTypeIsMainType(GrowingEventType type)
{
    return type < 10000;
}

CG_INLINE GrowingEventType GrowingTypeGetMainType(GrowingEventType type)
{
    return GrowingTypeIsMainType(type) ? type : (type / 10000);
}

NSString* _Nullable GrowingEventTypeGetDescription(GrowingEventType type);


#define DEFINE_GROWING_EVENT_CLASS(PROCTOCOL,EVENTTYPE)                                                 \
    @interface PROCTOCOL ## EVENTTYPE : NSObject<PROCTOCOL>                                             \
    @end


#define GrowingEventAction(PROCTOCOL)                                                                   \
    DEFINE_GROWING_EVENT_CLASS(PROCTOCOL,AppLifeCycle)                                                  \
    DEFINE_GROWING_EVENT_CLASS(PROCTOCOL,Page)                                                          \
    DEFINE_GROWING_EVENT_CLASS(PROCTOCOL,UserInteraction)                                               \
    DEFINE_GROWING_EVENT_CLASS(PROCTOCOL,UI)                                                            \
    DEFINE_GROWING_EVENT_CLASS(PROCTOCOL,NetWork)                                                       \
                                                                                                        \
CG_INLINE id<PROCTOCOL> PROCTOCOL ## ForEventType(GrowingEventType eventType)                           \
{                                                                                                       \
    NSArray *classes = @[                                                                               \
                         [PROCTOCOL ## AppLifeCycle     class],                                         \
                         [PROCTOCOL ## Page             class],                                         \
                         [PROCTOCOL ## UserInteraction  class],                                         \
                         [PROCTOCOL ## UI               class],                                         \
                         [PROCTOCOL ## NetWork          class],                                         \
                         ];                                                                             \
    if (eventType < classes.count && eventType!=  GrowingEventTypeNotInit)                              \
    {                                                                                                   \
        return [[classes[eventType-1] alloc] init];                                                     \
    }                                                                                                   \
    else                                                                                                \
    {                                                                                                   \
        return nil;                                                                                     \
    }                                                                                                   \
}                                                                                                       \






@protocol GrowingEventProtocol<GrowingNode>

@optional

- (BOOL)growingEventProtocolCanTrackWithType:(GrowingEventType)eventType
                                 triggerNode:(id<GrowingNode> _Nullable)triggerNode;


@end



@interface GrowingEvent : NSObject <NSCopying>


@property (nonatomic, retain  , nonnull) NSMutableDictionary *dataDict;
@property (nonatomic, readonly, nonnull) NSString *uuid;
@property (nonatomic, readonly )         GrowingEventType eventType;

- (_Nullable instancetype)initWithUUID:(NSString* _Nonnull)uuid
                                  data:(NSDictionary* _Nullable)data NS_DESIGNATED_INITIALIZER;


- (NSString*)eventTypeKey;
- (instancetype)initWithTimestamp:(NSNumber *)tm ;

- (void)sendWithTriggerNode:(id<GrowingNode>)triggerNode
                   thisNode:(id<GrowingNode>)triggerNode
           triggerEventType:(GrowingEventType)eventType
                    context:(id<GrowingAddEventContext>)context;
+ (BOOL)hasExtraFields; 
- (void)assignLocationIfAny;
- (void)assignRadioType;

+ (BOOL)nodeShouldTriggered:(id<GrowingNode>)triggerNode
                   withType:(GrowingEventType)type
                  withChild:(BOOL)withChild;

@end

@interface GrowingAppSimpleEvent : GrowingEvent
+ (void)send;
@end


@interface GrowingVisitEvent : GrowingAppSimpleEvent

+ (void)onGpsLocationChanged:(CLLocation * _Nullable)location;

@end

@interface GrowingCustomRootEvent : GrowingEvent
@end
