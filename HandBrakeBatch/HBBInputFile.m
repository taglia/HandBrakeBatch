//
//  HBBInputFile.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
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

- (NSString *)path {
    return [url path];
}

- (id)copyWithZone:(NSZone *)zone {    
    return nil;
}

@end
