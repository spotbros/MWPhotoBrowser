/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "mw_SDWebImageCompat.h"
#import "mw_SDWebImageOperation.h"

typedef enum
{
    mw_SDWebImageDownloaderLowPriority = 1 << 0,
    mw_SDWebImageDownloaderProgressiveDownload = 1 << 1,
    /**
     * By default, request prevent the of NSURLCache. With this flag, NSURLCache
     * is used with default policies.
     */
    mw_SDWebImageDownloaderUseNSURLCache = 1 << 2,
    /**
     * Call completion block with nil image/imageData if the image was read from NSURLCache
     * (to be combined with `SDWebImageDownloaderUseNSURLCache`).
     */
    mw_SDWebImageDownloaderIgnoreCachedResponse = 1 << 3
} mw_SDWebImageDownloaderOptions;

typedef enum
{
    mw_SDWebImageDownloaderFIFOExecutionOrder,
    /**
     * Default value. All download operations will execute in queue style (first-in-first-out).
     */
    mw_SDWebImageDownloaderLIFOExecutionOrder
    /**
     * All download operations will execute in stack style (last-in-first-out).
     */
} mw_SDWebImageDownloaderExecutionOrder;

extern NSString *const mw_SDWebImageDownloadStartNotification;
extern NSString *const mw_SDWebImageDownloadStopNotification;

typedef void(^mw_SDWebImageDownloaderProgressBlock)(NSUInteger receivedSize, long long expectedSize);
typedef void(^mw_SDWebImageDownloaderCompletedBlock)(UIImage *image, NSData *data, NSError *error, BOOL finished);

/**
 * Asynchronous downloader dedicated and optimized for image loading.
 */
@interface mw_SDWebImageDownloader : NSObject

@property (assign, nonatomic) NSInteger maxConcurrentDownloads;

/**
 * Changes download operations execution order. Default value is `SDWebImageDownloaderFIFOExecutionOrder`.
 */
@property (assign, nonatomic) mw_SDWebImageDownloaderExecutionOrder executionOrder;

+ (mw_SDWebImageDownloader *)sharedDownloader;

/**
 * Set a value for a HTTP header to be appended to each download HTTP request.
 *
 * @param value The value for the header field. Use `nil` value to remove the header.
 * @param field The name of the header field to set.
 */
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 * Returns the value of the specified HTTP header field.
 *
 * @return The value associated with the header field field, or `nil` if there is no corresponding header field.
 */
- (NSString *)valueForHTTPHeaderField:(NSString *)field;

/**
 * Creates a SDWebImageDownloader async downloader instance with a given URL
 *
 * The delegate will be informed when the image is finish downloaded or an error has happen.
 *
 * @see SDWebImageDownloaderDelegate
 *
 * @param url The URL to the image to download
 * @param options The options to be used for this download
 * @param progressBlock A block called repeatedly while the image is downloading
 * @param completedBlock A block called once the download is completed.
 *                  If the download succeeded, the image parameter is set, in case of error,
 *                  error parameter is set with the error. The last parameter is always YES
 *                  if SDWebImageDownloaderProgressiveDownload isn't use. With the
 *                  SDWebImageDownloaderProgressiveDownload option, this block is called
 *                  repeatedly with the partial image object and the finished argument set to NO
 *                  before to be called a last time with the full image and finished argument
 *                  set to YES. In case of error, the finished argument is always YES.
 *
 * @return A cancellable mw_SDWebImageOperation
 */
- (id<mw_SDWebImageOperation>)downloadImageWithURL:(NSURL *)url
                                        options:(mw_SDWebImageDownloaderOptions)options
                                       progress:(mw_SDWebImageDownloaderProgressBlock)progressBlock
                                      completed:(mw_SDWebImageDownloaderCompletedBlock)completedBlock;

@end
