//
//  ARDTestBookmarksModifications.m
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 21/01/14.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+ARDReadabilityTests.h"
#import "OHHTTPStubs.h"
#import "ARDAsyncLock.h"
#import "ARDReadabilityClient.h"

@interface ARDTestBookmarksModifications : XCTestCase

@end

@implementation ARDTestBookmarksModifications

- (void)tearDown
{
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

- (void)testAddingNewArticle
{
    NSDictionary *headers = @{@"Location" : @"https://www.readability.com/api/rest/v1/bookmarks/58361237",
                              @"X-Article-Location" : @"/api/rest/v1/articles/oeo9kdzj"};
    [self stubBookmarksRequestWithStatusCode:202 headers:headers];

    ARDAsyncLock *lock = [[ARDAsyncLock alloc] init];
    ARDReadabilityClient *client = [self authentificatedReadabilityClient];
    void(^sucessHandler)() = ^(AFHTTPRequestOperation *operation, NSString *articleId) {
        XCTAssert(articleId, @"Operation did not return any content back");
        [lock signal];
    };
    void(^failureHandler)() = ^(AFHTTPRequestOperation *operation, NSError *error) {
        XCTFail(@"Error adding new article");
        [lock signal];
    };
    [client addBookmarkForArticleURL:[NSURL URLWithString:@"http://goo.gl/54cYC"]
                            favorite:NO
                             archive:NO
                             success:sucessHandler
                             failure:failureHandler];
    XCTAssert([lock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]], @"Timeout occurred");
    [OHHTTPStubs removeLastStub];
}

- (void)testAddingExistingArticle
{
    [self stubBookmarksRequestWithStatusCode:409 headers:nil];
    ARDAsyncLock *lock = [[ARDAsyncLock alloc] init];
    ARDReadabilityClient *client = [self authentificatedReadabilityClient];
    void(^sucessHandler)() = ^(AFHTTPRequestOperation *operation, NSString *articleId) {
        XCTFail(@"Successfully added article that already exists added");
        [lock signal];
    };
    void(^failureHandler)() = ^(AFHTTPRequestOperation *operation, NSError *error) {
        XCTAssertEqualObjects([error domain], ARDReadabilityClientErrorDomain, @"Wrong error domain");
        XCTAssertEqual([error code], ARDReadabilityClientErrorResourceAlreadyExist, @"Wrong error code");
        [lock signal];
    };
    [client addBookmarkForArticleURL:[NSURL URLWithString:@"http://goo.gl/54cYC"]
                            favorite:NO
                             archive:NO
                             success:sucessHandler
                             failure:failureHandler];
    XCTAssert([lock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]], @"Timeout occurred");
    [OHHTTPStubs removeLastStub];
}

- (void)testUpdatingBookmark
{
    [self stubBookmarksRequestWithStatusCode:200 headers:nil];
    ARDAsyncLock *lock = [[ARDAsyncLock alloc] init];
    ARDReadabilityClient *client = [self authentificatedReadabilityClient];
    NSUInteger bookmarkId = 40513368;
    void(^sucessHandler)() = ^(AFHTTPRequestOperation *operation) {
        [lock signal];
    };
    void(^failureHandler)() = ^(AFHTTPRequestOperation *operation, NSError *error) {
        XCTFail(@"Error updating a bookmark: %@", [error localizedDescription]);
        [lock signal];
    };
    [client updateBookmark:bookmarkId
                  favorite:YES
                   archive:NO
               readPercent:0.12f
                   success:sucessHandler
                   failure:failureHandler];
    XCTAssert([lock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]], @"Timeout occurred");
    [OHHTTPStubs removeLastStub];
}

- (void)testDeletingBookmark
{
    [self stubBookmarksRequestWithStatusCode:204 headers:nil];
    ARDAsyncLock *lock = [[ARDAsyncLock alloc] init];
    ARDReadabilityClient *client = [self authentificatedReadabilityClient];
    NSUInteger bookmarkId = 40759348;
    void(^sucessHandler)() = ^(AFHTTPRequestOperation *operation) {
        [lock signal];
    };
    void(^failureHandler)() = ^(AFHTTPRequestOperation *operation, NSError *error) {
        XCTFail(@"Error updating a bookmark: %@", [error localizedDescription]);
        [lock signal];
    };
    [client deleteBookmark:bookmarkId
                   success:sucessHandler
                   failure:failureHandler];
    XCTAssert([lock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]], @"Timeout occurred");
    [OHHTTPStubs removeLastStub];
}

- (void)stubBookmarksRequestWithStatusCode:(NSInteger)statusCode headers:(NSDictionary *)headers
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        if ([[[request URL] absoluteString] hasPrefix:@"https://www.readability.com/api/rest/v1/bookmarks"]
            && ![[request HTTPMethod] isEqualToString:@"GET"]) {
            return YES;
        }
        return NO;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        OHHTTPStubsResponse *response = [OHHTTPStubsResponse responseWithData:[NSData data]
                                                                   statusCode:statusCode
                                                                      headers:headers];
        return [response responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];
}

@end
