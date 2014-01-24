//
//  ARDArticleViewController.m
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 22/01/14.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import "ARDArticleViewController.h"
#import "UIViewController+ARDErrorAllert.h"
#import "ARDReadabilityClient.h"

@interface ARDArticleViewController ()

@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ARDArticleViewController

- (void)viewDidAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self.readability articleContentByArticleId:self.articleId
                                        success:^(AFHTTPRequestOperation *operation, NSString *content) {
                                            NSString *format =@"<HTML><BODY>%@""</BODY></HTML>";
                                            NSString *html = [NSString stringWithFormat:format, content];
                                            [self.webView loadHTMLString:html baseURL:nil];
                                            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                            [self showErrorAlert:error];
                                            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                        }];
}

@end
