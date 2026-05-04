//
//  ZoomingScrollView.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "App-Swift.h"
#import "MWCommon.h"
#import "MWZoomingScrollView.h"
#import "MWPhotoBrowser.h"
#import "MWPhoto.h"
#import "DACircularProgressView.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

// VLC fallback for video formats unsupported by AVFoundation (e.g. MPEG-1/2, MKV, AVI).
// Compiled in only when MobileVLCKit is available so the photo browser can be built
// without the dependency.
#if __has_include(<MobileVLCKit/MobileVLCKit.h>)
#import <MobileVLCKit/MobileVLCKit.h>
#define MWZ_HAS_VLC 1
#endif

// Declare private methods of browser
@interface MWPhotoBrowser ()
- (UIImage *)imageForPhoto:(id<MWPhoto>)photo;
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
- (void)videoDidStartPlayingAtIndex:(NSUInteger)index;
@end

// Private methods and properties
@interface MWZoomingScrollView ()
#ifdef MWZ_HAS_VLC
    <VLCMediaPlayerDelegate>
#endif
{

	MWTapDetectingView *_tapView; // for background taps
	MWTapDetectingImageView *_photoImageView;
	DACircularProgressView *_loadingIndicator;

    // Video support
    UIView *_videoContainerView;
    UIImageView *_videoThumbnailImageView;
    AVPlayerViewController *_playerViewController;
    UIButton *_playButton;
    UIActivityIndicatorView *_videoLoadingIndicator;
    UILabel *_videoErrorLabel;
    BOOL _isShowingVideo;
    BOOL _isVideoPlaying;
    id _videoStartTimeObserver;

#ifdef MWZ_HAS_VLC
    // VLC fallback
    VLCMediaPlayer *_vlcPlayer;
    UIView *_vlcDrawableView;
    UITapGestureRecognizer *_vlcTapRecognizer;
#endif

}

@property (nonatomic, weak) MWPhotoBrowser *photoBrowser;

- (void)handleSingleTap:(CGPoint)touchPoint;
- (void)handleDoubleTap:(CGPoint)touchPoint;

// Video methods
- (void)displayVideo;
- (void)cleanupVideo;
- (void)playButtonTapped:(id)sender;
- (BOOL)isDisplayingVideo;

@end

@implementation MWZoomingScrollView

- (id)initWithPhotoBrowser:(MWPhotoBrowser *)browser {
    if ((self = [super init])) {
        
        // Delegate
        self.photoBrowser = browser;
        
		// Tap view for background
		_tapView = [[MWTapDetectingView alloc] initWithFrame:self.bounds];
		_tapView.tapDelegate = self;
		_tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_tapView.backgroundColor = [UIColor blackColor];
		[self addSubview:_tapView];
		
		// Image view
		_photoImageView = [[MWTapDetectingImageView alloc] initWithFrame:CGRectZero];
		_photoImageView.tapDelegate = self;
		_photoImageView.contentMode = UIViewContentModeCenter;
		_photoImageView.backgroundColor = [UIColor blackColor];
		[self addSubview:_photoImageView];
		
		// Loading indicator
		_loadingIndicator = [[DACircularProgressView alloc] initWithFrame:CGRectMake(140.0f, 30.0f, 40.0f, 40.0f)];
        _loadingIndicator.userInteractionEnabled = NO;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7")) {
            _loadingIndicator.thicknessRatio = 0.1;
            _loadingIndicator.roundedCorners = NO;
        } else {
            _loadingIndicator.thicknessRatio = 0.2;
            _loadingIndicator.roundedCorners = YES;
        }
		_loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
		[self addSubview:_loadingIndicator];
        
        // Video container view
        _videoContainerView = [[UIView alloc] initWithFrame:self.bounds];
        _videoContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _videoContainerView.backgroundColor = [UIColor blackColor];
        _videoContainerView.hidden = YES;
        [self addSubview:_videoContainerView];
        
        // Video thumbnail image view
        _videoThumbnailImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _videoThumbnailImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _videoThumbnailImageView.contentMode = UIViewContentModeScaleAspectFit;
        _videoThumbnailImageView.backgroundColor = [UIColor blackColor];
        _videoThumbnailImageView.hidden = YES;
        [_videoContainerView addSubview:_videoThumbnailImageView];
        
        // Play button for video
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playButton.frame = CGRectMake(0, 0, 80, 80);
        _playButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                                       UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_playButton setImage:[UIImage systemImageNamed:@"play.circle.fill"] forState:UIControlStateNormal];
        _playButton.tintColor = [UIColor whiteColor];
        _playButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
        _playButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
        [_playButton addTarget:self action:@selector(playButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        _playButton.hidden = YES;
        [_videoContainerView addSubview:_playButton];
        
        // Video loading indicator
        _videoLoadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        _videoLoadingIndicator.color = [UIColor whiteColor];
        _videoLoadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                                                  UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _videoLoadingIndicator.hidesWhenStopped = YES;
        [_videoContainerView addSubview:_videoLoadingIndicator];

        // Video error label (with translucent background so it stays readable on light thumbnails)
        _videoErrorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _videoErrorLabel.textColor = [UIColor whiteColor];
        _videoErrorLabel.font = [UIFont systemFontOfSize:15];
        _videoErrorLabel.textAlignment = NSTextAlignmentCenter;
        _videoErrorLabel.numberOfLines = 0;
        _videoErrorLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
        _videoErrorLabel.layer.cornerRadius = 8.0;
        _videoErrorLabel.layer.masksToBounds = YES;
        _videoErrorLabel.hidden = YES;
        [_videoContainerView addSubview:_videoErrorLabel];

        // Listen progress notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setProgressFromNotification:)
                                                     name:MWPHOTO_PROGRESS_NOTIFICATION
                                                   object:nil];
        
		// Setup
		self.backgroundColor = [UIColor blackColor];
		self.delegate = self;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        // Video state
        _isShowingVideo = NO;
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cleanupVideo];
}

- (void)setPhoto:(id<MWPhoto>)photo {
    // Cleanup previous content
    _photoImageView.image = nil;
    [self cleanupVideo];
    
    if (_photo != photo) {
        _photo = photo;
    }
    
    // Check if this is a video
    if (_photo && [_photo respondsToSelector:@selector(isVideo)] && [_photo isVideo]) {
        [self displayVideo];
    } else {
        [self displayImage];
    }
}

- (void)prepareForReuse {
    [self cleanupVideo];
    self.photo = nil;
    [_captionView removeFromSuperview];
    self.captionView = nil;
}

- (BOOL)isDisplayingVideo {
    return _isShowingVideo;
}

#pragma mark - Image

// Get and display image
- (void)displayImage {
    [self displayImage:YES];
}

- (void)displayImage:(BOOL)force {
	if (_photo && (_photoImageView.image == nil || force)) {
		
		// Reset
		self.maximumZoomScale = 1;
		self.minimumZoomScale = 1;
		self.zoomScale = 1;
		self.contentSize = CGSizeMake(0, 0);
		
		// Get image from browser as it handles ordering of fetching
		UIImage *img = [self.photoBrowser imageForPhoto:_photo];
		if (img) {
			
			// Hide indicator
			[self hideLoadingIndicator];
			
			// Set image
			_photoImageView.image = img;
            
            if (@available(iOS 16.0, *)) {
                if ([LiveTextHelper isSupported]) {
                    for (id<UIInteraction> inter in [_photoImageView.interactions copy]) {
                        [_photoImageView removeInteraction:inter];
                    }
                    [LiveTextHelper addLiveTextTo:_photoImageView delegate:self];
                }
            }
            
			_photoImageView.hidden = NO;
			
			// Setup photo frame
			CGRect photoImageViewFrame;
			photoImageViewFrame.origin = CGPointZero;
			photoImageViewFrame.size = img.size;
			_photoImageView.frame = photoImageViewFrame;
			self.contentSize = photoImageViewFrame.size;

			// Set zoom to minimum zoom
			[self setMaxMinZoomScalesForCurrentBounds];
			
		} else {
			
			// Hide image view
			_photoImageView.hidden = YES;
			[self showLoadingIndicator];
			
		}
		[self setNeedsLayout];
	}
}

// Image failed so just show black!
- (void)displayImageFailure {
    [self hideLoadingIndicator];
}

#pragma mark - Video

- (void)displayVideo {
    if (!_photo || ![_photo respondsToSelector:@selector(videoURL)]) {
        return;
    }
    
    _isShowingVideo = YES;
    
    // Hide photo views
    _photoImageView.hidden = YES;
    [self hideLoadingIndicator];
    
    // Show video container
    _videoContainerView.hidden = NO;
    _videoContainerView.frame = self.bounds;
    
    // Show thumbnail if available
    UIImage *thumbnail = [self.photoBrowser imageForPhoto:_photo];
    if (thumbnail) {
        _videoThumbnailImageView.image = thumbnail;
        _videoThumbnailImageView.frame = _videoContainerView.bounds;
        _videoThumbnailImageView.hidden = NO;
    } else {
        _videoThumbnailImageView.hidden = YES;
    }
    
    // Center play button
    _playButton.center = CGPointMake(_videoContainerView.bounds.size.width / 2.0,
                                     _videoContainerView.bounds.size.height / 2.0);
    _playButton.hidden = NO;
    _videoErrorLabel.hidden = YES;

    // Center video loading indicator
    _videoLoadingIndicator.center = _playButton.center;
    
    // Disable zoom for video
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    self.scrollEnabled = NO;
    
    [self setNeedsLayout];
}

- (void)playVideo {
    [self playVideoMuted:NO];
}

- (void)playVideoMuted:(BOOL)muted {
    if (!_photo || ![_photo respondsToSelector:@selector(videoURL)]) {
        return;
    }
    
    NSURL *videoURL = [_photo videoURL];
    if (!videoURL) {
        return;
    }
    
    // Hide play button, keep thumbnail visible until video starts
    _playButton.hidden = YES;
    [_videoLoadingIndicator startAnimating];
    
    // Create player view controller if needed
    if (!_playerViewController) {
        AVPlayer *player = [AVPlayer playerWithURL:videoURL];
        player.muted = muted;
        
        _playerViewController = [[AVPlayerViewController alloc] init];
        _playerViewController.player = player;
        _playerViewController.showsPlaybackControls = YES;
        _playerViewController.videoGravity = AVLayerVideoGravityResizeAspect;
        _playerViewController.allowsPictureInPicturePlayback = NO;
        
        // Add player view to container but keep it hidden until video is ready
        _playerViewController.view.frame = _videoContainerView.bounds;
        _playerViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _playerViewController.view.backgroundColor = [UIColor blackColor];
        _playerViewController.view.hidden = YES; // Hidden until video actually starts
        [_videoContainerView addSubview:_playerViewController.view];
        
        // Observe player status
        [player.currentItem addObserver:self
                             forKeyPath:@"status"
                                options:NSKeyValueObservingOptionNew
                                context:nil];
        
        // Observe when video ends
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(videoDidFinishPlaying:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:player.currentItem];
    } else {
        // Player already exists, seek to start and play
        _playerViewController.player.muted = muted;
        [_playerViewController.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_videoLoadingIndicator stopAnimating];
                self->_videoThumbnailImageView.hidden = YES;
                self->_playerViewController.view.hidden = NO;
                [self->_playerViewController.player play];
                self->_isVideoPlaying = YES;
                [self->_photoBrowser videoDidStartPlayingAtIndex:self.tag - 1000];
            });
        }];
    }
}

- (void)pauseVideo {
#ifdef MWZ_HAS_VLC
    if (_vlcPlayer) {
        [_vlcPlayer pause];
        _isVideoPlaying = NO;
        return;
    }
#endif
    if (_playerViewController.player) {
        [_playerViewController.player pause];
        _isVideoPlaying = NO;
    }
}

- (void)cleanupVideo {
    _isShowingVideo = NO;
    _isVideoPlaying = NO;

    [self teardownAVPlayer];

#ifdef MWZ_HAS_VLC
    [self teardownVLCPlayer];
#endif

    // Hide video views
    _videoContainerView.hidden = YES;
    _videoThumbnailImageView.image = nil;
    _videoThumbnailImageView.hidden = YES;
    _playButton.hidden = YES;
    [_videoLoadingIndicator stopAnimating];
    _videoErrorLabel.hidden = YES;

    // Re-enable zoom
    self.scrollEnabled = YES;
}

- (void)playButtonTapped:(id)sender {
    [self playVideo];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            // Video is ready, start playing
            [_playerViewController.player play];
            _isVideoPlaying = YES;
            
            // Remove previous time observer if any
            if (_videoStartTimeObserver) {
                [_playerViewController.player removeTimeObserver:_videoStartTimeObserver];
                _videoStartTimeObserver = nil;
            }
            
            // Add a time observer to hide thumbnail once video actually starts rendering
            __weak typeof(self) weakSelf = self;
            _videoStartTimeObserver = [_playerViewController.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) // ~33ms
                                                                                     queue:dispatch_get_main_queue()
                                                                                usingBlock:^(CMTime time) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (strongSelf && CMTimeGetSeconds(time) > 0.05) {
                    // Video has started playing, now hide thumbnail and show player
                    [strongSelf->_videoLoadingIndicator stopAnimating];
                    strongSelf->_videoThumbnailImageView.hidden = YES;
                    strongSelf->_playerViewController.view.hidden = NO;
                    
                    // Remove this observer, we only need it once
                    if (strongSelf->_videoStartTimeObserver) {
                        [strongSelf->_playerViewController.player removeTimeObserver:strongSelf->_videoStartTimeObserver];
                        strongSelf->_videoStartTimeObserver = nil;
                    }
                    
                    [strongSelf->_photoBrowser videoDidStartPlayingAtIndex:strongSelf.tag - 1000];
                }
            }];
        } else if (playerItem.status == AVPlayerItemStatusFailed) {
            MWLog(@"AVFoundation failed to load video: %@", playerItem.error);
            NSURL *failedURL = nil;
            if ([playerItem.asset isKindOfClass:[AVURLAsset class]]) {
                failedURL = ((AVURLAsset *)playerItem.asset).URL;
            }
            // Defer teardown to next runloop turn so we don't remove a KVO observer
            // from inside its own callback. Capture the photo so we can bail if the
            // cell has been reused for a different one in the meantime.
            id<MWPhoto> photoAtFailure = _photo;
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf || strongSelf->_photo != photoAtFailure) return;
                [strongSelf teardownAVPlayer];
#ifdef MWZ_HAS_VLC
                if (failedURL) {
                    [strongSelf playVideoWithVLCAtURL:failedURL];
                } else {
                    [strongSelf showVideoFormatError];
                }
#else
                [strongSelf showVideoFormatError];
#endif
            });
        }
    }
}

- (void)videoDidFinishPlaying:(NSNotification *)notification {
    // Show play button and thumbnail again when video ends
    _isVideoPlaying = NO;
    _playButton.hidden = NO;
    _videoThumbnailImageView.hidden = NO;
    _playerViewController.view.hidden = YES;
    [_playerViewController.player seekToTime:kCMTimeZero completionHandler:nil];
}

#pragma mark - Video error / fallback

- (void)showVideoFormatError {
    [_videoLoadingIndicator stopAnimating];
    _playButton.hidden = YES;
    _videoThumbnailImageView.hidden = NO;
    _videoErrorLabel.text = NSLocalizedString(@"video_format_not_supported", nil);
    _videoErrorLabel.hidden = NO;
    [self setNeedsLayout];
}

// Tears down the AVPlayer-based stack without touching the video container or thumbnail.
// Used when we want to swap to the VLC fallback for the same playback session.
- (void)teardownAVPlayer {
    if (_videoStartTimeObserver && _playerViewController.player) {
        [_playerViewController.player removeTimeObserver:_videoStartTimeObserver];
        _videoStartTimeObserver = nil;
    }
    if (_playerViewController.player.currentItem) {
        @try {
            [_playerViewController.player.currentItem removeObserver:self forKeyPath:@"status"];
        } @catch (NSException *exception) {
            // Observer was not registered
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:_playerViewController.player.currentItem];
    }
    [_playerViewController.player pause];
    [_playerViewController.view removeFromSuperview];
    _playerViewController = nil;
}

#ifdef MWZ_HAS_VLC

- (void)playVideoWithVLCAtURL:(NSURL *)url {
    if (!_vlcDrawableView) {
        _vlcDrawableView = [[UIView alloc] initWithFrame:_videoContainerView.bounds];
        _vlcDrawableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _vlcDrawableView.backgroundColor = [UIColor blackColor];
        _vlcDrawableView.hidden = YES;
        [_videoContainerView addSubview:_vlcDrawableView];

        _vlcTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(vlcViewTapped:)];
        [_vlcDrawableView addGestureRecognizer:_vlcTapRecognizer];
    }

    if (!_vlcPlayer) {
        _vlcPlayer = [[VLCMediaPlayer alloc] init];
        _vlcPlayer.delegate = self;
        _vlcPlayer.drawable = _vlcDrawableView;
    }

    _videoErrorLabel.hidden = YES;
    [_videoLoadingIndicator startAnimating];
    _vlcPlayer.media = [VLCMedia mediaWithURL:url];
    [_vlcPlayer play];
}

- (void)teardownVLCPlayer {
    if (_vlcPlayer) {
        [_vlcPlayer stop];
        _vlcPlayer.delegate = nil;
        _vlcPlayer.drawable = nil;
        _vlcPlayer.media = nil;
        _vlcPlayer = nil;
    }
    [_vlcDrawableView removeFromSuperview];
    _vlcDrawableView = nil;
    _vlcTapRecognizer = nil;
}

- (void)vlcViewTapped:(UITapGestureRecognizer *)recognizer {
    if (!_vlcPlayer) return;
    if (_vlcPlayer.isPlaying) {
        [_vlcPlayer pause];
        _isVideoPlaying = NO;
    } else {
        [_vlcPlayer play];
        _isVideoPlaying = YES;
    }
}

#pragma mark - VLCMediaPlayerDelegate

- (void)mediaPlayerStateChanged:(NSNotification *)notification {
    if (!_vlcPlayer) return;
    switch (_vlcPlayer.state) {
        case VLCMediaPlayerStateError: {
            MWLog(@"VLC failed to play video as well, giving up.");
            [self teardownVLCPlayer];
            [self showVideoFormatError];
            break;
        }
        case VLCMediaPlayerStateEnded: {
            _isVideoPlaying = NO;
            _vlcDrawableView.hidden = YES;
            _videoThumbnailImageView.hidden = NO;
            _playButton.hidden = NO;
            break;
        }
        default:
            break;
    }
    // Note: we deliberately don't react to VLCMediaPlayerStatePlaying here.
    // VLC enters that state during demuxing/buffering, before any frame has
    // been rendered to the GL surface — swapping the thumbnail for the drawable
    // at that point causes a visible black flash. We swap on the first time
    // tick instead (see mediaPlayerTimeChanged:).
}

- (void)mediaPlayerTimeChanged:(NSNotification *)notification {
    if (!_vlcPlayer || !_vlcDrawableView.hidden) return;
    if (_vlcPlayer.time.intValue <= 0) return;
    [_videoLoadingIndicator stopAnimating];
    _videoThumbnailImageView.hidden = YES;
    _vlcDrawableView.hidden = NO;
    _isVideoPlaying = YES;
    [_photoBrowser videoDidStartPlayingAtIndex:self.tag - 1000];
}

#endif

#pragma mark - Loading Progress

- (void)setProgressFromNotification:(NSNotification *)notification {
    NSDictionary *dict = [notification object];
    MWPhoto *photoWithProgress = (MWPhoto *)[dict objectForKey:@"photo"];
    if (photoWithProgress == self.photo) {
        float progress = [[dict valueForKey:@"progress"] floatValue];
        _loadingIndicator.progress = MAX(MIN(1, progress), 0);
    }
}

- (void)hideLoadingIndicator {
    _loadingIndicator.hidden = YES;
}

- (void)showLoadingIndicator {
    _loadingIndicator.progress = 0;
    _loadingIndicator.hidden = NO;
}

#pragma mark - Setup

- (void)setMaxMinZoomScalesForCurrentBounds {
	
	// Reset
	self.maximumZoomScale = 1;
	self.minimumZoomScale = 1;
	self.zoomScale = 1;
	
	// Bail
	if (_photoImageView.image == nil) return;
	
	// Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.frame.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible

    // Calculate Max
	CGFloat maxScale = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Let them go a bit bigger on a bigger screen!
        maxScale = 4;
    }
    
    // Image is smaller than screen so no zooming!
	if (xScale >= 1 && yScale >= 1) {
		minScale = 1.0;
	}

    // Initial zoom
    CGFloat zoomScale = minScale;
    if (self.photoBrowser.zoomPhotosToFill) {
        // Zoom image to fill if the aspect ratios are fairly similar
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        CGFloat imageAR = imageSize.width / imageSize.height;
        if (ABS(boundsAR - imageAR) < 0.3) {
            zoomScale = MAX(xScale, yScale);
            // Ensure we don't zoom in or out too far, just in case
            zoomScale = MIN(MAX(minScale, zoomScale), maxScale);
        }
    }
	
	// Set
	self.maximumZoomScale = maxScale;
	self.minimumZoomScale = minScale;
	self.zoomScale = zoomScale;
    
	// Reset position
	_photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
    
    // If we're zooming to fill then centralise
    if (zoomScale != minScale) {
        // Centralise
        self.contentOffset = CGPointMake((imageSize.width * zoomScale - boundsSize.width) / 2.0,
                                         (imageSize.height * zoomScale - boundsSize.height) / 2.0);
        // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
        self.scrollEnabled = NO;
    }
    
    // Layout
	[self setNeedsLayout];

}

#pragma mark - Layout

- (void)layoutSubviews {
	
	// Update tap view frame
	_tapView.frame = self.bounds;
	
	// Indicator
	if (!_loadingIndicator.hidden)
        _loadingIndicator.center = CGPointMake(floorf(self.bounds.size.width/2.0),
                                               floorf(self.bounds.size.height/2.0));
    
    // Video layout
    if (_isShowingVideo) {
        _videoContainerView.frame = self.bounds;
        _videoThumbnailImageView.frame = _videoContainerView.bounds;
        _playButton.center = CGPointMake(floorf(self.bounds.size.width/2.0),
                                         floorf(self.bounds.size.height/2.0));
        _videoLoadingIndicator.center = _playButton.center;
        if (!_videoErrorLabel.hidden) {
            CGFloat paddingX = 14.0;
            CGFloat paddingY = 10.0;
            CGFloat maxWidth = MAX(0, _videoContainerView.bounds.size.width - 40);
            CGSize textSize = [_videoErrorLabel sizeThatFits:CGSizeMake(maxWidth - paddingX * 2, CGFLOAT_MAX)];
            CGRect labelFrame = CGRectMake(0, 0,
                                           ceilf(textSize.width) + paddingX * 2,
                                           ceilf(textSize.height) + paddingY * 2);
            _videoErrorLabel.bounds = labelFrame;
            _videoErrorLabel.center = CGPointMake(_videoContainerView.bounds.size.width / 2.0,
                                                  _videoContainerView.bounds.size.height / 2.0);
        }
        if (_playerViewController) {
            _playerViewController.view.frame = _videoContainerView.bounds;
        }
    }
    
	// Super
	[super layoutSubviews];
	
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
	} else {
        frameToCenter.origin.x = 0;
	}
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
	} else {
        frameToCenter.origin.y = 0;
	}
    
	// Center
	if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter))
		_photoImageView.frame = frameToCenter;
	
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[_photoBrowser cancelControlHiding];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.scrollEnabled = YES; // reset
	[_photoBrowser cancelControlHiding];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!kMWPhotoBrowserAlwaysShowTools) {
        [_photoBrowser hideControlsAfterDelay];
    }
}

#pragma mark - Tap Detection

- (void)handleSingleTap:(CGPoint)touchPoint {
    if (!kMWPhotoBrowserAlwaysShowTools) {
        [_photoBrowser performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2];
    }
}

- (void)handleDoubleTap:(CGPoint)touchPoint {
	
	// Cancel any single tap handling
	[NSObject cancelPreviousPerformRequestsWithTarget:_photoBrowser];
	
	// Zoom
	if (self.zoomScale == self.maximumZoomScale) {
		
		// Zoom out
		[self setZoomScale:self.minimumZoomScale animated:YES];
		
	} else {
		
		// Zoom in
        CGFloat newZoomScale;
        if (((self.zoomScale - self.minimumZoomScale) / self.maximumZoomScale) >= 0.3) { // we're zoomed in a fair bit, so zoom to max now
            // Go to max zoom
            newZoomScale = self.maximumZoomScale;
        } else {
            // Zoom to 50%
            newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        }
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];

	}
	
	// Delay controls
    if (!kMWPhotoBrowserAlwaysShowTools) {
        [_photoBrowser hideControlsAfterDelay];
    }
	
}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch { 
    [self handleSingleTap:[touch locationInView:imageView]];
}
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch {
    [self handleDoubleTap:[touch locationInView:imageView]];
}

// Background View
- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleSingleTap:CGPointMake(touchX, touchY)];
}
- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleDoubleTap:CGPointMake(touchX, touchY)];
}

@end
