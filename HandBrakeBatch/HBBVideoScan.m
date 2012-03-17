//
//  HBBVideoScan.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 16/01/2012.
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import "HBBVideoScan.h"

@implementation HBBVideoScan

@synthesize fileName, audioLanguages, subtitleLanguages;

-(id)initWithFile:(NSString *)path {
    self = [self init];
    
    [self setFileName:path];
    
    return self;
}

- (id)init {
    self = [super init];

    if (self) {
        audioLanguages = [[NSMutableArray alloc] init];
        subtitleLanguages = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void)scan {
    NSTask *task = [[NSTask alloc] init];
    NSPipe *stdOutPipe = [NSPipe pipe];
    
    [task setStandardOutput:stdOutPipe];
    [task setStandardError: [task standardOutput]];
    
    // No perf issues here, so we always use the 32 bit version
    [task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"HandBrakeCLI_32" ofType:@""]];
    
    // Setting arguments
    [task setArguments:[NSArray arrayWithObjects:@"--scan", @"-i", fileName, nil]];
    
    // Executing scan
    [task launch];
    for (int i = 0; i < 4 && [task isRunning]; ++i) {
        [NSThread sleepForTimeInterval: .5];
    }
    
    // If the scan is not completed in 2 seconds, let's kill it
    if ([task isRunning])
        [task terminate];
    
    NSData *output = [[stdOutPipe fileHandleForReading] readDataToEndOfFile];
    
    NSString *stringData = [NSString stringWithCString:[output bytes] encoding:NSASCIIStringEncoding];

    NSArray *outputLines = [stringData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSUInteger audioIndex = [outputLines indexOfObject:@"  + audio tracks:"];
    NSUInteger subtitleIndex = [outputLines indexOfObject:@"  + subtitle tracks:"];
    
    // Reset languages
    [audioLanguages removeAllObjects];
    [subtitleLanguages removeAllObjects];
    
    if (audioIndex != NSNotFound) {
        while ([[outputLines objectAtIndex:++audioIndex] characterAtIndex:4] == '+') {
            NSRange range = [[outputLines objectAtIndex:audioIndex] rangeOfString:@"iso639-2: "];
            [audioLanguages addObject:[[outputLines objectAtIndex:audioIndex] substringWithRange:NSMakeRange(range.location + range.length, 3)]];
        }
    }
    
    if (subtitleIndex != NSNotFound) {
        while ([[outputLines objectAtIndex:++subtitleIndex] characterAtIndex:4] == '+') {
            NSRange range = [[outputLines objectAtIndex:subtitleIndex] rangeOfString:@"iso639-2: "];
            [subtitleLanguages addObject:[[outputLines objectAtIndex:subtitleIndex] substringWithRange:NSMakeRange(range.location + range.length, 3)]];
        }
    }
}

@end
