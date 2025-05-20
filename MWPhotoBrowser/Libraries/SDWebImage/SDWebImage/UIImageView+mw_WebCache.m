/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+mw_WebCache.h"
#import "objc/runtime.h"

static char operationKey;
static char operationArrayKey;

@implementation UIImageView (mw_WebCache)

- (void)mw_setImageWithURL:(NSURL *)url
{
    [self mw_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)mw_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    [self mw_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)mw_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(mw_SDWebImageOptions)options
{
    [self mw_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)mw_setImageWithURL:(NSURL *)url completed:(mw_SDWebImageCompletedBlock)completedBlock
{
    [self mw_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)mw_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(mw_SDWebImageCompletedBlock)completedBlock
{
    [self mw_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)mw_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(mw_SDWebImageOptions)options completed:(mw_SDWebImageCompletedBlock)completedBlock
{
    [self mw_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)mw_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(mw_SDWebImageOptions)options progress:(mw_SDWebImageDownloaderProgressBlock)progressBlock completed:(mw_SDWebImageCompletedBlock)completedBlock
{
    [self mw_cancelCurrentImageLoad];

    self.image = placeholder;
    
    if (url)
    {
        __weak UIImageView *wself = self;
        id<mw_SDWebImageOperation> operation = [mw_SDWebImageManager.sharedManager downloadWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished)
        {
            if (!wself) return;
            dispatch_main_sync_safe(^
            {
                if (!wself) return;
                if (image)
                {
                    wself.image = image;
                    [wself setNeedsLayout];
                }
                if (completedBlock && finished)
                {
                    completedBlock(image, error, cacheType);
                }
            });
        }];
        objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)mw_setAnimationImagesWithURLs:(NSArray *)arrayOfURLs
{
    [self mw_cancelCurrentArrayLoad];
    __weak UIImageView *wself = self;

    NSMutableArray *operationsArray = [[NSMutableArray alloc] init];

    for (NSURL *logoImageURL in arrayOfURLs)
    {
        id<mw_SDWebImageOperation> operation = [mw_SDWebImageManager.sharedManager downloadWithURL:logoImageURL options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished)
        {
            if (!wself) return;
            dispatch_main_sync_safe(^
            {
                __strong UIImageView *sself = wself;
                [sself stopAnimating];
                if (sself && image)
                {
                    NSMutableArray *currentImages = [[sself animationImages] mutableCopy];
                    if (!currentImages)
                    {
                        currentImages = [[NSMutableArray alloc] init];
                    }
                    [currentImages addObject:image];

                    sself.animationImages = currentImages;
                    [sself setNeedsLayout];
                }
                [sself startAnimating];
            });
        }];
        [operationsArray addObject:operation];
    }

    objc_setAssociatedObject(self, &operationArrayKey, [NSArray arrayWithArray:operationsArray], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)mw_cancelCurrentImageLoad
{
    // Cancel in progress downloader from queue
    id<mw_SDWebImageOperation> operation = objc_getAssociatedObject(self, &operationKey);
    if (operation)
    {
        [operation cancel];
        objc_setAssociatedObject(self, &operationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)mw_cancelCurrentArrayLoad
{
    // Cancel in progress downloader from queue
    NSArray *operations = objc_getAssociatedObject(self, &operationArrayKey);
    for (id<mw_SDWebImageOperation> operation in operations)
    {
        if (operation)
        {
            [operation cancel];
        }
    }
    objc_setAssociatedObject(self, &operationArrayKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
