
//  ARDReadabilityClient.h
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 9/25/13.
//  Copyright (c) 2013 com.slabko. All rights reserved.
//

#import "ARDReadabilityClient.h"
#import "ARDOAuthHTTPClient.h"
#import "ARDReadabilityDataFormatters.h"
#import "NSString+ARDRegularExpression.h"

NSString *const ARDReadabilityClientErrorDomain = @"ARDReadabilityErrorDomain";
NSString *const ARDReadabilityClientRootErrorKey = @"ARDReadabilityClientRootErrorKey";

static NSUInteger const ItemsPerPageRequest = 20;

static NSString *const AuthenticationURLPath = @"oauth/access_token/";
static NSString *const BookmarksURLPath = @"bookmarks";
static NSString *const ArticlesURLPath = @"articles";

typedef NS_ENUM(NSInteger, APHTTPErrors) {
    APHTTPErrorUnauthorized = 401,
    APHTTPErrorConflict = 409
};

static inline NSString *wrongUserNameOrPasswordErrorDescription()
{
    return NSLocalizedString(@"Authentication error, please check your username and password",
                             @"Wrong credentials error localized description");
}

static inline NSString *requestIsNotAuthorizedErrorDescription()
{
    return NSLocalizedString(@"Please, check your user name and password, probably, "
                             "you have changed them using web interface",
                             @"Request is not authorized error localized description");
}

static inline NSString *resourceAlreadyExistErrorDescription()
{
    return NSLocalizedString(@"The resource you are trying to add already exist",
                             @"Resource already exist error localized description");
}

static inline NSString *unexpectedServerResponse()
{
    return NSLocalizedString(@"The server returned an unexpected response",
                             @"Unexpected server response localized description");
}

@interface ARDReadabilityBookmark (ARDPrivateInterface)

- (id)initWithJSON:(id)JSON;

@end

@implementation ARDReadabilityClient

#pragma mark - Initialization

- (id)initWithBaseURL:(NSURL *)url
          consumerKey:(NSString *)oAuthConsumerKey
       consumerSecret:(NSString *)oAuthConsumerSecret
{
    self = [super initWithBaseURL:url consumerKey:oAuthConsumerKey consumerSecret:oAuthConsumerSecret];
    if (self) {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/json"];
    }
    return self;
}

- (id)initWithBaseURL:(NSURL *)url
                token:(NSString *)oAuthToken
          tokenSecret:(NSString *)oAuthTokenSecret
          consumerKey:(NSString *)oAuthConsumerKey
       consumerSecret:(NSString *)oAuthConsumerSecret
{
    return [super initWithBaseURL:url
                            token:oAuthToken
                      tokenSecret:oAuthTokenSecret
                      consumerKey:oAuthConsumerKey
                   consumerSecret:oAuthConsumerSecret];
}

#pragma mark - Public interface

- (void)authenticateWithUserName:(NSString *)userName
                        password:(NSString *)password
                         success:(void (^)(AFHTTPRequestOperation *operation, NSString *token, NSString *secret))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
{
    [self authenticateUsingXAuthWithURL:AuthenticationURLPath
                               userName:userName
                               password:password
                                success:success
                                failure:failure];
}

- (void)bookmarksUpdatedSince:(NSDate *)addedSince
                       sucess:(void(^)(NSArray *opeations, NSArray *bookmarks))sucess
                      failure:(void(^)(AFHTTPRequestOperation *erroneousOpeation, NSError *error))failure;
{
    addedSince = [addedSince laterDate:[self minReadabilityKnownDate]];
    NSDictionary *parameters = @{@"updated_since" : [ARDReadabilityInputDataFormatter() stringFromDate:addedSince]};
    [self bookmarksWithParameters:parameters sucess:sucess failure:failure];
}

- (void)bookmarksDeletedSince:(NSDate *)deletedSince
                       sucess:(void(^)(NSArray *opeations, NSArray *bookmarks))sucess
                      failure:(void(^)(AFHTTPRequestOperation *erroneousOpeation, NSError *error))failure;
{
    deletedSince = [deletedSince laterDate:[self minReadabilityKnownDate]];
    NSDictionary *parameters = @{@"updated_since": [ARDReadabilityInputDataFormatter() stringFromDate:deletedSince],
                                 @"only_deleted" : @1 };
    [self bookmarksWithParameters:parameters sucess:sucess failure:failure];
}

- (void)bookmark:(NSUInteger)bookmarkId
          sucess:(void(^)(AFHTTPRequestOperation *opeations,  ARDReadabilityBookmark *bookmark))sucess
         failure:(void(^)(AFHTTPRequestOperation *erroneousOpeation, NSError *error))failure
{
    NSString *path = [self bookmarkPath:bookmarkId];
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        ARDReadabilityBookmark *bookmark = [[ARDReadabilityBookmark alloc] initWithJSON:responseObject];
        if (bookmark) {
            sucess(operation, bookmark);
            return;
        }
        failure(operation, [self unexpectedServerResponseError]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSError *domainError = [self processError:error requestOperation:operation];
        failure(operation, domainError);
    }];
}

- (void)updateBookmark:(NSUInteger)bookmarkId
              favorite:(BOOL)favorite
               archive:(BOOL)archive
           readPercent:(float)readPercent
               success:(void (^)(AFHTTPRequestOperation *operation))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSString *path = [self bookmarkPath:bookmarkId];
    NSDictionary *parameters = @{@"favorite" : favorite ? @"1" : @"0",
                                 @"archive" : archive ? @"1" : @"0",
                                 @"read_percent" : [NSString stringWithFormat:@"%.2f", readPercent]};
    [self postPath:path parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               success(operation);
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               failure(operation, [self processError:error requestOperation:operation]);
           }];
}

- (void)deleteBookmark:(NSUInteger)bookmarkId
               success:(void (^)(AFHTTPRequestOperation *operation))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSString *path = [self bookmarkPath:bookmarkId];
    [self deletePath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, [self processError:error requestOperation:operation]);
    }];
}

- (void)articleContentByArticleId:(NSString *)articleId
                          success:(void (^)(AFHTTPRequestOperation *operation, NSString *content))success
                          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
{
    NSString *articlePath = [NSString stringWithFormat:@"%@/%@", ArticlesURLPath, articleId];
    [self getPath:articlePath
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, NSDictionary *articleJSON) {
              success(operation, articleJSON[@"content"]);
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              failure(operation, [self processError:error requestOperation:operation]);
          }];
}

- (void)addBookmarkForArticleURL:(NSURL *)articleURL
                        favorite:(BOOL)favorite
                         archive:(BOOL)archive
                         success:(void (^)(AFHTTPRequestOperation *operation, NSString *articleId))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self postPath:BookmarksURLPath
        parameters:@{@"url" : [articleURL absoluteString],
                     @"favorite" : favorite ? @"1" : @"0",
                     @"archive" : archive ? @"1" : @"0",
                     @"allow_duplicates" : @"0"}
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               NSString *articleLocation = [operation.response allHeaderFields][@"X-Article-Location"];
               NSString *articleId = [articleLocation firstMatchOfRegex:@"/([^/]+)$" captureGroupIndex:1];
               success(operation, articleId);
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               failure(operation, [self processError:error requestOperation:operation]);
           }];
}

#pragma mark - ARDOAuthHTTPClient's methods redefinition

- (void)authenticateUsingXAuthWithURL:(NSString *)accessTokenPath
                             userName:(NSString *)userName
                             password:(NSString *)password
                              success:(void (^)(AFHTTPRequestOperation *, NSString *, NSString *))success
                              failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    void(^failureHandler)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error){
        NSError *domainError;
        if ([[operation response] statusCode] == APHTTPErrorUnauthorized) {
            domainError = [self wrongUserNameOrPasswordError];
        } else {
            domainError = [self processError:error requestOperation:operation];
        }
        failure(operation, domainError);
    };
    
    [super authenticateUsingXAuthWithURL:accessTokenPath
                                userName:userName
                                password:password
                                 success:success
                                 failure:failureHandler];
}

#pragma mark - AFHTTPClient's methods redefinition

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(AFHTTPRequestOperation *, id))success
                                                    failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    AFHTTPRequestOperation *operation = [super HTTPRequestOperationWithRequest:urlRequest success:success failure:failure];
    operation.successCallbackQueue = self.successCallbackQueue;
    operation.failureCallbackQueue = self.failureCallbackQueue;
    return operation;
}

#pragma mark - Private interface

- (void)bookmarksWithParameters:(NSDictionary *)parameters
                         sucess:(void(^)(NSArray *opeations, NSArray *bookmarks))sucess
                        failure:(void(^)(AFHTTPRequestOperation *erroneousOpeation, NSError *error))failure
{
    dispatch_queue_t operationsCallbackQueue = dispatch_queue_create("com.slabko.readabilityclient.bookmarkslist", DISPATCH_QUEUE_CONCURRENT);
    NSURLRequest *firstPageRequest = [self bookmarksRequestWithParamaters:parameters forPage:1 itemPerPage:ItemsPerPageRequest];
    AFHTTPRequestOperation *firstPageOperation = [self HTTPRequestOperationWithRequest:firstPageRequest
    success:^(AFHTTPRequestOperation *firstPageOperation, NSDictionary *firstPage) {
        NSUInteger totalPages = [((NSString *)firstPage[@"meta"][@"num_pages"]) integerValue];
        NSMutableArray *requests = [NSMutableArray array];
        for (NSUInteger i = 2; i <= totalPages; ++i) {
            NSURLRequest *nextPageRequest = [self bookmarksRequestWithParamaters:parameters forPage:i itemPerPage:ItemsPerPageRequest];
            [requests addObject:nextPageRequest];
        }
        [self enqueueBatchOfHTTPRequestOperationsWithRequests:requests progressBlock:nil
        completionBlock:^(NSArray *morePageOperations) {
            dispatch_async(operationsCallbackQueue, ^{
                NSMutableArray *operations = [NSMutableArray arrayWithCapacity:totalPages];
                [operations addObject:firstPageOperation];
                [operations addObjectsFromArray:morePageOperations];
                
                NSError *error;
                AFHTTPRequestOperation *erroneousOpeation;
                NSArray *bookmarks = [self bookmarksFromReadabilityRequestOperations:operations error:&error erroneousOpeation:&erroneousOpeation];
                if (!bookmarks) {
                    dispatch_async(self.failureCallbackQueue, ^{
                        failure(erroneousOpeation ,error);
                    });
                }
                dispatch_async(self.successCallbackQueue ?: dispatch_get_main_queue(), ^{
                    sucess(operations, bookmarks);
                });
            });
        }];
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, [self processError:error requestOperation:operation]);
    }];
    
    firstPageOperation.successCallbackQueue = operationsCallbackQueue;
    [self enqueueHTTPRequestOperation:firstPageOperation];
}

- (NSURLRequest *)bookmarksRequestWithParamaters:(NSDictionary *)parameters
                                         forPage:(NSInteger)pageNumber
                                     itemPerPage:(NSInteger)itemsPerPage
{
    NSParameterAssert(!parameters[@"per_page"]);
    NSParameterAssert(!parameters[@"page"]);
    NSDictionary *basicParametser = @{@"per_page" : @(itemsPerPage),
                                      @"page" : @(pageNumber)};
    NSMutableDictionary *mergedParameter = [NSMutableDictionary dictionaryWithCapacity:([basicParametser count] + [parameters count])];
    [mergedParameter addEntriesFromDictionary:basicParametser];
    [mergedParameter addEntriesFromDictionary:parameters];
    
    NSURLRequest *request = [self requestWithMethod:@"GET" path:BookmarksURLPath parameters:mergedParameter];
    return request;
}

- (NSArray *)bookmarksFromReadabilityRequestOperations:(NSArray *)operations
                                                 error:(NSError **)error
                                     erroneousOpeation:(AFHTTPRequestOperation **)erroneousOpeation
{
    NSMutableArray *bookmarks = [NSMutableArray arrayWithCapacity:[operations count] * ItemsPerPageRequest];
    
    for (AFJSONRequestOperation *operation in operations) {
        NSDictionary *responseJSON = operation.responseJSON;
        if (!responseJSON) {
            *error = [self processError:operation.error requestOperation:operation];
            *erroneousOpeation = operation;
            return nil;
        }
        
        for (NSDictionary *rawBookmark in responseJSON[@"bookmarks"]) {
            ARDReadabilityBookmark *bookmark = [[ARDReadabilityBookmark alloc] initWithJSON:rawBookmark];
            if (bookmark) {
                [bookmarks addObject:bookmark];
            }
        }
    }
    return [bookmarks copy];
}

- (NSDate *)minReadabilityKnownDate
{
    static NSDate *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [NSDate dateWithTimeIntervalSince1970:0];
    });
    return instance;
}

- (NSError *)processError:(NSError *)networkError requestOperation:(AFHTTPRequestOperation *)operation
{
    NSInteger HTTPStatusCode = [[operation response] statusCode];
    switch (HTTPStatusCode) {
        case APHTTPErrorUnauthorized:{
            return [NSError errorWithDomain:ARDReadabilityClientErrorDomain
                                       code:ARDReadabilityClientErrorRequestIsNotAuthorized
                                   userInfo:@{ARDReadabilityClientRootErrorKey : networkError,
                                              NSLocalizedDescriptionKey: requestIsNotAuthorizedErrorDescription()}];
        }
        case APHTTPErrorConflict:{
            return [NSError errorWithDomain:ARDReadabilityClientErrorDomain
                                       code:ARDReadabilityClientErrorResourceAlreadyExist
                                   userInfo:@{ARDReadabilityClientRootErrorKey : networkError,
                                              NSLocalizedDescriptionKey : resourceAlreadyExistErrorDescription()}];
        }
    }
    
    return networkError;
}

- (NSError *)unexpectedServerResponseError
{
    return [NSError errorWithDomain:ARDReadabilityClientErrorDomain
                               code:ARDReadabilityClientErrorUnexpectedServerResponse
                           userInfo:@{NSLocalizedDescriptionKey : unexpectedServerResponse()}];
}

- (NSError *)wrongUserNameOrPasswordError
{
    return [NSError errorWithDomain:ARDReadabilityClientErrorDomain
                               code:ARDReadabilityClientErrorWrongUserNameOrPassword
                           userInfo:@{NSLocalizedDescriptionKey: wrongUserNameOrPasswordErrorDescription()}];
}

- (NSString *)bookmarkPath:(NSUInteger)bookmarkId
{
    return [BookmarksURLPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", bookmarkId]];
}

@end
