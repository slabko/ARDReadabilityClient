//
//  ARDOAuthHTTPClient.h
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 2/22/13.
//  Copyright (c) 2013 ru.slabko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "AFNetworking.h"

extern NSString *const ARDOAuthHTTPClientErrorDomain;



typedef void(^OAuthAuthenticationCompletedhHandler)(BOOL, NSError*);

@interface ARDOAuthHTTPClient : AFHTTPClient

@property (readonly, nonatomic) NSString *oauthConsumerKey;
@property (readonly, nonatomic) NSString *oauthConsumerSecret;
@property (readonly, nonatomic) NSString *oauthToken;
@property (readonly, nonatomic) NSString *oauthTokenSecret;
@property (readonly, nonatomic, getter = isAuthenticated) BOOL authenticated;

- (id)initWithBaseURL:(NSURL *)url
          consumerKey:(NSString *)oAuthConsumerKey
       consumerSecret:(NSString *)oAuthConsumerSecret;

- (id)initWithBaseURL:(NSURL *)url
                token:(NSString *)oAuthToken
          tokenSecret:(NSString *)oAuthTokenSecret
          consumerKey:(NSString *)oAuthConsumerKey
       consumerSecret:(NSString *)oAuthConsumerSecret;

- (void)authenticateUsingXAuthWithURL:(NSString *)accessTokenPath
                             userName:(NSString *)userName
                             password:(NSString *)password
                              success:(void(^)(AFHTTPRequestOperation *operation, NSString *token, NSString *tokenSicret))success
                              failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failure;
@end
