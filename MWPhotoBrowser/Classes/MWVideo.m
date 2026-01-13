//
//  MWVideo.m
//  MWPhotoBrowser
//
//  Video support for MWPhotoBrowser
//

#import "MWVideo.h"
#import "MWPhotoBrowser.h"
#import "mw_SDWebImageManager.h"

@interface MWVideo ()

@property (nonatomic, strong) UIImage *underlyingThumbnail;
@property (nonatomic) BOOL loadingThumbnail;

@end

@implementation MWVideo

#pragma mark - Class Methods

+ (MWVideo *)videoWithURL:(NSURL *)url {
    return [[MWVideo alloc] initWithURL:url];
}

+ (MWVideo *)videoWithURL:(NSURL *)url thumbnailImage:(UIImage *)thumbnailImage {
    return [[MWVideo alloc] initWithURL:url thumbnailImage:thumbnailImage];
}

+ (MWVideo *)videoWithURL:(NSURL *)url thumbnailURL:(NSURL *)thumbnailURL {
    return [[MWVideo alloc] initWithURL:url thumbnailURL:thumbnailURL];
}

#pragma mark - Init

- (id)initWithURL:(NSURL *)url {
    if ((self = [super init])) {
        _videoURL = [url copy];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url thumbnailImage:(UIImage *)thumbnailImage {
    if ((self = [self initWithURL:url])) {
        _thumbnailImage = thumbnailImage;
        _underlyingThumbnail = thumbnailImage;
    }
    return self;
}

- (id)initWithURL:(NSURL *)url thumbnailURL:(NSURL *)thumbnailURL {
    if ((self = [self initWithURL:url])) {
        _thumbnailURL = [thumbnailURL copy];
    }
    return self;
}

#pragma mark - MWPhoto Protocol Methods

- (UIImage *)underlyingImage {
    // Return thumbnail if available
    return _underlyingThumbnail;
}

- (void)loadUnderlyingImageAndNotify {
    // If we already have a thumbnail, we're ready
    if (_underlyingThumbnail) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_LOADING_DID_END_NOTIFICATION
                                                            object:self];
        return;
    }
    
    // If we have a thumbnail URL, load it
    if (_thumbnailURL && !_loadingThumbnail) {
        _loadingThumbnail = YES;
        
        mw_SDWebImageManager *manager = [mw_SDWebImageManager sharedManager];
        [manager downloadWithURL:_thumbnailURL
                         options:0
                        progress:nil
                       completed:^(UIImage *image, NSError *error, mw_SDImageCacheType cacheType, BOOL finished) {
            self.underlyingThumbnail = image;
            self.loadingThumbnail = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_LOADING_DID_END_NOTIFICATION
                                                                object:self];
        }];
    } else {
        // No thumbnail, just signal ready
        [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_LOADING_DID_END_NOTIFICATION
                                                            object:self];
    }
}

- (void)unloadUnderlyingImage {
    // Keep thumbnail if it was provided directly
    if (!_thumbnailImage) {
        _underlyingThumbnail = nil;
    }
}

#pragma mark - Video Protocol Methods

- (BOOL)isVideo {
    return YES;
}

@end
