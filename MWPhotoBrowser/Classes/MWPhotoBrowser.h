//
//  MWPhotoBrowser.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "MWPhoto.h"
#import "MWPhotoProtocol.h"
#import "MWCaptionView.h"

// Debug Logging
#if 0 // Set to 1 to enable debug logging
#define MWLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define MWLog(x, ...)
#endif

#define kMWPhotoBrowserAlwaysShowTools YES

// Delgate
@class MWPhotoBrowser;

@protocol MWPhotoBrowserDelegate <NSObject>

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser;
- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;

@optional

- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser activityType:(NSString *)activityType completed:(BOOL)completed;
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser savePhoto:(id<MWPhoto>)photo completion:(void (^)(BOOL success, NSError *error))completion;

@end

// MWPhotoBrowser
@interface MWPhotoBrowser : UIViewController <UIScrollViewDelegate, MFMailComposeViewControllerDelegate>

// Properties
@property (nonatomic, weak) IBOutlet id<MWPhotoBrowserDelegate> delegate;
@property (nonatomic) BOOL zoomPhotosToFill;
@property (nonatomic) BOOL displayNavArrows;
@property (nonatomic) BOOL displayActionButton;
@property (nonatomic) BOOL applicationActionsOnly;
@property (nonatomic, readonly) NSUInteger currentIndex,currentPageIndex;

// Init
- (id)initWithPhotos:(NSArray *)photosArray; // Depreciated
- (id)initWithDelegate:(id <MWPhotoBrowserDelegate>)delegate;
- (id)initWithDelegate:(id <MWPhotoBrowserDelegate>)delegate andActivities:(NSArray *)activities;


// Reloads the photo browser and refetches data
- (void)reloadData;

// Set page that photo browser starts on
- (void)setCurrentPhotoIndex:(NSUInteger)index;
- (void)setInitialPageIndex:(NSUInteger)index; // Depreciated

// Navigation
- (void)showNextPhotoAnimated:(BOOL)animated;
- (void)showPreviousPhotoAnimated:(BOOL)animated;

- (void)toggleControls;

- (void)showProgressHUDWithMessage:(NSString *)message;
- (void)hideProgressHUD:(BOOL)animated;
- (void)showProgressHUDCompleteMessage:(NSString *)message;


@end
