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

@interface HBBVideoScan ()

@property (readwrite, strong, nonatomic) NSString *fileName;
@property (readwrite, strong, nonatomic) NSMutableArray *mutableAudioLanguages;
@property (readwrite, strong, nonatomic) NSMutableArray *mutableSubtitleLanguages;

@end

@implementation HBBVideoScan

@synthesize fileName, audioLanguages, subtitleLanguages;

- (id)initWithFile:(NSString *)path {
	self = [self init];

	[self setFileName:path];

	return self;
}

- (id)init {
	self = [super init];

	if (self) {
		self.mutableAudioLanguages = [[NSMutableArray alloc] init];
		self.mutableSubtitleLanguages = [[NSMutableArray alloc] init];
	}

	return self;
}

- (NSArray *)audioLanguages {
	return [self.mutableAudioLanguages copy];
}

- (NSArray *)subtitleLanguages {
	return [self.mutableSubtitleLanguages copy];
}

- (void)scan {
	NSTask *task = [[NSTask alloc] init];
	NSPipe *stdOutPipe = [NSPipe pipe];

	[task setStandardOutput:stdOutPipe];
	[task setStandardError:[task standardOutput]];

	// No perf issues here, so we always use the 32 bit version
	[task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"HandBrakeCLI" ofType:@""]];

	// Setting arguments
	[task setArguments:@[@"--scan", @"-i", fileName]];

	// Executing scan
	[task launch];

	for (int i = 0; i < 10 && [task isRunning]; ++i) {
		[NSThread sleepForTimeInterval:.5];
	}

	// If the scan is not completed in 5 seconds, let's kill it
	if ([task isRunning]) {
		[task terminate];
	}

	NSData *output = [[stdOutPipe fileHandleForReading] readDataToEndOfFile];

	NSString *stringData = [NSString stringWithCString:[output bytes] encoding:NSASCIIStringEncoding];

	NSArray *outputLines = [stringData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

	NSUInteger audioIndex = [outputLines indexOfObject:@"  + audio tracks:"];
	NSUInteger subtitleIndex = [outputLines indexOfObject:@"  + subtitle tracks:"];

	// Reset languages
	[self.mutableAudioLanguages removeAllObjects];
	[self.mutableSubtitleLanguages removeAllObjects];

	if (audioIndex != NSNotFound) {
		while ([outputLines[++audioIndex] length] > 4 && [outputLines[audioIndex] characterAtIndex:4] == '+') {
			NSRange range = [outputLines[audioIndex] rangeOfString:@"iso639-2: "];
			[self.mutableAudioLanguages addObject:[outputLines[audioIndex] substringWithRange:NSMakeRange(range.location + range.length, 3)]];
		}
	}

	if (subtitleIndex != NSNotFound) {
		while ([outputLines[++audioIndex] length] > 4 && [outputLines[subtitleIndex] characterAtIndex:4] == '+') {
			NSRange range = [outputLines[subtitleIndex] rangeOfString:@"iso639-2: "];
			[self.mutableSubtitleLanguages addObject:[outputLines[subtitleIndex] substringWithRange:NSMakeRange(range.location + range.length, 3)]];
		}
	}
}

@end
