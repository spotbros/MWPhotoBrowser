//
//  CustomImageDownloaderOperation.m
//  SpotBros
//
//  Created by Spotbros S.L. on 30/11/2017.
//  Copyright © 2017 SpotBros. All rights reserved.
//

#import "CustomImageDownloaderOperation.h"
#import "ThumbnailCacheManagerOperation.h"
#import "SDWebImageDecoder.h"
#import "UIImage+MultiFormat.h"
#import <ImageIO/ImageIO.h>

@interface CustomImageDownloaderOperation ()

@property (copy, nonatomic) SDWebImageDownloaderProgressBlock progressBlock;
@property (copy, nonatomic) SDWebImageDownloaderCompletedBlock completedBlock;
@property (copy, nonatomic) void (^cancelBlock)(void);

@end

@implementation CustomImageDownloaderOperation

- (id)initWithRequest:(NSURLRequest *)request options:(SDWebImageDownloaderOptions)options progress:(void (^)(NSUInteger, long long))progressBlock completed:(void (^)(UIImage *, NSData *, NSError *, BOOL))completedBlock cancelled:(void (^)(void))cancelBlock
{
    if ((self = [super init]))
    {
        _request = request;
        _options = options;
        _progressBlock = progressBlock;
        _completedBlock = completedBlock;
        _cancelBlock = cancelBlock;
        
    }
    return self;
}

- (void)main
{
    ThumbnailCacheManagerOperation *customOp = [ThumbnailCacheManagerOperation requestThumbnailOperationWithURL:_request.URL
                                                                                                        success:^(UIImage *image, NSURL *url) {
        dispatch_main_sync_safe(^{
            if (self->_completedBlock) {
                self->_completedBlock(image, nil, nil, YES);
            }
        });
    }
                                                                                                           fail:^(NSURL *url, NSError *error) {
        dispatch_main_sync_safe(^{
            if (self->_completedBlock) {
                self->_completedBlock(nil, nil, error, YES);
            }
        });
    }];
    
    [customOp start];
}

@end

