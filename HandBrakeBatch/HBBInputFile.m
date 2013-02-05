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

@interface HBBInputFile ()

@property (readwrite, strong, nonatomic) NSString *name;
@property (readwrite, strong, nonatomic) NSString *inputPath;
@property (readwrite, strong, nonatomic) NSString *outputPath;
@property (readwrite, strong, nonatomic) NSString *tempOutputPath;
@property (readwrite, strong, nonatomic) NSURL *inputURL;
//@property (readwrite, strong, nonatomic) NSURL *outputURL;
//@property (readwrite, strong, nonatomic) NSURL *tempOutputURL;
@property (readwrite, assign, nonatomic) NSUInteger size;
@property (readwrite, strong, nonatomic) NSArray *audioLanguages;
@property (readwrite, strong, nonatomic) NSArray *subtitleLanguages;

@end

@implementation HBBInputFile

- (id)initWithURL:(NSURL *)url {
    self = [self init];
    
    if (self) {
        [self setInputURL:url];
        NSFileManager *man = [[NSFileManager alloc] init];
        NSDictionary *attrs = [man attributesOfItemAtPath:[url path] error:NULL];
        self.size = [attrs fileSize];

        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBScanEnabled"]) {
            HBBVideoScan *scan = [[HBBVideoScan alloc] initWithFile:[url path]];
            [scan scan];
            self.audioLanguages = [scan.audioLanguages copy];
            self.subtitleLanguages = [scan.subtitleLanguages copy];
        } else {
            self.audioLanguages = [[NSArray alloc] init];
            self.subtitleLanguages = [[NSArray alloc] init];
        }
    }
    return self;
}

- (NSString *)name {
    return [self.inputURL lastPathComponent];
}

- (NSString *)inputPath {
    return [self.inputURL path];
}

- (NSString *) outputPath {
    return [self.outputURL path];
}

- (NSString *) tempOutputPath {
    return [self.tempOutputURL path];
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
            NSString *lang = [HBBLangData.defaultHBBLangData langName:langCode];
            if ([resultList length] == 0)
                [resultList appendString:lang];
            else
                [resultList appendFormat:@", %@", lang];
        }
    }
    return resultList;
}

- (NSString *)plainAudioLanguageList {
    return [self plainLanguageList:self.audioLanguages];
}

- (NSString *)plainSubtitleLanguageList {
    return [self plainLanguageList:self.subtitleLanguages];
}

// NSCoding methods
- (id)initWithCoder:(NSCoder *)coder {
    if (self=[super init]) {
        [self setInputURL:[coder decodeObject]];
        [self setOutputURL:[coder decodeObject]];
        [self setTempOutputURL:[coder decodeObject]];

        NSFileManager *man = [[NSFileManager alloc] init];
        NSDictionary *attrs = [man attributesOfItemAtPath: [self.inputURL path] error:NULL];
        self.size = (NSInteger)[attrs fileSize];

        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBScanEnabled"]) {
            HBBVideoScan *scan = [[HBBVideoScan alloc] initWithFile:[self.inputURL path]];
            [scan scan];
            self.audioLanguages = [scan.audioLanguages copy];
            self.subtitleLanguages = [scan.subtitleLanguages copy];
        } else {
            self.audioLanguages = [[NSArray alloc] init];
            self.subtitleLanguages = [[NSArray alloc] init];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.inputURL];
    [coder encodeObject:self.outputURL];
    [coder encodeObject:self.tempOutputURL];
}

@end
