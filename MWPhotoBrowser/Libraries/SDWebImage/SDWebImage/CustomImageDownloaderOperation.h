//
//  CustomImageDownloaderOperation.h
//  SpotBros
//
//  Created by Spotbros S.L. on 30/11/2017.
//  Copyright © 2017 SpotBros. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDWebImageDownloaderOperation.h"

@interface CustomImageDownloaderOperation : NSOperation <SDWebImageDownloaderOperationProtocol>

@property (strong, nonatomic, readonly) NSURLRequest *request;
@property (assign, nonatomic, readonly) SDWebImageDownloaderOptions options;

- (id)initWithRequest:(NSURLRequest *)request
              options:(SDWebImageDownloaderOptions)options
             progress:(SDWebImageDownloaderProgressBlock)progressBlock
            completed:(SDWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(void (^)())cancelBlock;

@end
