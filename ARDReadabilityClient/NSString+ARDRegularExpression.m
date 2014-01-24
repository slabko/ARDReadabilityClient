//
//  NSString+ARDRegularExpression.m
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 9/25/13.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import "NSString+ARDRegularExpression.h"

@implementation NSString (ARDRegularExpression)

- (NSString *)firstMatchOfRegex:(NSString *)pattern captureGroupIndex:(NSInteger)captureGroupIndex
{
    NSParameterAssert(pattern);
    if (![self length]){
        return nil;
    }
    
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSAssert(regex, @"Error creating regular expression: %@", [error localizedDescription]);

    NSTextCheckingResult *match = [regex firstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
    if (match && [match numberOfRanges] > captureGroupIndex) {
        NSRange range = [match rangeAtIndex:captureGroupIndex];
        return [self substringWithRange:range];
    }
    return nil;
}

@end