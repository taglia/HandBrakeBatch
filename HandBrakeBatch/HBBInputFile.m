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
@synthesize url, size;

- (id)initWithURL:(NSURL *)u {
    self = [super init];
    
    if (self) {
        [self setUrl:u];
        NSFileManager *man = [[NSFileManager alloc] init];
        NSDictionary *attrs = [man attributesOfItemAtPath: [u path] error: NULL];
        size = [attrs fileSize];

    }
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
