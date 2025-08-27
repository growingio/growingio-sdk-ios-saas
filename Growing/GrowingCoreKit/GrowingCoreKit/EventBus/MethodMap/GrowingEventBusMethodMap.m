#import "GrowingEventBusMethodMap.h"

@implementation GrowingEventBusMethodMap
+ (NSDictionary *)methodMap
{

   return @{@"GrowingEBApplicationEvent": @[@"GrowingMobileDebugger/1/didfinishLauching:", @"GrowingInstance/1/didfinishLauching:", @"GrowingIMPTrack/1/applicationEvent:"], @"GrowingEBTrackSelfEvent": @[@"GrowingTrackSelfManager/1/trackSelfEvent:"], @"GrowingEBVCLifeEvent": @[@"GrowingIMPTrack/1/viewControllerLifeEvent:"]};
}

@end