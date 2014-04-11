//
//  ARDReadabilityBookmark.h
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 9/30/13.
//  Copyright (c) 2013 com.slabko. All rights reserved.
//

#import "ARDReadabilityBookmark.h"
#import "ARDReadabilityDataFormatters.h"
#import "GTMNSString+HTML.h"

const NSUInteger ARDShortExcerptLength = 100;

@interface NSObject(ARDdynamicCast)

+ (instancetype)dynamicCast:(id)value;

@end

@implementation NSObject(ARDdynamicCast)

+ (instancetype)dynamicCast:(id)value
{
    if ([value isKindOfClass:self]) {
        return value;
    }
    return nil;
}

@end

@interface ARDReadabilityBookmark()
{
    NSDictionary *_bookmarkJSON;
    NSDictionary *_articleJSON;
    NSString *articleTitle;
    NSString *articleExcerpt;
    NSString *shortArticleExcerpt;
}
@end

@implementation ARDReadabilityBookmark {
    
}


- (id)initWithJSON:(id)JSON
{
    NSDictionary *dictionary = [NSDictionary dynamicCast:JSON];
    if (!dictionary) {
        return nil;
    }
    
    if (self = [super init]) {
        _bookmarkJSON = dictionary;
        id articleJSONValue = _bookmarkJSON[@"article"];
        _articleJSON = (articleJSONValue != [NSNull null] ? articleJSONValue : nil);
    }
    return self;
}


- (float)readPercent
{
    return [[NSNumber dynamicCast:_bookmarkJSON[@"read_percent"]] floatValue];
}

- (BOOL)isFavorite
{
    return [[NSNumber dynamicCast:_bookmarkJSON[@"favorite"]] boolValue];
}

- (NSUInteger)bookmarkId
{
    return [[NSNumber dynamicCast:_bookmarkJSON[@"id"]] integerValue];
}

- (NSDate *)dateAdded
{
    return [self dateFromString:[NSString dynamicCast:_bookmarkJSON[@"date_added"]]];
}

- (NSDate *)dateUpdated
{
    return [self dateFromString:[NSString dynamicCast:_bookmarkJSON[@"date_updated"]]];
}

- (BOOL)isArchived
{
    return [[NSNumber dynamicCast:_bookmarkJSON[@"archive"]] boolValue];
}

- (NSString *)articleId
{
    return [NSString dynamicCast:_articleJSON[@"id"]];
}

- (NSString *)articleTitle
{
    if (!articleTitle) {
        articleTitle = [[NSString dynamicCast:_articleJSON[@"title"]] gtm_stringByUnescapingFromHTML];
    }
    return articleTitle;
}

- (NSString *)articleExcerpt
{
    if (!articleExcerpt) {
        articleExcerpt = [[NSString dynamicCast:_articleJSON[@"excerpt"]] gtm_stringByUnescapingFromHTML];
    }
    return articleExcerpt;
}

- (NSString *)shortArticleExcerpt {
    if (!shortArticleExcerpt) {
        if (self.articleExcerpt.length < ARDShortExcerptLength) {
            shortArticleExcerpt = self.articleExcerpt;
        } else {
            shortArticleExcerpt = [[self.articleExcerpt substringToIndex:ARDShortExcerptLength] stringByAppendingString:@"..."];
        }
    }
    return shortArticleExcerpt;
}

- (NSDate *)articleDatePublished
{
    return [self dateFromString:[NSString dynamicCast:_articleJSON[@"date_published"]]];
}

- (NSString *)articleURL
{
    return [NSString dynamicCast:_articleJSON[@"url"]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{%lu, %@ (%@), %@, %d}", self.bookmarkId, self.articleTitle, self.articleId,
            self.dateUpdated, self.isFavorite];
}

- (NSDate *)dateFromString:(NSString *)string
{
    return [ARDReadabilityOutputDataFormatter() dateFromString:string];
}

@end
