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
#import "HBBVideoScan.h"
#import "HBBLangData.h"

@implementation HBBInputFile
@synthesize inputURL, outputURL, size, audioLanguages, subtitleLanguages;

- (id)initWithURL:(NSURL *)u {
    self = [super init];
    
    if (self) {
        [self setInputURL:u];
        NSFileManager *man = [[NSFileManager alloc] init];
        NSDictionary *attrs = [man attributesOfItemAtPath: [u path] error: NULL];
        size = (NSInteger)[attrs fileSize];

        HBBVideoScan *scan = [[HBBVideoScan alloc] initWithFile:[u path]];
        
        [scan scan];
        
        audioLanguages = [[scan audioLanguages] copy];
        subtitleLanguages = [[scan subtitleLanguages] copy];
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

- (NSString *)plainLanguageList:(NSArray *)list {
    NSMutableString *resultList = [[NSMutableString alloc] init];
    
    if ([list count] == 0) {
        return @"None";
    } else {
        for (NSString *langCode in list) {
            NSString *lang = [[HBBLangData defaultHBBLangData] langName:langCode];
            if ([resultList length] == 0)
                [resultList appendString:lang];
            else
                [resultList appendFormat:@", %@", lang];
        }
    }
    
    return resultList;
}

- (NSString *)plainAudioLanguageList {
    return [self plainLanguageList:audioLanguages];
}

- (NSString *)plainSubtitleLanguageList {
    return [self plainLanguageList:subtitleLanguages];
}

@end
