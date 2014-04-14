//
//  ARDReadablilityClientTestBookmars.m
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 20/01/14.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+ARDReadabilityTests.h"
#import "OHHTTPStubs.h"
#import "ARDAsyncLock.h"
#import "ARDReadabilityClient.h"

@interface ARDTestBookmars : XCTestCase

@end

@implementation ARDTestBookmars

- (void)tearDown
{
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

- (void)testBookmarsList
{
    NSString *requestPattern = @"https://www\\.readability\\.com/api/rest/v1/bookmarks\\?page=(\\d+)"
                                "&per_page=\\d+&updated_since=.+";
    [self stubRequestWithURLPattern:requestPattern
                           withFile:@"AllUpdatedBookmarksPage%@.txt"
                    responseHeaders:[self readabilityContentHeaders]];
    ARDAsyncLock *lock = [[ARDAsyncLock alloc] init];
    ARDReadabilityClient *client = [self authentificatedReadabilityClient];
    [client bookmarksUpdatedSince:[NSDate distantPast] sucess:^(NSArray *operatins, NSArray *bookmarks) {
        XCTAssertEqual([bookmarks count], (NSUInteger)98, @"Not all the bookmarks are loaded");
        [lock signal];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        XCTFail(@"Failed to get list of bookmars: %@", [error localizedDescription]);
        [lock signal];
    }];
    XCTAssert([lock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]], @"Timeout occurred");
    [OHHTTPStubs removeLastStub];
}

- (void)testDeletedBookmarksList
{
    NSString *requestPattern = @"https://www\\.readability\\.com/api/rest/v1/bookmarks\\?only_deleted=1"
                                "&page=(\\d)&per_page=\\d+&updated_since=.+";
    [self stubRequestWithURLPattern:requestPattern
                           withFile:@"AllDeletedBookmarks%@.txt"
                    responseHeaders:[self readabilityContentHeaders]];
    ARDAsyncLock *lock = [[ARDAsyncLock alloc] init];
    ARDReadabilityClient *client = [self authentificatedReadabilityClient];
    [client bookmarksDeletedSince:[NSDate distantPast] sucess:^(NSArray *opeations, NSArray *bookmarks) {
        XCTAssert([bookmarks count] == 47, @"Not all the bookmarks are loaded");
        XCTAssert([bookmarks count], @"Wrong list of bookmarks");
        [lock signal];
    } failure:^(AFHTTPRequestOperation *erroneousOpeation, NSError *error) {
        XCTFail(@"Failed to get list of bookmars: %@", [error localizedDescription]);
        [lock signal];
    }];
    XCTAssert([lock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]], @"Timeout occurred");
    [OHHTTPStubs removeLastStub];
}

- (void)testSingleBookmark
{
    NSString *requestPattern = @"https://www\\.readability\\.com/api/rest/v1/bookmarks/([^/+]+)/?";
    [self stubRequestWithURLPattern:requestPattern
                           withFile:@"Bookmark-%@.txt"
                    responseHeaders:[self readabilityContentHeaders]];
    ARDAsyncLock *lock = [[ARDAsyncLock alloc] init];
    ARDReadabilityClient *client = [self authentificatedReadabilityClient];
    NSUInteger bookmarkId = 43745203;    
    [client bookmark:bookmarkId sucess:^(AFHTTPRequestOperation *opeation, ARDReadabilityBookmark *bookmark) {
        XCTAssertEqual(bookmark.bookmarkId, bookmarkId, @"Wrong value of the id field");
        XCTAssertEqual(bookmark.readPercent, 0.12f, @"Wrong value of the read percent field");
        
        XCTAssertEqualObjects(bookmark.dateUpdated, [NSDate dateWithTimeIntervalSince1970:1390247648],
                              @"Wrong value of the date updated field");
        XCTAssertEqualObjects(bookmark.dateAdded, [NSDate dateWithTimeIntervalSince1970:1374912878],
                              @"Wrong value of the date added field");
        XCTAssertEqual(bookmark.isFavorite, YES, @"Wrong value of the favorite field");
        XCTAssertEqual(bookmark.isArchived, NO, @"Wrong value of the archived field");
        XCTAssertEqualObjects(bookmark.articleId, @"3xuhnzwp", @"Wrong value of the date article ID field");
        XCTAssertEqualObjects(bookmark.articleTitle, @"How Not to Be Alone",
                              @"Wrong value of the date article title field");
        NSString *expectedArticleExcerpt = @"A COUPLE of weeks ago, I saw a stranger crying in public. "
                                            "I was in Brooklyn’s Fort Greene neighborhood, waiting to meet "
                                            "a friend for breakfast. I arrived at the restaurant a few minutes early…";
        XCTAssertEqualObjects(bookmark.articleExcerpt, expectedArticleExcerpt,
                              @"Wrong value of the date article excerpt field");
        XCTAssertEqualObjects(bookmark.articleDatePublished, [NSDate dateWithTimeIntervalSince1970:1370664000],
                              @"Wrong value of the date article date published field");
        NSString *expectedArticleURL = @"http://www.nytimes.com/2013/06/09/opinion/sunday/"
                                        "how-not-to-be-alone.html?pagewanted=all&_r=0";
        XCTAssertEqualObjects(bookmark.articleURL, expectedArticleURL, @"Wrong value of the date article URL field");
        
        [lock signal];
    } failure:^(AFHTTPRequestOperation *erroneousOpeation, NSError *error) {
        XCTFail(@"Failed to load a bookmark: %@", [error localizedDescription]);
        [lock signal];
    }];
    XCTAssert([lock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]], @"Timeout occurred");
    [OHHTTPStubs removeLastStub];
}

@end
