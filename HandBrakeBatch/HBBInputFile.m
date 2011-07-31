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
@synthesize inputURL, outputURL, size;

- (id)initWithURL:(NSURL *)u {
    self = [super init];
    
    if (self) {
        [self setInputURL:u];
        NSFileManager *man = [[NSFileManager alloc] init];
        NSDictionary *attrs = [man attributesOfItemAtPath: [u path] error: NULL];
        size = (NSInteger)[attrs fileSize];

    }
    return self;
}

- (NSString *)name {
    return [inputURL lastPathComponent];
}

- (NSString *)inputPath {
    return [inputURL path];
}

- (NSString *) outputPath {
    return [outputURL path];
}

- (id)copyWithZone:(NSZone *)zone {    
    return nil;
}

@end
