//
//  CustomImageDownloaderOperation.h
//  SpotBros
//
//  Created by Spotbros S.L. on 30/11/2017.
//  Copyright © 2017 SpotBros. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mw_SDWebImageDownloaderOperation.h"

@interface CustomImageDownloaderOperation : NSOperation <mw_SDWebImageDownloaderOperationProtocol>

@property (strong, nonatomic, readonly) NSURLRequest *request;
@property (assign, nonatomic, readonly) mw_SDWebImageDownloaderOptions options;

- (id)initWithRequest:(NSURLRequest *)request
              options:(mw_SDWebImageDownloaderOptions)options
             progress:(mw_SDWebImageDownloaderProgressBlock)progressBlock
            completed:(mw_SDWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(void (^)(void))cancelBlock;

@end
