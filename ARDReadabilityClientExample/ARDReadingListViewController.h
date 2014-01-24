//
//  ARDReadingListViewController.h
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 22/01/14.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ARDReadabilityClient;

@interface ARDReadingListViewController : UITableViewController

@property (nonatomic, strong) ARDReadabilityClient *readability;

@end
