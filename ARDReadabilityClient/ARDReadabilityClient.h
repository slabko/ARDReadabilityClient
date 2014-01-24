//
//  ARDReadabilityClient.h
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 9/25/13.
//  Copyright (c) 2013 com.slabko. All rights reserved.
//

#import "ARDOAuthHTTPClient.h"
#import "ARDReadabilityBookmark.h"

extern NSString *const ARDReadabilityClientErrorDomain;
extern NSString *const ARDReadabilityClientRootErrorKey;

typedef NS_ENUM(NSInteger, ARDReadabilityClientErrors){
    ARDReadabilityClientErrorUnexpectedServerResponse = -1,
    ARDReadabilityClientErrorWrongUserNameOrPassword = -2,
    ARDReadabilityClientErrorRequestIsNotAuthorized = -3,
    ARDReadabilityClientErrorResourceAlreadyExist = -4
};

@interface ARDReadabilityClient : ARDOAuthHTTPClient

@property (nonatomic, assign) dispatch_queue_t successCallbackQueue;
@property (nonatomic, assign) dispatch_queue_t failureCallbackQueue;


///----------------------------------------------------
/// @name Initializing
///----------------------------------------------------

- (id)initWithBaseURL:(NSURL *)url
          consumerKey:(NSString *)oAuthConsumerKey
       consumerSecret:(NSString *)oAuthConsumerSecret;

- (id)initWithBaseURL:(NSURL *)url
                token:(NSString *)oAuthToken
          tokenSecret:(NSString *)oAuthTokenSecret
          consumerKey:(NSString *)oAuthConsumerKey
       consumerSecret:(NSString *)oAuthConsumerSecret;


///---------------------
/// @name Authentication
///---------------------

- (void)authenticateWithUserName:(NSString *)userName
                        password:(NSString *)password
                         success:(void (^)(AFHTTPRequestOperation *operation, NSString *token, NSString *secret))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@property (readonly, nonatomic) NSString *oauthConsumerKey;
@property (readonly, nonatomic) NSString *oauthConsumerSecret;
@property (readonly, nonatomic) NSString *oauthToken;
@property (readonly, nonatomic) NSString *oauthTokenSecret;
@property (readonly, nonatomic, getter = isAuthenticated) BOOL authenticated;


///--------------------------------------------------
/// @name Requesting and modificating users bookmarks
///--------------------------------------------------

- (void)bookmarksUpdatedSince:(NSDate *)addedSince
                       sucess:(void(^)(NSArray *opeations, NSArray *bookmarks))sucess
                      failure:(void(^)(AFHTTPRequestOperation *erroneousOpeation, NSError *error))failure;

- (void)bookmarksDeletedSince:(NSDate *)deletedSince
                       sucess:(void(^)(NSArray *opeations, NSArray *bookmarks))sucess
                      failure:(void(^)(AFHTTPRequestOperation *erroneousOpeation, NSError *error))failure;

- (void)bookmark:(NSUInteger)bookmarkId
          sucess:(void(^)(AFHTTPRequestOperation *opeations,  ARDReadabilityBookmark *bookmark))sucess
         failure:(void(^)(AFHTTPRequestOperation *erroneousOpeation, NSError *error))failure;

- (void)addBookmarkForArticleURL:(NSURL *)articleURL
                        favorite:(BOOL)favorite
                         archive:(BOOL)archive
                         success:(void (^)(AFHTTPRequestOperation *operation, NSString *articleId))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)updateBookmark:(NSUInteger)bookmarkId
              favorite:(BOOL)favorite
               archive:(BOOL)archive
           readPercent:(float)readPercent
               success:(void (^)(AFHTTPRequestOperation *operation))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)deleteBookmark:(NSUInteger)bookmarkId
               success:(void (^)(AFHTTPRequestOperation *operation))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;


///-----------------------------
/// @Requesting articles context
///-----------------------------

- (void)articleContentByArticleId:(NSString *)articleId
                          success:(void (^)(AFHTTPRequestOperation *operation, NSString *content))success
                          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end