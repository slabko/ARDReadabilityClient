//
//  ARDTestArticleContent.m
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

@interface ARDTestArticleContent : XCTestCase

@end

@implementation ARDTestArticleContent

- (void)tearDown
{
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

- (void)testGettingArticleContent
{
    [self stubRequestWithURLPattern:@"https://www\\.readability\\.com/api/rest/v1/articles/(.+)"
                           withFile:@"Article-%@.txt"
                    responseHeaders:[self readabilityContentHeaders]];
    ARDAsyncLock *lock = [[ARDAsyncLock alloc] init];
    ARDReadabilityClient *client = [self authentificatedReadabilityClient];
    [client articleContentByArticleId:@"3xuhnzwp" success:^(AFHTTPRequestOperation *operation, NSString *content) {
        XCTAssert([content length], @"Article content is empty");
        [lock signal];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        XCTFail(@"Failed to get article content: %@", [error localizedDescription]);
        [lock signal];
    }];
    XCTAssert([lock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]], @"Timeout occurred");
    [OHHTTPStubs removeAllStubs];
}

@end
