//
//  MWVideo.h
//  MWPhotoBrowser
//
//  Video support for MWPhotoBrowser
//

#import <Foundation/Foundation.h>
#import "MWPhotoProtocol.h"

// This class models a video item for the photo browser.
// It conforms to MWPhoto protocol to work seamlessly with MWPhotoBrowser.
@interface MWVideo : NSObject <MWPhoto>

// Properties
@property (nonatomic, strong) NSString *caption;
@property (nonatomic, readonly) NSURL *videoURL;
@property (nonatomic, strong) UIImage *thumbnailImage;
@property (nonatomic, readonly) NSURL *thumbnailURL;

// Class methods
+ (MWVideo *)videoWithURL:(NSURL *)url;
+ (MWVideo *)videoWithURL:(NSURL *)url thumbnailImage:(UIImage *)thumbnailImage;
+ (MWVideo *)videoWithURL:(NSURL *)url thumbnailURL:(NSURL *)thumbnailURL;

// Init
- (id)initWithURL:(NSURL *)url;
- (id)initWithURL:(NSURL *)url thumbnailImage:(UIImage *)thumbnailImage;
- (id)initWithURL:(NSURL *)url thumbnailURL:(NSURL *)thumbnailURL;

@end
