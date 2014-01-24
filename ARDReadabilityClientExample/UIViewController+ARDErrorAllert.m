//
//  UIViewController+ARDErrorAllert.m
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 22/01/14.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import "UIViewController+ARDErrorAllert.h"

@implementation UIViewController (ARDErrorAllert)

- (void)showErrorAlert:(NSError *)error
{
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                      otherButtonTitles:nil, nil] show];
}

@end
