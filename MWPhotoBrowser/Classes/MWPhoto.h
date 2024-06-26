//
//  MWPhoto.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 17/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWPhotoProtocol.h"

typedef enum {
    MWPhotoCacheMemoryOnly = 1 << 0,
    MWPhotoRefreshCached = 1 << 1
} MWPhotoOptions;

// This class models a photo/image and it's caption
// If you want to handle photos, caching, decompression
// yourself then you can simply ensure your custom data model
// conforms to MWPhotoProtocol
@interface MWPhoto : NSObject <MWPhoto>

// Properties
@property (nonatomic, strong) NSString *caption;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSURL *photoURL;
@property (nonatomic, readonly) NSString *filePath  __attribute__((deprecated("Use photoURL"))); // Depreciated

// Class
+ (MWPhoto *)photoWithImage:(UIImage *)image;
+ (MWPhoto *)photoWithFilePath:(NSString *)path  __attribute__((deprecated("Use photoWithURL: with a file URL"))); // Depreciated
+ (MWPhoto *)photoWithURL:(NSURL *)url;
+ (MWPhoto *)photoWithURL:(NSURL *)url options:(MWPhotoOptions)options;

// Init
- (id)initWithImage:(UIImage *)image;
- (id)initWithURL:(NSURL *)url;
- (id)initWithURL:(NSURL *)url options:(MWPhotoOptions)options;
- (id)initWithFilePath:(NSString *)path  __attribute__((deprecated("Use initWithURL: with a file URL"))); // Depreciated

@end

