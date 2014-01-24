//
//  ARDLoginViewController.m
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 22/01/14.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import "ARDLoginViewController.h"
#import "UIViewController+ARDErrorAllert.h"
#import "ARDReadabilityClient.h"
#import "ARDReadingListViewController.h"

static NSString *const ARDReadabilityBaseURL = @"https://www.readability.com/api/rest/v1/";


//============================================================================================
//          Before you start the example, get your keys and remove this error
#error Get you Readability keys from https://www.readability.com/developers and put them below

static NSString *const ARDOAuthConsumerKey = @"CONSUMER KEY";
static NSString *const ARDOAuthConsumerSecret = @"CUNSUMER SECRET";
//============================================================================================

@interface ARDLoginViewController ()

@property (nonatomic, weak) IBOutlet UITextField *userNameTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, strong) ARDReadabilityClient *readability;

@end

@implementation ARDLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"token"];
    NSString *secret = [[NSUserDefaults standardUserDefaults] objectForKey:@"secret"];
    if ([token length] && [secret length]) {
        self.readability = [[ARDReadabilityClient alloc] initWithBaseURL:[NSURL URLWithString:ARDReadabilityBaseURL]
                                                                  token:token
                                                            tokenSecret:secret
                                                            consumerKey:ARDOAuthConsumerKey
                                                         consumerSecret:ARDOAuthConsumerSecret];
    } else {
        self.readability = [[ARDReadabilityClient alloc] initWithBaseURL:[NSURL URLWithString:ARDReadabilityBaseURL]
                                                            consumerKey:ARDOAuthConsumerKey
                                                         consumerSecret:ARDOAuthConsumerSecret];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if ([self.readability isAuthenticated]) {
        [self performSegueWithIdentifier:@"ShowArticlesSegue" sender:self];
    }
}

- (IBAction)login:(id)sender
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self.readability authenticateWithUserName:self.userNameTextField.text
                                      password:self.passwordTextField.text
                                       success:^(AFHTTPRequestOperation *operation, NSString *token, NSString *secret) {
                                           [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                           [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"token"];
                                           [[NSUserDefaults standardUserDefaults] setObject:secret forKey:@"secret"];
                                           [self performSegueWithIdentifier:@"ShowArticlesSegue" sender:self];
                                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                           [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                           [self showErrorAlert:error];
                                       }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *navigationController = segue.destinationViewController;
    ARDReadingListViewController *bookmarksController
        = (ARDReadingListViewController *)navigationController.visibleViewController;
    bookmarksController.readability = self.readability;
}

@end
