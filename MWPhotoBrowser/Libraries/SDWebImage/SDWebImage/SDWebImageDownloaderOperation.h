/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageDownloader.h"
#import "SDWebImageOperation.h"

@protocol SDWebImageDownloaderOperationProtocol <SDWebImageOperation>

- (id)initWithRequest:(NSURLRequest *)request
              options:(SDWebImageDownloaderOptions)options
             progress:(SDWebImageDownloaderProgressBlock)progressBlock
            completed:(SDWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(void (^)(void))cancelBlock;

@end

@interface SDWebImageDownloaderOperation : NSOperation <SDWebImageDownloaderOperationProtocol>

@property (strong, nonatomic, readonly) NSURLRequest *request;
@property (assign, nonatomic, readonly) SDWebImageDownloaderOptions options;

- (id)initWithRequest:(NSURLRequest *)request
              options:(SDWebImageDownloaderOptions)options
             progress:(SDWebImageDownloaderProgressBlock)progressBlock
            completed:(SDWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(void (^)(void))cancelBlock;

@end
