//
//  HBBInputFile.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 30/04/2011.
//  Copyright 2011 Murex SEA. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HBBInputFile : NSObject {
    NSURL *url;
}

@property (readonly)NSString *name;
@property (assign)NSURL *url;

- (id)initWithURL:(NSURL *)u;

@end
