//
//  HBBProgressController.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import <Growl/Growl.h>
#import "HBBProgressController.h"
#import "HBBPresets.h"
#import "HBBLangData.h"

#define FILES_OK            0
#define FILE_EXISTS         1
#define INPUT_EQUALS_OUTPUT 2

#define M4V_EXTENSION       0

@implementation HBBProgressController

@synthesize queue;

- (id) init {
    self = [super initWithWindowNibName:@"HBBProgressWindow"];

    processedQueue = [[NSMutableArray alloc] init];
    suspended = false;
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

- (IBAction) cancelButtonAction:(id)sender {
    cancel = TRUE;
    [timer invalidate];
    [backgroundTask terminate];
    [progressWheel stopAnimation:self];
    
    NSBeginAlertSheet(@"Operation canceled", @"Ok", nil, nil, [self window], self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, NULL, @"%d files have been converted, %d remaining.", [processedQueue count], [currentQueue count]);
}

- (IBAction)pauseButtonAction:(id)sender {
    if (suspended) {
        [backgroundTask resume];
        [progressWheel startAnimation:self];
        [pausedLabel setHidden:true];
        suspended = false;
    } else {
        [backgroundTask suspend];
        [progressWheel stopAnimation:self];
        [pausedLabel setHidden:false];
        suspended = true;
    }
}

-(void) prepareTask {
    // Initialize NSTask
    backgroundTask = [[NSTask alloc] init];
    [backgroundTask setStandardOutput: [NSPipe pipe]];
    [backgroundTask setStandardError: [backgroundTask standardOutput]];
    [backgroundTask setLaunchPath: handBrakeCLI];
    
    NSString *inputFilePath = [[currentQueue objectAtIndex:0] inputPath];
        
    NSString *outputFilePath = [outputFolder stringByAppendingPathComponent:[[[inputFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:fileExtension] lastPathComponent]];
    
    // Deal with EyeTV files
    if ([[inputFilePath pathExtension] isEqualToString:@"eyetv"]) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *name;
        NSEnumerator *folderEnumerator = [fm enumeratorAtPath:inputFilePath];
        while (name = [folderEnumerator nextObject]) {
            if ([[name pathExtension] isEqualToString:@"mpg"]) {
                inputFilePath = [inputFilePath stringByAppendingPathComponent:name];
                break;
            }
        }
    }
    
    // Storing output path to quickly access it in case we need to tweek the timestamps
    [[currentQueue objectAtIndex:0] setOutputURL:[NSURL fileURLWithPath:outputFilePath]];
    
    // Additional Arguments
    NSMutableArray *allArguments = [NSMutableArray arrayWithArray:arguments];
    
    // Audio language arguments
    NSArray *audioLanguages = [[currentQueue objectAtIndex:0] audioLanguages];
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"HBBAudioSelection"] == 0) { // All languages
        NSMutableString *audioLanguageIDs = [NSMutableString stringWithString:@"1"];
        for (int i = 2; i <= [audioLanguages count]; ++i) {
            [audioLanguageIDs appendFormat:@",%d", i];
        }
        [allArguments addObjectsFromArray:[NSArray arrayWithObjects:@"-a", audioLanguageIDs, nil]];
    } else { // Preferred language (if available)
        NSString *bCode = [[HBBLangData defaultHBBLangData] langBCode:[[NSUserDefaults standardUserDefaults] objectForKey:@"HBBAudioPreferredLanguage"]];
        NSString *tCode = [[HBBLangData defaultHBBLangData] langTCode:[[NSUserDefaults standardUserDefaults] objectForKey:@"HBBAudioPreferredLanguage"]];
        int i=1;
        for (NSString *lang in audioLanguages) {
            if ([lang isEqualToString:bCode] || [lang isEqualToString:tCode]) {
                [allArguments addObjectsFromArray:[NSArray arrayWithObjects:@"-a", [NSString stringWithFormat:@"%d", i], nil]];
                break;
            }
            ++i;
        }
    }
    
    // Subtitle language arguments
    NSArray *subtitleLanguages = [[currentQueue objectAtIndex:0] subtitleLanguages];
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"HBBSubtitleSelection"] == 0) { // All languages
        NSMutableString *subtitleLanguageIDs = [NSMutableString stringWithString:@"1"];
        for (int i = 2; i <= [subtitleLanguages count]; ++i) {
            [subtitleLanguageIDs appendFormat:@",%d", i];
        }
        [allArguments addObjectsFromArray:[NSArray arrayWithObjects:@"-s", subtitleLanguageIDs, nil]];
    } else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"HBBSubtitleSelection"] == 1) { // Preferred language (if available)
        NSString *bCode = [[HBBLangData defaultHBBLangData] langBCode:[[NSUserDefaults standardUserDefaults] objectForKey:@"HBBSubtitlePreferredLanguage"]];
        NSString *tCode = [[HBBLangData defaultHBBLangData] langTCode:[[NSUserDefaults standardUserDefaults] objectForKey:@"HBBSubtitlePreferredLanguage"]];
        int i=1;
        for (NSString *lang in subtitleLanguages) {
            if ([lang isEqualToString:bCode] || [lang isEqualToString:tCode]) {
                [allArguments addObjectsFromArray:[NSArray arrayWithObjects:@"-s", [NSString stringWithFormat:@"%d", i], nil]];
                break;
            }
            ++i;
        }
    } // Else no subtitle, thus no need for any arguments
    
    [allArguments addObjectsFromArray:[NSArray arrayWithObjects:@"-i", inputFilePath, @"-o", outputFilePath, nil]];
    
    [backgroundTask setArguments: allArguments];
    
    // Set Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(getData:) 
                                                 name: NSFileHandleReadCompletionNotification 
                                               object: [[backgroundTask standardOutput] fileHandleForReading]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(taskCompleted:) 
                                                 name: NSTaskDidTerminateNotification
                                               object: nil];
    
    // Set the current file name in the progress window
    [messageField setStringValue:[[currentQueue objectAtIndex:0] name]];
    
    currentStartDate = [NSDate date];
    
    // Growl notification
    [GrowlApplicationBridge notifyWithTitle:@"HandBrakeBatch"
                                description:[NSString stringWithFormat:@"Starting conversion of %@", [inputFilePath lastPathComponent]]
                           notificationName:@"Starting new video conversion"
                                   iconData:[NSData data]
                                   priority:-1
                                   isSticky:NO
                               clickContext:nil];
    
    // We tell the file handle to go ahead and read in the background asynchronously, and notify
    // us via the callback registered above when we signed up as an observer.  The file handle will
    // send a NSFileHandleReadCompletionNotification when it has data that is available.
    [[[backgroundTask standardOutput] fileHandleForReading] readInBackgroundAndNotify];
}

// Check whether some files will be over-written during the conversion
- (BOOL)checkFiles {
    for (HBBInputFile *input in currentQueue) {
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:[input inputPath]])
            return FALSE;
    }
    return TRUE;
}

// Check whether the output folder contains some input files (not supported) and
// whether some files will be over-written during the conversion (warning displayed)
- (int) inputFilesChecks {
    for (HBBInputFile *input in currentQueue) {
        NSFileManager *fm = [NSFileManager defaultManager];

        NSString *inputFilePath = [input inputPath];
        NSString *outputFilePath = [outputFolder stringByAppendingPathComponent:[[[inputFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:fileExtension] lastPathComponent]];
        if ([inputFilePath isEqual:outputFilePath])
            return INPUT_EQUALS_OUTPUT;
        else if ([fm fileExistsAtPath:outputFilePath])
            return FILE_EXISTS; 
    }
    return FILES_OK;
}

- (void) startConversion {
    // Initialize progress bars
    [taskProgressBar setMinValue:0.0];
    [taskProgressBar setDoubleValue:0.0];
    [taskProgressBar setMaxValue:100.0];
    [taskProgressBar setIndeterminate:NO];
    [taskProgressBar startAnimation:self];
    
    [overallProgressBar setMinValue:0.0];
    [overallProgressBar setDoubleValue:0.0];
    [overallProgressBar setMaxValue:[queue count]*100.0];
    [overallProgressBar setIndeterminate:NO];
    [overallProgressBar startAnimation:self];
    
    [progressWheel startAnimation:self];
    
    // Prepare timer for the ETA estimation
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(estimateETA:) userInfo:nil repeats:YES];
    
    // Initialize total size to be converted (used to estimate the ETA)
    totalSize = 0;
    for (HBBInputFile *curFile in currentQueue) {
        totalSize += [curFile size];
    }
    remainingSize = totalSize;
    
    [self prepareTask];
    
    [backgroundTask launch];
}

// Entry point
- (void)processQueue {
    cancel = FALSE;
    
    overallStartDate = [NSDate date];
    
    // Initialize queue mutable copy
    currentQueue = [queue mutableCopy];
    
    // Check if we have a valid queue
    if (currentQueue == nil || [currentQueue count] == 0) {
        [[self window] orderOut:nil];
        return;
    }
    
    // Set appropriate HandBrakeCLI binary
    if ([[NSRunningApplication currentApplication] executableArchitecture] == NSBundleExecutableArchitectureX86_64) {
        handBrakeCLI = [[NSBundle mainBundle] pathForResource:@"HandBrakeCLI_64" ofType:@""];
    } else {
        handBrakeCLI = [[NSBundle mainBundle] pathForResource:@"HandBrakeCLI_32" ofType:@""];
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Initialization of common parameters
    // Build HandBrakeCLI arguments
    presets = [[HBBPresets hbbPresets] presets];
    selectedPresetName = [[NSUserDefaults standardUserDefaults] objectForKey:@"PresetName"];
    preset = [presets objectForKey:selectedPresetName];
    // Parsing arguments from preset line
    // The MPEG-4 file extension can be configured in the preferences
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"HBBMPEG4Extension"] == M4V_EXTENSION)
        fileExtension = [NSString stringWithString:@"m4v"];
    else
        fileExtension = [NSString stringWithString:@"mp4"];
    
    arguments = [[NSMutableArray alloc] init];

    BOOL ignoreFollowing = false;
    
    for (NSString *currentArg in [preset componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]) {
        
        // We filter out the -a x,y,z argument: added later depending on the audio language preferences
        if (!ignoreFollowing) {
            if ([currentArg isEqualToString:@"-a"]) {
                ignoreFollowing = true;
            } else {
                [arguments addObject:currentArg];
                
                // In case a preset specifies an mkv container as output format
                if ([currentArg isEqualToString:@"mkv"])
                    fileExtension = [NSString stringWithString:@"mkv"];
            }
        } else {
            ignoreFollowing = false;
        }
    }
    
    outputFolder = [[NSUserDefaults standardUserDefaults] objectForKey:@"OutputFolder"];
    
    // Check whether the output folder exists
    BOOL exists;
    BOOL isDir;
    exists = [[NSFileManager defaultManager] fileExistsAtPath:outputFolder isDirectory:&isDir];
    if (!exists || !isDir) {
        NSBeginAlertSheet(@"Output Folder does not exist", @"Ok", NULL, NULL, [self window], self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, NULL, @"Please make sure that the selected output folder exists.");
        return;
    }
    
    // Initialization of common parameters complete
    ////////////////////////////////////////////////////////////////////////////////////////////////
    
    int filesCheckResult = [self inputFilesChecks];
    switch (filesCheckResult) {
        case INPUT_EQUALS_OUTPUT:
            NSBeginCriticalAlertSheet(@"Input files in the output folder", @"Ok", NULL, NULL, [self window], self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, @"Stop", @"Some or all of the input files are in the output folder, please change the output folder!");
            break;
        
        case FILE_EXISTS:
            NSBeginAlertSheet(@"Existing files", @"Ok", @"Cancel", nil, [self window], self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, @"Warning", @"Some or all of the output files already exist. Are you sure you want to overwrite them?");
            break;
        
        default:
            [self startConversion];
            break;
    }
}

// Format a number of seconds as hh:mm:ss
-(NSString *) formatTime:(NSInteger)seconds {
    NSInteger h = seconds / 3600;
    NSInteger m = seconds / 60 - (h*60);
    NSInteger s = seconds % 60;
    
    return [NSString stringWithFormat:@"%0.2d:%0.2d:%0.2d", h, m, s];
}

-(void)estimateETA:(NSTimer *)theTimer {
    NSInteger overallElapsedTime = [[NSDate date] timeIntervalSinceDate:overallStartDate];
    NSInteger currentElapsedTime = [[NSDate date] timeIntervalSinceDate:currentStartDate];
    double estimatedCurrentETA;
    double estimatedOverallETA;
    
    [elapsed setStringValue:[self formatTime:overallElapsedTime]];
    
    if(suspended) {
        [currentETA setStringValue:@"--:--:--"];
        [overallETA setStringValue:@"--:--:--"];
        [pausedLabel setHidden:![pausedLabel isHidden]];
        return;
    }
    
    // Estimate ETA for the current task
    if (currentElapsedTime > 10) {
        estimatedCurrentETA = (currentElapsedTime / [taskProgressBar doubleValue] * 100) - currentElapsedTime;
        [currentETA setStringValue:[self formatTime:estimatedCurrentETA]];
    } else {
        [currentETA setStringValue:@"--:--:--"];
    }
    
    // Estimate overall ETA
    if (overallElapsedTime > 12) {
        if (currentElapsedTime < 12)
            return;
        NSInteger remaining = remainingSize - [(HBBInputFile *)[currentQueue objectAtIndex:0] size] * ([taskProgressBar doubleValue]/100.0);
        estimatedOverallETA = overallElapsedTime * (remaining / (totalSize - remaining));
        
        // Trying to avoid clearly wrong output
        if (estimatedOverallETA < estimatedCurrentETA || [currentQueue count] == 1)
            estimatedOverallETA = estimatedCurrentETA;

        [overallETA setStringValue:[self formatTime:estimatedOverallETA]];
    } else {
        [overallETA setStringValue:@"--:--:--"];
    }
}

#pragma mark Notification methods

-(void) taskCompleted:(NSNotification *)notification {
    if ([notification object] != backgroundTask || cancel || [currentQueue count] == 0)
        return;
    
    // Modify timestamps if required
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBMaintainTimestamps"]) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSDictionary *sourceAttrs = [fm attributesOfItemAtPath:[[currentQueue objectAtIndex:0] inputPath] error:NULL];
        NSDictionary *destAttrs = [fm attributesOfItemAtPath:[[currentQueue objectAtIndex:0] outputPath] error:NULL];
        
        if (sourceAttrs && destAttrs) {
            NSDate *creationDate = [sourceAttrs objectForKey:NSFileCreationDate];
            NSDate *modificationDate = [sourceAttrs objectForKey:NSFileModificationDate];
            
            NSMutableDictionary *destMutableAttrs = [destAttrs mutableCopy];
            [destMutableAttrs setObject:creationDate forKey:NSFileCreationDate];
            [destMutableAttrs setObject:modificationDate forKey:NSFileModificationDate];
            
            [fm setAttributes:destMutableAttrs ofItemAtPath:[[currentQueue objectAtIndex:0] outputPath] error:NULL];
        }
    }
    
    // Remove processed file from the queue
    remainingSize -= [(HBBInputFile *)[currentQueue objectAtIndex:0] size];
    [processedQueue addObject:[currentQueue objectAtIndex:0]];
    [currentQueue removeObjectAtIndex:0];

    // Check if all files have been processed
    if ([currentQueue count] == 0) {
        // Growl notification
        [GrowlApplicationBridge notifyWithTitle:@"HandBrakeBatch"
                                    description:@"All files have been converted"
                               notificationName:@"All files converted"
                                       iconData:[NSData data]
                                       priority:-1
                                       isSticky:NO
                                   clickContext:nil];
        
        [progressWheel stopAnimation:self];
        [timer invalidate];
        NSBeginAlertSheet(@"Conversion Complete", @"Ok", nil, nil, [self window], self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, NULL, @"%d files have been converted.", [processedQueue count]);
        return;
    }
    
    // Process next file
    [self prepareTask];
    [backgroundTask launch];
}

- (void) getData: (NSNotification *)aNotification
{
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    
    if ([data length])
    {
        NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        // Searching percentage of progress
        if ([message rangeOfString:@"Encoding: task"].location != NSNotFound) {
            NSString *percentString = [message substringWithRange:NSMakeRange(24, 5)];
            double percent = [percentString floatValue];
            double overallPercent = percent + [processedQueue count]*100.0;
            
            // Simple filter
            if (overallPercent > [overallProgressBar doubleValue]) {
                [taskProgressBar setDoubleValue:percent];
                [overallProgressBar setDoubleValue:overallPercent];
            }
        }
    }
    
    // we need to schedule the file handle go read more data in the background again.
    if ([backgroundTask isRunning])
        [[aNotification object] readInBackgroundAndNotify];
}

// Called when the alert sheet is dismissed
-(void) sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
    if ([(NSString *)contextInfo isEqual:@"Warning"]) {
        if (returnCode == NSAlertDefaultReturn) {
            [self startConversion];
            return;
        }
    }
        
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:processedQueue, currentQueue, nil]
                                                         forKeys:[NSArray arrayWithObjects:PROCESSED_QUEUE_KEY, CURRENT_QUEUE_KEY, nil]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:COMPLETE_NOTIFICATION object:self userInfo:userInfo];
    [self close];
}

@end
