//
//  ARDReadabilityBookmark.h
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 9/30/13.
//  Copyright (c) 2013 com.slabko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARDReadabilityBookmark : NSObject

@property (readonly, nonatomic) NSUInteger bookmarkId;
@property (readonly, nonatomic) float readPercent;
@property (readonly, nonatomic) NSDate *dateUpdated;
@property (readonly, nonatomic, getter = isFavorite) BOOL favorite;
@property (readonly, nonatomic) NSDate *dateAdded;
@property (readonly, nonatomic, getter = isArchived) BOOL archived;

@property (readonly, nonatomic) NSString *articleId;
@property (readonly, nonatomic) NSString *articleTitle;
@property (readonly, nonatomic) NSString *articleExcerpt;
@property (readonly, nonatomic) NSDate *articleDatePublished;
@property (readonly, nonatomic) NSString *articleURL;

@end
