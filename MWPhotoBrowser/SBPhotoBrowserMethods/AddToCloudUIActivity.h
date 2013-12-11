//
//  AddToCloudUIActivity.h
//  SpotBros
//
//  Created by victor on 10/12/13.
//  Copyright (c) 2013 SpotBros. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhotoBrowser.h"

@interface AddToCloudUIActivity : UIActivity

@property(nonatomic,strong)id<MWPhotoBrowserDelegate> delegate;

- (id)initWithPhotoBrowser:(MWPhotoBrowser *)photoBrowser;

@end
