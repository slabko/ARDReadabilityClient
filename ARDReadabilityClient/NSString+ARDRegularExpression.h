//
//  NSString+ARDRegularExpression.h
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 9/25/13.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (ARDRegularExpression)

- (NSString *)firstMatchOfRegex:(NSString *)pattern captureGroupIndex:(NSInteger)captureGroupIndex;

@end
