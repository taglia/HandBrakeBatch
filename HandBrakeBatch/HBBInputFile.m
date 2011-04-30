//
//  HBBInputFile.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 30/04/2011.
//  Copyright 2011 Murex SEA. All rights reserved.
//

#import "HBBInputFile.h"


@implementation HBBInputFile
@synthesize url;

- (id)initWithURL:(NSURL *)u {
    self = [super init];
    
    if (self)
        [self setUrl:u];
    return self;
}

- (NSString *)name {
    return [url lastPathComponent];
}

- (id)copyWithZone:(NSZone *)zone {    
    return nil;
}

@end
