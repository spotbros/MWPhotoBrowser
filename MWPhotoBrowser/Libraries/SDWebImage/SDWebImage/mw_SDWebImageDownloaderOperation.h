/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "mw_SDWebImageDownloader.h"
#import "mw_SDWebImageOperation.h"

@protocol mw_SDWebImageDownloaderOperationProtocol <mw_SDWebImageOperation>

- (id)initWithRequest:(NSURLRequest *)request
              options:(mw_SDWebImageDownloaderOptions)options
             progress:(mw_SDWebImageDownloaderProgressBlock)progressBlock
            completed:(mw_SDWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(void (^)(void))cancelBlock;

@end

@interface mw_SDWebImageDownloaderOperation : NSOperation <mw_SDWebImageDownloaderOperationProtocol>

@property (strong, nonatomic, readonly) NSURLRequest *request;
@property (assign, nonatomic, readonly) mw_SDWebImageDownloaderOptions options;

- (id)initWithRequest:(NSURLRequest *)request
              options:(mw_SDWebImageDownloaderOptions)options
             progress:(mw_SDWebImageDownloaderProgressBlock)progressBlock
            completed:(mw_SDWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(void (^)(void))cancelBlock;

@end
