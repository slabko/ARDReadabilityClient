//
//  UIViewController+ARDErrorAllert.h
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 22/01/14.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (ARDErrorAllert)

- (void)showErrorAlert:(NSError *)error;

@end
