//
//  ARDAsyncLock.m
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 19/01/14.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import "ARDAsyncLock.h"

@interface ARDAsyncLock(){
@private
    BOOL _callOccurred;
}

@end

@implementation ARDAsyncLock

- (BOOL)waitUntilDate:(NSDate *)limit
{
    _callOccurred = NO;
    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    [runloop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    while (!_callOccurred && [limit timeIntervalSinceNow] > 0.0) {
        [runloop runMode:NSDefaultRunLoopMode beforeDate:limit];
    }
    if (!_callOccurred) {
        return NO;
    }
    return YES;
}

- (void)wait
{
    [self waitUntilDate:[NSDate distantFuture]];
}

- (void)signal
{
    _callOccurred = YES;
}

@end
