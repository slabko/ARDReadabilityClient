//
//  XCTestCase+ARDReadabilityTests.h
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 21/01/14.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import <XCTest/XCTest.h>

@class ARDReadabilityClient;

static NSString *const ARDReadabilityBaseURL = @"https://www.readability.com/api/rest/v1/";
static NSString *const ARDOAuthConsumerKey = @"CONSUMER KEY";
static NSString *const ARDOAuthConsumerSecret = @"CONSUMER SECRET";
static NSString *const ARDOAuthUserToken = @"USER TOKEN";
static NSString *const ARDOAuthUserTokenSecret = @"USER TOKEN SECRET";

@interface XCTestCase (ARDReadabilityTests)

- (ARDReadabilityClient *)unauthentificatedReadabilityClient;
- (ARDReadabilityClient *)authentificatedReadabilityClient;
- (NSDictionary *)readabilityContentHeaders;
- (void)stubRequestWithURLPattern:(NSString *)regexPattern
                         withFile:(NSString *)fileNamePattern
                  responseHeaders:(NSDictionary *)headers;
@end
