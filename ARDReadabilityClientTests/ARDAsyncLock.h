//
//  ARDAsyncLock.h
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 19/01/14.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARDAsyncLock : NSObject

- (void)signal;
- (void)wait;
- (BOOL)waitUntilDate:(NSDate *)limit;

@end
