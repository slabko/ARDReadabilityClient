//
//  ARDReadabilityDataFormatters.m
//  ARDReadabilityClient
//
//  Created by Andrew Slabko on 10/12/13.
//  Copyright (c) 2014 ru.slabko. All rights reserved.
//

#import "ARDReadabilityDataFormatters.h"

NSDateFormatter *ARDReadabilityInputDataFormatter()
{
    static NSDateFormatter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NSDateFormatter alloc] init];
        [instance setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        [instance setTimeZone:[NSTimeZone systemTimeZone]];
    });
    return instance;
}

NSDateFormatter *ARDReadabilityOutputDataFormatter()
{
    static NSDateFormatter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NSDateFormatter alloc] init];
        [instance setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [instance setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"EST"]];
    });
    return instance;
}