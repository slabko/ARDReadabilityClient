//
//  ARDReadabilityClientTests.m
//  ARDReadabilityClientTests
//
//  Created by Andrew Slabko on 19/01/14.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+ARDReadabilityTests.h"
#import "OHHTTPStubs.h"
#import "ARDAsyncLock.h"
#import "ARDReadabilityClient.h"

@interface ARDTestsAuthentification : XCTestCase

@end

@implementation ARDTestsAuthentification

- (void)tearDown
{
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

- (void)testSimpleUserAuthentification
{
    NSString *sampleTokenValue = @"AUTHTOKEN";
    NSString *sampleTokenSecretValue = @"AUTHTOKENSECRET";
    NSString *responseString = [NSString stringWithFormat:@"oauth_token_secret=%@&oauth_token=%@&oauth_callback_confirmed=true",
                                sampleTokenSecretValue, sampleTokenValue];
    [self stubAuthentificationRequestsWithResponseString:responseString statusCode:200];
    
    ARDAsyncLock *lock = [[ARDAsyncLock alloc] init];
    
    ARDReadabilityClient *client = [self unauthentificatedReadabilityClient];
    [client authenticateWithUserName:@"user" password:@"pass" success:^(AFHTTPRequestOperation *operation, NSString *token, NSString *tokenSecret) {
        XCTAssertEqualObjects(tokenSecret, sampleTokenSecretValue, @"Wrong the token secret value");
        XCTAssertEqualObjects(token, sampleTokenValue,  @"Wrong the token value");
        [lock signal];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        XCTFail(@"Failed to authenticate the user");
        [lock signal];
    }];
    
    XCTAssert([lock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]], @"Timeout occurred");
    [OHHTTPStubs removeLastStub];
}

- (void)testWrongUserCredentials
{
    [self stubAuthentificationRequestsWithResponseString:@"xAuth username or password is not valid" statusCode:401];
    ARDAsyncLock *lock = [[ARDAsyncLock alloc] init];
    ARDReadabilityClient *client = [self unauthentificatedReadabilityClient];
    
    [client authenticateWithUserName:@"theft" password:@"pass" success:^(AFHTTPRequestOperation *operation, NSString *token, NSString *tokenSecret) {
        XCTFail(@"The wrong user is authenticated");
        [lock signal];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        XCTAssertEqualObjects([error domain], ARDReadabilityClientErrorDomain, @"Wrong error domain for  authentication error");
        XCTAssertEqual([error code], ARDReadabilityClientErrorWrongUserNameOrPassword, @"Wrong error code for authentication error");
        [lock signal];
    }];
    
    XCTAssert([lock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]], @"Timeout occurred");
    [OHHTTPStubs removeLastStub];
}

#pragma mark - Helpers

- (void)stubAuthentificationRequestsWithResponseString:(NSString *)responseString statusCode:(NSInteger)statusCode
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        NSString *authentificationURLString = @"https://www.readability.com/api/rest/v1/oauth/access_token/";
        if ([[request.URL absoluteString]isEqualToString:authentificationURLString]) {
            return YES;
        }
        return NO;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        OHHTTPStubsResponse *response = [OHHTTPStubsResponse responseWithData:responseData
                                                                   statusCode:statusCode
                                                                      headers:nil];
        return [response responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];
}

@end
