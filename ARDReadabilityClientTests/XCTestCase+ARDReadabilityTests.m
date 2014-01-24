//
//  XCTestCase+ARDReadabilityTests.m
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 21/01/14.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import "XCTestCase+ARDReadabilityTests.h"
#import "OHHTTPStubs.h"
#import "ARDReadabilityClient.h"

@implementation XCTestCase (ARDReadabilityTests)

- (ARDReadabilityClient *)unauthentificatedReadabilityClient
{
    return [[ARDReadabilityClient alloc] initWithBaseURL: [NSURL URLWithString:ARDReadabilityBaseURL]
                                            consumerKey:ARDOAuthConsumerKey
                                         consumerSecret:ARDOAuthConsumerSecret];
}

- (ARDReadabilityClient *)authentificatedReadabilityClient
{
    return [[ARDReadabilityClient alloc] initWithBaseURL: [NSURL URLWithString:ARDReadabilityBaseURL]
                                                  token:ARDOAuthUserToken
                                            tokenSecret:ARDOAuthUserTokenSecret
                                            consumerKey:ARDOAuthConsumerKey
                                         consumerSecret:ARDOAuthConsumerSecret];
}

- (void)stubRequestWithURLPattern:(NSString *)regexPattern
                         withFile:(NSString *)fileNamePattern
                  responseHeaders:(NSDictionary *)headers
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:0 error:nil];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        NSString *reqestURLString = [[request URL] absoluteString];
        if ([reqestURLString length] && [regex firstMatchInString:reqestURLString
                                                           options:0
                                                             range:NSMakeRange(0, [reqestURLString length])]) {
            return YES;
        }
        return NO;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString *reqestURLString = [[request URL] absoluteString];
        NSTextCheckingResult *match = [regex firstMatchInString:reqestURLString options:0 range:NSMakeRange(0, [reqestURLString length])];
        NSString *value = [reqestURLString substringWithRange:[match rangeAtIndex:1]];
        NSString *fileName = [NSString stringWithFormat:fileNamePattern, value];
        OHHTTPStubsResponse *respnose = [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(fileName, nil)
                                                                         statusCode:200
                                                                            headers:headers];
        return [respnose responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];
}

- (NSDictionary *)readabilityContentHeaders
{
    return @{@"Content-Type" : @"application/json; charset=utf-8"};
}

@end
