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


#import "GrowingDeviceInfo.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import "GrowingInstance.h"
#import "GrowingEventDataBase.h"
#import "UIApplication+Growing.h"
#import "NSString+GrowingHelper.h"
#import <pthread.h>
#import "GrowingEventManager.h"
#import "GrowingCocoaLumberjack.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>



@implementation GrowingDeviceInfo

static pthread_mutex_t _mutex;

@synthesize deviceIDString = _deviceIDString;
@synthesize idfv = _idfv;
@synthesize idfa = _idfa;



- (NSMutableDictionary *)getKeychainQuery:(NSString *)key {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    (id)kSecClassGenericPassword, (id)kSecClass,
                                             key, (id)kSecAttrService,
                                             key, (id)kSecAttrAccount,
      (id)kSecAttrAccessibleAlwaysThisDeviceOnly, (id)kSecAttrAccessible,
            nil];
}

- (void)setKeychainObject:(id)value forKey:(NSString *)service{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @try {
            
            NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
            
            
            SecItemDelete((CFDictionaryRef)keychainQuery);
            
            
            [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:value] forKey:(id)kSecValueData];
            
            
            
            SecItemAdd((CFDictionaryRef)keychainQuery, NULL);
        } @catch (NSException *exception) {
            GIOLogError(@"%@",exception);
        }
    });
}

- (id)keyChainObjectForKey:(NSString *)key {
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    
    
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [keychainQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        } @catch (NSException *e) {
            GIOLogError(@"GrowingIO Unarchive of %@ failed: %@", key, e);
        } @finally {
        }
    }
    if (keyData)
        CFRelease(keyData);
    return ret;
}

- (void)removeKeyChainObjectForKey:(NSString *)service {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((CFDictionaryRef)keychainQuery);
}



- (NSString*)getCurrentUrlScheme
{
    NSArray* urlSchemeGroup = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];

    
    for (NSDictionary* dic in urlSchemeGroup)
    {
        NSArray* shemes = [dic objectForKey:@"CFBundleURLSchemes"];
        for (NSString* urlScheme in shemes)
        {
            if ([urlScheme isKindOfClass:[NSString class]] && [urlScheme hasPrefix:@"growing."])
            {
                return urlScheme;
            }
        }
    }
    return nil;
}

- (NSString*)deviceIDString
{
   pthread_mutex_lock(&_mutex);
    if (!_deviceIDString)
    {
        _deviceIDString = [self getDeviceIdString];
    }
    pthread_mutex_unlock(&_mutex);
    return _deviceIDString;
}

- (NSString *)idfv {
    if (!_idfv)
    {
        _idfv = [self getVendorId];
    }
    return _idfv;
}

- (NSString *)idfa {
    if (!_idfa)
    {
        _idfa = [self getUserIdentifier];
    }
    return _idfa;
}


- (BOOL)isNewInstall
{
    return ![self isSentDeviceInfoBefore];
}

- (BOOL)isPastedDeeplinkCallback
{
    return [self isPasteboardDeeplinkCallBack];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        _storePath = [self getStorePath];
        
        __weak typeof(self) wself = self;
        _deviceIDBlock = [^NSString*{
            NSString *userIdentifier = [wself getUserIdentifier];
            if (userIdentifier.growingHelper_isValidU) {
                return userIdentifier;
            } else {
                return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
            }
        } copy];

        pthread_mutex_init(&_mutex, NULL);
        NSString *bundleId = [Growing getBundleId];
        if (bundleId.length) {
            _bundleID = bundleId;
        } else {
            _bundleID = infoDictionary[@"CFBundleIdentifier"];
        }
        
        
        _displayName = infoDictionary[@"CFBundleDisplayName"] ?: infoDictionary[@"CFBundleName"];
        if (!_displayName) {
            _displayName = @"";
        }
        
        
        _language = [NSLocale preferredLanguages].firstObject?:@"";
        
        
        struct utsname systemInfo;
        uname(&systemInfo);
        _deviceModel = @(systemInfo.machine);
        
        
        _deviceBrand = @"Apple";
        
        
        _deviceType = [UIDevice currentDevice].model;
        
        
        _isPhone = [[_deviceType lowercaseString] rangeOfString:@"ipad"].length ? @0 : @1;
        
        
        _systemName = @"iOS"; 
        
        
        _systemVersion = [[UIDevice currentDevice] systemVersion];

        
        _appFullVersion = infoDictionary[@"CFBundleVersion"];
        if (!_appFullVersion)
        {
            _appFullVersion = @"";
        }
        
        
        _appShortVersion = infoDictionary[@"CFBundleShortVersionString"];
        
        
        NSTimeZone *timeZoneLocal = [NSTimeZone localTimeZone];
        long timezone = [timeZoneLocal secondsFromGMT] / 60l / 60l;
        if (timezone >= 0) {
            _timezone = [NSString stringWithFormat:@"+%ld", timezone];
        } else {
            _timezone = [NSString stringWithFormat:@"%ld", timezone];
        }
        
        
        NSString *urlScheme = [Growing getUrlScheme];
        _urlScheme = urlScheme ?: [self getCurrentUrlScheme];
        
        
        NSMutableDictionary *customDict = [[NSMutableDictionary alloc] init];
        [infoDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL * _Nonnull stop) {
            if ([key isKindOfClass:[NSString class]])
            {
                [customDict setValue:obj forKey:key.lowercaseString];
            }
        }];
        
        _configAccountID = [customDict valueForKey:@"growingaccountid"];
        
        GrowingEventDataBase * databaseOfUtm = [GrowingEventDataBase databaseWithName:@"user_install_time"];
        NSString * utmString = [databaseOfUtm valueForKey:@"utm"];
        if (utmString.length == 0)
        {
            utmString = [GROWGetTimestamp() stringValue];
            [databaseOfUtm setValue:utmString forKey:@"utm"];
        }
        _userInstallTime = [NSNumber numberWithLongLong:[utmString longLongValue]];
        
        [self resetSessionID];
        
    }
    return self;
}

- (NSString*)getStorePath
{
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"libGrowing"];
 
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    NSError *error = nil;
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    BOOL success = [fileUrl setResourceValue:@YES
                                      forKey:NSURLIsExcludedFromBackupKey
                                       error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", path, error);
    }

    return path;
}

#define GROWINGIO_KEYCHAIN_KEY  @"GROWINGIO_KEYCHAIN_KEY"
#define GROWINGIO_CUSTOM_U_KEY  @"GROWINGIO_CUSTOM_U_KEY"
- (NSString*)transferOldUUID
{
    
    NSString *deviceIDPath = [self.storePath stringByAppendingPathComponent:@"device"];

    
    NSString *deviceIdString = [NSString stringWithContentsOfFile:deviceIDPath
                                                         encoding:NSUTF8StringEncoding error:nil];
    
    return deviceIdString;
}

- (NSString*)getDeviceIdString
{
    
    if (self.customDeviceIDBlock)
    {
        __weak GrowingDeviceInfo* wself = self;
        NSString *customUUID = self.customDeviceIDBlock();
        if ([customUUID isKindOfClass:[NSString class]]
            && customUUID.length > 0
            && customUUID.length <= 64 && customUUID.growingHelper_isValidU)
        {
            
            [wself setKeychainObject:customUUID forKey:GROWINGIO_CUSTOM_U_KEY];
            return  customUUID;
        }
    } else
    {
        NSString *customDeviceIdString = [self keyChainObjectForKey:GROWINGIO_CUSTOM_U_KEY];
        
        if ([customDeviceIdString growingHelper_isValidU])
        {
            return customDeviceIdString;
        }
    }
    NSString *deviceIdString = [self keyChainObjectForKey:GROWINGIO_KEYCHAIN_KEY];
    
    if ([deviceIdString growingHelper_isValidU])
    {
        return deviceIdString;
    }
    
    
    NSString *uuid = [self transferOldUUID];
    
    
    if (!uuid.length && self.deviceIDBlock)
    {
        NSString *blockUUID = self.deviceIDBlock();
        if ([blockUUID isKindOfClass:[NSString class]]
            && blockUUID.length > 0
            && blockUUID.length <= 64)
        {
            uuid = blockUUID;
        }
    }
    
    
    if (!uuid.length || !uuid.growingHelper_isValidU)
    {
        uuid = [[NSUUID UUID] UUIDString];
    }
    
    [self setKeychainObject:uuid forKey:GROWINGIO_KEYCHAIN_KEY];
    
    return uuid;
}

- (NSString *)isSentDeviceInfoBeforePath
{
    return [self.storePath stringByAppendingPathComponent:@"isSentDeviceInfoBefore"];
}

- (NSString *)isPasteboardDeeplinkCallBackPath
{
    return [self.storePath stringByAppendingPathComponent:@"586719D4-62FF-4B23-A0C2-CD342438FB69"];
}

- (BOOL)isSentDeviceInfoBefore
{
    NSString *isSentDeviceInfoStateString = [NSString stringWithContentsOfFile: [self isSentDeviceInfoBeforePath]
                                                                      encoding:NSUTF8StringEncoding error:nil];
    return isSentDeviceInfoStateString != nil;
}

- (BOOL)isPasteboardDeeplinkCallBack
{
    NSString *isPasteboardDeeplinkCallBack = [NSString stringWithContentsOfFile:[self isPasteboardDeeplinkCallBackPath]
                                                                      encoding:NSUTF8StringEncoding error:nil];
    return isPasteboardDeeplinkCallBack.length > 0;
}
  
- (void)deviceInfoReported
{
    [[GrowingEventManager shareInstance] dispathInUpload:^{
        [[@"hasSent" dataUsingEncoding:NSUTF8StringEncoding] writeToFile: [self isSentDeviceInfoBeforePath] atomically:YES];
    }];
}

- (void)pasteboardDeeplinkReported
{
    [[GrowingEventManager shareInstance] dispathInUpload:^{
        [[@"yes" dataUsingEncoding:NSUTF8StringEncoding] writeToFile: [self isPasteboardDeeplinkCallBackPath] atomically:YES];
    }];
}

+ (instancetype)currentDeviceInfo
{
    static GrowingDeviceInfo *info = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        info = [[GrowingDeviceInfo alloc] init];
        info.isResetSIDByWillEnterForeground = NO;
        info.isApplicationInWillEnterForeground = NO;
    });
    return info;
}

- (NSString*)carrier
{
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    if (carrier)
    {
        return [NSString stringWithFormat:@"%@-%@", carrier.mobileCountryCode, carrier.mobileNetworkCode];
    }
    else
    {
        return @"unknown";
    }
}

- (void)resetSessionID
{
    _sessionID = [[NSUUID UUID] UUIDString];
}

- (NSString *)getVendorId {
    NSString *vendorId = nil;
        
    if (NSClassFromString(@"UIDevice")) {
        vendorId = [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
        
    return vendorId;
}

- (NSString *)getUserIdentifier {
    NSString *userIdentifier = @"";
#ifndef GROWINGIO_NO_IFA
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (!ASIdentifierManagerClass) {
        return userIdentifier;
    }

    SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
    id sharedManager = ((id(*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(
        ASIdentifierManagerClass, sharedManagerSelector);
    SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");

    NSUUID *uuid = ((NSUUID * (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(
        sharedManager, advertisingIdentifierSelector);
    userIdentifier = [uuid UUIDString];
    
    
    if ([userIdentifier hasPrefix:@"00000000"]) {
        userIdentifier = @"";
    }
#endif
    return userIdentifier;
}

@end
