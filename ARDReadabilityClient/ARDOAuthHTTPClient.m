//
//  ARDOAuthHTTPClient.h
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 2/22/13.
//  Copyright (c) 2013 ru.slabko. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "ARDOAuthHTTPClient.h"
#import "NSString+ARDRegularExpression.h"

static NSString *const oAuthVersion = @"1.0";
static NSString *const oAuthSignatureMethod = @"HMAC-SHA1";
static NSString *const xAuthMode = @"client_auth";

NSString *const ARDOAuthHTTPClientErrorDomain = @"ARDOAuthHTTPClientErrorDomain";

typedef NS_ENUM(NSInteger, ARDOAuthHTTPClientErrors){
    ARDOAuthHTTPClientWrongResponse = -1
};

#pragma mark - Helpers

@interface NSURL (OAHTTPClientExtensions)

- (NSURL *)URLWithoutQuery;

@end

@interface NSDictionary (OAHTTPClientExtensions)

- (NSDictionary *)dictionaryMergedWithDictionary:(NSDictionary *)dictionary;
- (NSString *)toStringWithItemsConcotination:(NSString *)concotinationBetweenItems
                          pairsConcotination:(NSString *)concotinationBetweenPairs
                       sortKeysUsingSelector:(SEL)comparator;

@end

@interface NSString (OAHTTPClientExtensions)

- (NSString *)encodedURLParameterString;
- (NSString *)signUsingSHA1WithSecret:(NSString *)secret;

@end

@interface NSURLRequest (OAHTTPClientExtensions)

- (NSDictionary *)queryParameters;

@end

@implementation NSURL (OAHTTPClientExtensions)

- (NSURL *)URLWithoutQuery
{
    NSString *path = [[[self absoluteString] componentsSeparatedByString:@"?"] firstObject];
    return [NSURL URLWithString:path];
}

@end

@implementation NSDictionary (OAHTTPClientExtensions)

- (NSDictionary *)dictionaryMergedWithDictionary:(NSDictionary *)dictionary
{
    NSMutableDictionary *result = [self mutableCopy];
    [result addEntriesFromDictionary:dictionary];
    return [result mutableCopy];
}


- (NSString *)toStringWithItemsConcotination:(NSString *)concotinationBetweenItems
                          pairsConcotination:(NSString *)concotinationBetweenPairs
                       sortKeysUsingSelector:(SEL)comparator
{
    NSMutableArray *concotinatedPairs = [[NSMutableArray alloc] initWithCapacity:[self count]];
    NSArray *sortedKeys = [[self allKeys] sortedArrayUsingSelector:comparator];
    [sortedKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        [concotinatedPairs addObject:[NSString stringWithFormat:@"%@%@%@", key, concotinationBetweenPairs, self[key]]];
    }];
    NSString *result = [concotinatedPairs componentsJoinedByString:concotinationBetweenItems];
    return result;
}


@end

@implementation NSString (OAHTTPClientExtensions)

- (NSString *)encodedURLParameterString
{
    NSString *result = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                             (CFStringRef)self,
                                                                                             NULL,
                                                                                             CFSTR(":/=,!$&'()*+;[]@#?"),
                                                                                             kCFStringEncodingUTF8);
	return result;
}

- (NSString *)signUsingSHA1WithSecret:(NSString *)secret
{
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [self dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CCHmacContext HMACContext;
    CCHmacInit(&HMACContext, kCCHmacAlgSHA1, [secretData bytes], [secretData length]);
    CCHmacUpdate(&HMACContext, [clearTextData bytes], [clearTextData length]);
    CCHmacFinal(&HMACContext, digest);
    return [[NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH] base64EncodedStringWithOptions:0];
}

@end

@implementation NSURLRequest (OAHTTPClientExtensions)

- (NSDictionary *)queryParameters;
{
    NSMutableDictionary *parameters = [[NSURLRequest queryParametersFromURL:[self URL]] mutableCopy];
    NSString *postQuery = [[NSString alloc] initWithData:[self HTTPBody] encoding:NSUTF8StringEncoding];
    [parameters addEntriesFromDictionary:[NSURLRequest parametersOfHTTPQuery:postQuery]];
    return [parameters copy];
}

+ (NSDictionary *)queryParametersFromURL:(NSURL *)URL
{
    NSString *query = [URL query];
    return [self parametersOfHTTPQuery:query];
}

+ (NSDictionary *)parametersOfHTTPQuery:(NSString *)query
{
    if (![query length]){
        return [NSDictionary dictionary];
    }
    
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([^&]+)=([^&]*)"
                                                                           options:0
                                                                             error:&error];
    NSAssert(regex, @"Failed to create regular expression: %@",[error localizedDescription]);
    NSMutableDictionary *queryParameter = [NSMutableDictionary dictionary];
    void(^enumerationBLock)(NSTextCheckingResult *, NSMatchingFlags , BOOL *)
    = ^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        if ([match numberOfRanges] >= 2) {
            NSString *key = [query substringWithRange:[match rangeAtIndex:1]];
            NSString *value = ([match numberOfRanges] > 2
                               ? [query substringWithRange:[match rangeAtIndex:2]] : @"");
            queryParameter[key] = value;
        }
    };
    [regex enumerateMatchesInString:query
                            options:0
                              range:NSMakeRange(0, [query length])
                         usingBlock:enumerationBLock];
    return [queryParameter copy];
}

@end

#pragma mark - OAuthHTTPClient

@interface ARDOAuthHTTPClient()

@property (readwrite, nonatomic, strong) NSString * oauthConsumerKey;
@property (readwrite, nonatomic, strong) NSString * oauthConsumerSecret;
@property (readwrite, nonatomic, strong) NSString * oauthToken;
@property (readwrite, nonatomic, strong) NSString * oauthTokenSecret;
@property (readwrite, nonatomic, assign, getter = isAuthenticated) BOOL authenticated;

@property (nonatomic, strong) NSString *oauthTimestamp;
@property (nonatomic, strong) NSString *oauthNonce;

@end

@implementation ARDOAuthHTTPClient

#pragma mark - Initialization

- (id)init
{
    NSString *errorMessageFormat = @"%@ Failed to call initializer. Invoke `initWithBaseURL:consumerKey:consumerSecret` instead.";
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:errorMessageFormat, NSStringFromClass([self class])]
                                 userInfo:nil];
}

- (id)initWithBaseURL:(NSURL *)url
{
    return [self init];
}

- (id)initWithBaseURL:(NSURL *)url
          consumerKey:(NSString *)oAuthConsumerKey
       consumerSecret:(NSString *)oAuthConsumerSecret;
{
    self = [super initWithBaseURL:url];
    if (self) {
        _oauthConsumerKey = oAuthConsumerKey;
        _oauthConsumerSecret = oAuthConsumerSecret;
    }
    return self;
}

- (id)initWithBaseURL:(NSURL *)url
                token:(NSString *)oAuthToken
          tokenSecret:(NSString *)oAuthTokenSecret
          consumerKey:(NSString *)oAuthConsumerKey
       consumerSecret:(NSString *)oAuthConsumerSecret;
{
    self = [self initWithBaseURL:url consumerKey:oAuthConsumerKey consumerSecret:oAuthConsumerSecret];
    if (self)
    {
        _oauthToken = oAuthToken;
        _oauthTokenSecret = oAuthTokenSecret;
    }
    return self;
}

#pragma mark - Public interface

- (BOOL)isAuthenticated
{
    return ([self.oauthToken length] && [self.oauthTokenSecret length]);
}

- (void)authenticateUsingXAuthWithURL:(NSString *)accessTokenPath
                             userName:(NSString *)userName
                             password:(NSString *)password
                              success:(void(^)(AFHTTPRequestOperation *operation, NSString *token, NSString *tokenSecret))success
                              failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSMutableDictionary *authorizationParamaters = [@{@"x_auth_username": userName,
                                                      @"x_auth_password": password,
                                                      @"x_auth_mode": xAuthMode} mutableCopy];
    
    [authorizationParamaters addEntriesFromDictionary:[self defeaulOAuthParameters]];
    
    NSMutableURLRequest *request = [self requestWithMethod:@"POST"
                                                      path:accessTokenPath
                                                parameters:nil
                                   authorizationParamaters:authorizationParamaters];
    [request setValue:@"text/html" forHTTPHeaderField:@"Accept"];
    
    void(^authorizationFailureHandler)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error){
        failure(operation, error);
    };

    void(^authorizationSuccessHandler)(AFHTTPRequestOperation *, NSData *) = ^(AFHTTPRequestOperation *operation, NSData *data){
        if ([self parseAuthenticationResponse:operation.responseString]) {
            success(operation, self.oauthToken, self.oauthTokenSecret);
        } else {
            NSString *errorDesicription = NSLocalizedString(@"Server returns wrong response",
                                                            @"Wrong authentication server response error descripton");
            failure(operation, [NSError errorWithDomain:ARDOAuthHTTPClientErrorDomain
                                                   code:ARDOAuthHTTPClientWrongResponse
                                               userInfo:@{NSLocalizedDescriptionKey: errorDesicription}]);
        };
    };
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request
                                                                      success:authorizationSuccessHandler
                                                                      failure:authorizationFailureHandler];
    [self enqueueHTTPRequestOperation:operation];
}

#pragma mark - AFHTTPClient's methods redefinition

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    NSDictionary *authorizationParamaters = [self defeaulOAuthParameters];
    NSMutableURLRequest *request = [self requestWithMethod:method
                                                      path:path
                                                parameters:parameters
                                   authorizationParamaters:authorizationParamaters];
    return request;
}

#pragma mark - Internal implementation

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
                   authorizationParamaters:(NSDictionary *)authorizationParamaters
{
    NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:parameters];
    NSDictionary *requestParameters = [request queryParameters];
    NSString *authorizationHeaderString = [self authorizationHeaderWithParameters:requestParameters
                                                          authorizationParamaters:authorizationParamaters
                                                                       requestURL:[request URL]
                                                                  usingHTTPMethod:[request HTTPMethod]];
    
    [request addValue:authorizationHeaderString forHTTPHeaderField:@"Authorization"];
    
    return request;
}

- (NSString *)authorizationHeaderWithParameters:(NSDictionary *)requestParameters
                        authorizationParamaters:(NSDictionary *)authorizationParamaters
                                     requestURL:(NSURL *)URL
                                usingHTTPMethod:(NSString *)HTTPMethod
{
    NSMutableDictionary *adaptedParameters = [NSMutableDictionary dictionaryWithCapacity:[authorizationParamaters count]];
    [authorizationParamaters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        adaptedParameters[key] = [NSString stringWithFormat:@"\"%@\"", value];
    }];
    NSString *signature = [self signatureWithParameters:requestParameters
                                        authorizationParamaters:authorizationParamaters
                                                     requestURL:URL
                                                usingHTTPMethod:HTTPMethod];
    NSString *authorizationHeader = [adaptedParameters toStringWithItemsConcotination:@", "
                                                                   pairsConcotination:@"="
                                                                  sortKeysUsingSelector:@selector(compare:)];
    authorizationHeader = [NSString stringWithFormat:@"OAuth %@, oauth_signature=\"%@\"",
                           authorizationHeader,
                           [signature encodedURLParameterString]];
    return authorizationHeader;
}

- (NSString *)signatureWithParameters:(NSDictionary *)requestParameters
              authorizationParamaters:(NSDictionary *)authorizationParamaters
                           requestURL:(NSURL *)URL
                      usingHTTPMethod:(NSString *)HTTPMethod
{
    NSString *baseString = [self signatureBaseWithParameters:requestParameters
                                                   authorizationParamaters:authorizationParamaters
                                                                requestURL:URL
                                                           usingHTTPMethod:HTTPMethod];
    NSString *secret = [NSString stringWithFormat:@"%@&%@",
                        ([self.oauthConsumerSecret length] ? self.oauthConsumerSecret : @""),
                        ([self.oauthTokenSecret length] ? self.oauthTokenSecret : @"")];
    NSString *signature = [baseString signUsingSHA1WithSecret:secret];
    return signature;
}


- (NSString *)signatureBaseWithParameters:(NSDictionary *)requestParameters
                  authorizationParamaters:(NSDictionary *)authorizationParamaters
                               requestURL:(NSURL *)URL
                          usingHTTPMethod:(NSString *)HTTPMethod
{
    NSDictionary *parametersToSign = authorizationParamaters;
    if(requestParameters) {
        parametersToSign = [parametersToSign dictionaryMergedWithDictionary:requestParameters];
    }
    NSString *stringToSign = [parametersToSign toStringWithItemsConcotination:@"&"
                                                           pairsConcotination:@"="
                                                        sortKeysUsingSelector:@selector(compare:)];
    NSString *urlWithoutQuery = [[URL URLWithoutQuery] absoluteString];
    stringToSign = [NSString stringWithFormat:@"%@&%@&%@",
                            HTTPMethod,
                            [urlWithoutQuery encodedURLParameterString],
                            [stringToSign encodedURLParameterString]];
    return stringToSign;
}


- (NSDictionary *)defeaulOAuthParameters
{
    [self updateTimestampAndNonce];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       self.oauthTimestamp, @"oauth_timestamp",
                                       self.oauthNonce, @"oauth_nonce",
                                       oAuthSignatureMethod, @"oauth_signature_method",
                                       self.oauthConsumerKey, @"oauth_consumer_key",
                                       oAuthVersion ,@"oauth_version",
                                       nil];
    if ([self.oauthToken length])
        [parameters setObject:self.oauthToken forKey:@"oauth_token"];
    
    return parameters;
}

- (void)updateTimestampAndNonce
{
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    self.oauthTimestamp = [NSString stringWithFormat:@"%@", [@(floor(timestamp)) stringValue]];
    self.oauthNonce = [[NSUUID UUID] UUIDString];
}

- (BOOL)parseAuthenticationResponse:(NSString *)response
{
    NSString *baseRegex = @"%@=(.*?)(&|$)";
    NSString *tokenRegex = [NSString stringWithFormat:baseRegex, @"oauth_token"];
    NSString *tokenSecretRegex = [NSString stringWithFormat:baseRegex, @"oauth_token_secret"];
    NSString *token = [response firstMatchOfRegex: tokenRegex
                                                       captureGroupIndex:1];
    NSString *tokenSecret = [response firstMatchOfRegex:tokenSecretRegex
                                                             captureGroupIndex:1];
    if (!token || !tokenSecret) {
        return NO;
    }
    [self willChangeValueForKey:@"authenticated"];
    self.oauthToken = token;
    self.oauthTokenSecret = tokenSecret;
    [self didChangeValueForKey:@"authenticated"];
    return YES;
}

@end
