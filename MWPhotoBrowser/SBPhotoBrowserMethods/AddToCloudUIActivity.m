//
//  AddToCloudUIActivity.m
//  SpotBros
//
//  Created by victor on 10/12/13.
//  Copyright (c) 2013 SpotBros. All rights reserved.
//

#import "AddToCloudUIActivity.h"

@implementation AddToCloudUIActivity

- (NSString *)activityType
{
    return @"";
}

- (NSString *)activityTitle
{
    return NSLocalizedString(@"Add to my cloud", @"Add to my cloud");
}

- (UIImage *)activityImage
{
    // Note: These images need to have a transparent background and I recommend these sizes:
    // iPadShare@2x should be 126 px, iPadShare should be 53 px, iPhoneShare@2x should be 100
    // px, and iPhoneShare should be 50 px. I found these sizes to work for what I was making.
	
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        return [UIImage imageNamed:@"myCloudShortcut"];
    }
    else
    {
        return [UIImage imageNamed:@"myCloudShortcut"];
    }
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"%s", __FUNCTION__);
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"%s",__FUNCTION__);
}

- (UIViewController *)activityViewController
{
    NSLog(@"%s",__FUNCTION__);
    return nil;
}

- (void)performActivity
{
    // This is where you can do anything you want, and is the whole reason for creating a custom
    // UIActivity
	
    [self activityDidFinish:YES];
}

@end
