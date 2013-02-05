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
@synthesize inputURL, outputURL, tempOutputURL, size, audioLanguages, subtitleLanguages;

- (id)initWithURL:(NSURL *)url {
    self = [self init];
    
    if (self) {
        [self setInputURL:url];
        NSFileManager *man = [[NSFileManager alloc] init];
        NSDictionary *attrs = [man attributesOfItemAtPath: [url path] error: NULL];
        size = (NSInteger)[attrs fileSize];

        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBScanEnabled"]) {
            HBBVideoScan *scan = [[HBBVideoScan alloc] initWithFile:[url path]];
        
            [scan scan];
        
            audioLanguages = [[scan audioLanguages] copy];
            subtitleLanguages = [[scan subtitleLanguages] copy];
        } else {
            audioLanguages = [[NSArray alloc] init];
            subtitleLanguages = [[NSArray alloc] init];
        }
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

- (NSString *) tempOutputPath {
    return [tempOutputURL path];
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

// NSCoding methods
- (id)initWithCoder:(NSCoder *)coder {
    if (self=[super init]) {
        [self setInputURL:[coder decodeObject]];
        [self setOutputURL:[coder decodeObject]];
        [self setTempOutputURL:[coder decodeObject]];

        NSFileManager *man = [[NSFileManager alloc] init];
        NSDictionary *attrs = [man attributesOfItemAtPath: [inputURL path] error: NULL];
        size = (NSInteger)[attrs fileSize];

        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBScanEnabled"]) {
            HBBVideoScan *scan = [[HBBVideoScan alloc] initWithFile:[inputURL path]];

            [scan scan];

            audioLanguages = [[scan audioLanguages] copy];
            subtitleLanguages = [[scan subtitleLanguages] copy];
        } else {
            audioLanguages = [[NSArray alloc] init];
            subtitleLanguages = [[NSArray alloc] init];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:inputURL];
    [coder encodeObject:outputURL];
    [coder encodeObject:tempOutputURL];
}

@end
