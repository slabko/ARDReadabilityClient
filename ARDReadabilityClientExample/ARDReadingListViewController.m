//
//  ARDReadingListViewController.m
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 22/01/14.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import "ARDReadingListViewController.h"
#import "UIViewController+ARDErrorAllert.h"
#import "ARDReadabilityClient.h"
#import "ARDArticleViewController.h"

@interface ARDReadingListViewController (){
@private
    NSMutableArray *_bookmarks;
}

@end

@implementation ARDReadingListViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self.readability bookmarksUpdatedSince:[NSDate distantPast]
                                     sucess:^(NSArray *opeations, NSArray *bookmarks) {
                                         _bookmarks = [bookmarks mutableCopy];
                                         [self.tableView reloadData];
                                         [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                     }
                                    failure:^(AFHTTPRequestOperation *erroneousOpeation, NSError *error) {
                                        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                        [self showErrorAlert:error];
                                    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    ARDReadabilityBookmark *bookmark = _bookmarks[indexPath.row];
    ARDArticleViewController *destinationViewController = segue.destinationViewController;
    destinationViewController.readability = [self readability];
    destinationViewController.articleId = bookmark.articleId;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_bookmarks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    ARDReadabilityBookmark *bookmark = _bookmarks[indexPath.row];
    cell.textLabel.text = bookmark.articleTitle;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        ARDReadabilityBookmark *bookmark = _bookmarks[indexPath.row];
        [_bookmarks removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.readability deleteBookmark:bookmark.bookmarkId
                                 success:^(AFHTTPRequestOperation *operation) {
                                     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                 }
                                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                     [self showErrorAlert:error];
                                 }];
    }
}

@end
