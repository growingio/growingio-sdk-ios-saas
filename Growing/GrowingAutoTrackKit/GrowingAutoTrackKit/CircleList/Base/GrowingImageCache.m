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


#import "GrowingImageCache.h"
#import "GrowingDeviceInfo.h"




@interface GrowingImageCacheItem : NSObject
@property (nonatomic, copy) NSString    *key;
@property (nonatomic, retain) UIImage   *image;
@end

@implementation GrowingImageCacheItem
@end

@interface GrowingImageCache ()<NSCacheDelegate>

@property (nonatomic, copy) NSString *path;

@property (nonatomic, retain) NSCache<NSString*,GrowingImageCacheItem*> *memCache;

@end


static void writeImageToPathWithName(UIImage *image,NSString* path,NSString *name)
{
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *filePath = [path stringByAppendingPathComponent:name];
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    [fileUrl setResourceValue:@YES
                       forKey:NSURLIsExcludedFromBackupKey
                        error:nil];
    [imageData writeToFile:filePath atomically:YES];
}

static UIImage* loadImageToPathWithName(NSString* path,NSString *name)
{
    NSString *filePath = [path stringByAppendingPathComponent:name];
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    return image;
}

@implementation GrowingImageCache

- (instancetype)init
{
    NSString *path = [[GrowingDeviceInfo currentDeviceInfo].storePath stringByAppendingPathComponent:@"imageCache"];
    return [self initWithDirPath:path];
}

- (instancetype)initWithDirPath:(NSString *)path
{
    self = [super init];
    if (self)
    {
        self.path = path;
        self.memCache = [[NSCache alloc] init];
        self.memCache.delegate = self;
        self.memCache.countLimit = 10;
    }
    return self;
}

- (void)cache:(NSCache *)cache willEvictObject:(GrowingImageCacheItem*)obj
{
    NSString *path = self.path ;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        writeImageToPathWithName(obj.image, path, obj.key);
    });
}

- (void)saveImage:(UIImage *)image forKey:(NSString *)key
{
    GrowingImageCacheItem *item = [[GrowingImageCacheItem alloc] init];
    item.image = image;
    item.key = key;
    [self.memCache setObject:item forKey:key];
}

- (void)loadImageForKey:(NSString *)key onFinish:(void (^)(UIImage *))onFinish
{
    GrowingImageCacheItem *item = [self.memCache objectForKey:key];
    
    if (item)
    {
        if (onFinish)
        {
            onFinish(item.image);
        }
        return;
    }

    
    NSString *path = self.path;
    onFinish = [onFinish copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = loadImageToPathWithName(path, key);
        dispatch_async(dispatch_get_main_queue(), ^{
            onFinish(image);
        });
    });
}

- (void)clearAllImage
{
    [self.memCache removeAllObjects];
    NSString *path = self.path;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    });
}

@end

@interface GrowingImageCacheImage()

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, retain) GrowingImageCache *cache;

@end


@implementation GrowingImageCacheImage

+ (instancetype)imageWithCache:(GrowingImageCache *)cache image:(UIImage *)image
{
    id obj = [[self alloc] init];
    if (obj)
    {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        [obj setCache:cache];
        [obj setImageSize:image.size];
        [obj setUuid:uuid];
        [cache saveImage:image forKey:uuid];
    }
    return obj;
}

- (void)loadImage:(void (^)(UIImage *))loadFinish
{
    [self.cache loadImageForKey:self.uuid onFinish:loadFinish];
}

@end
