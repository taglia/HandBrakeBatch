//
//  HBBProgressController.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import <Foundation/NSAppleScript.h>
#import <Growl/Growl.h>
#import "HBBProgressController.h"
#import "HBBPresets.h"
#import "HBBLangData.h"

#define FILES_OK            0
#define FILE_EXISTS         1
#define INPUT_EQUALS_OUTPUT 2

#define M4V_EXTENSION       0

#define ACTION_NOTHING      0
#define ACTION_QUIT         1
#define ACTION_SLEEP        2
#define ACTION_SHUTDOWN     3

@interface HBBProgressController ()

@property (readwrite, assign, nonatomic) IBOutlet NSProgressIndicator *taskProgressBar;
@property (readwrite, assign, nonatomic) IBOutlet NSProgressIndicator *overallProgressBar;
@property (readwrite, assign, nonatomic) IBOutlet NSProgressIndicator *progressWheel;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *pausedLabel;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *messageField;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *currentETA;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *elapsed;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *processingLabel;

// Items remaining in the queue, to be processed
@property (readwrite, strong, nonatomic) NSMutableArray *currentQueue;

// Processed items
@property (readwrite, strong, nonatomic) NSMutableArray *processedQueue;
@property (readwrite, strong, nonatomic) NSMutableArray *failedQueue;

@property (readwrite, strong, nonatomic) NSTask *backgroundTask;
@property (readwrite, assign, nonatomic) BOOL suspended;
@property (readwrite, strong, nonatomic) NSString *handBrakeCLI;
@property (readwrite, assign, nonatomic) BOOL cancel;

// Start tireadwrite
@property (readwrite, strong, nonatomic) NSDate *overallStartDate;
@property (readwrite, strong, nonatomic) NSDate *currentStartDate;

@property (readwrite, strong, nonatomic) NSTimer *timer;

// Common preadwrites
@property (readwrite, strong, nonatomic) NSDictionary *presets;
@property (readwrite, strong, nonatomic) NSString *selectedPresetName;
@property (readwrite, strong, nonatomic) NSString *preset;
@property (readwrite, strong, nonatomic) NSString *fileExtension;
@property (readwrite, strong, nonatomic) NSMutableArray *arguments;
@property (readwrite, strong, nonatomic) NSString *outputFolder;

@end

@implementation HBBProgressController

@synthesize queue;

static long int totalFiles;
static long int currentFile = 1;

static NSMutableString *stdErrorString;

- (id)init {
    self = [super initWithWindowNibName:@"HBBProgressWindow"];

    self.processedQueue = [[NSMutableArray alloc] init];
    self.failedQueue = [[NSMutableArray alloc] init];
    self.suspended = NO;
    
    return self;
}

- (NSArray *)queue {
	return [self.currentQueue copy];
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (IBAction) cancelButtonAction:(id)sender {
    self.cancel = TRUE;
    [self.timer invalidate];
    [self.backgroundTask terminate];
    [self.progressWheel stopAnimation:self];
    
    NSBeginAlertSheet(@"Operation canceled", @"Ok", nil, nil, [self window], self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, NULL, @"%lu files have been converted, %lu remaining.", [self.processedQueue count], [self.currentQueue count]);
}

- (IBAction)pauseButtonAction:(id)sender {
    if (self.suspended) {
        [self.backgroundTask resume];
        [self.progressWheel startAnimation:self];
        [self.pausedLabel setHidden:YES];
        self.suspended = NO;
    } else {
        [self.backgroundTask suspend];
        [self.progressWheel stopAnimation:self];
        [self.pausedLabel setHidden:NO];
        self.suspended = YES;
    }
}

- (void)prepareTask {
    // Initialize NSTask
    self.backgroundTask = [[NSTask alloc] init];
    [self.backgroundTask setStandardOutput:[NSPipe pipe]];
    [self.backgroundTask setStandardError:[NSPipe pipe]];
    [self.backgroundTask setLaunchPath:self.handBrakeCLI];
    
    NSString *inputFilePath = [(self.currentQueue)[0] inputPath];
    
    NSString *fileName = [[inputFilePath stringByDeletingPathExtension] lastPathComponent];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBDestinationSameAsSource"]) {
        self.outputFolder = [inputFilePath stringByDeletingLastPathComponent];
	}
    NSString *outputFilePath = [self.outputFolder stringByAppendingPathComponent:[fileName stringByAppendingPathExtension:self.fileExtension]];
    
    NSString *tempOutputFilePath = [self.outputFolder stringByAppendingPathComponent:[NSString stringWithFormat:@".%@_%ld.%@", fileName, random(), self.fileExtension]];
    
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
    
    // Storing output path to quickly access it to move temp file to final, and in case we need to tweek the timestamps
	HBBInputFile *inputFile = (self.currentQueue)[0];
    [inputFile setOutputURL:[NSURL fileURLWithPath:outputFilePath]];
    [inputFile setTempOutputURL:[NSURL fileURLWithPath:tempOutputFilePath]];
    
    // Additional Arguments
    NSMutableArray *allArguments = [NSMutableArray arrayWithArray:self.arguments];
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"HBBScanEnabled"]) { // Process languages & subtitles only if scan enabled
        // Audio language arguments
        NSArray *audioLanguages = [(self.currentQueue)[0] audioLanguages];
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"HBBAudioSelection"] == 0) { // All languages
            if ([audioLanguages count]) { // Leave this alone if no languages are available
                NSMutableString *audioLanguageIDs = [NSMutableString stringWithString:@"1"];
                for (int i = 2; i <= [audioLanguages count]; ++i) {
                    [audioLanguageIDs appendFormat:@",%d", i];
                }
                [allArguments addObjectsFromArray:@[@"-a", audioLanguageIDs]];
            }
        } else { // Preferred language (if available)
            NSString *bCode = [[HBBLangData defaultHBBLangData] langBCode:[[NSUserDefaults standardUserDefaults] objectForKey:@"HBBAudioPreferredLanguage"]];
            NSString *tCode = [[HBBLangData defaultHBBLangData] langTCode:[[NSUserDefaults standardUserDefaults] objectForKey:@"HBBAudioPreferredLanguage"]];
            int i = 1;
            for (NSString *lang in audioLanguages) {
                if ([lang isEqualToString:bCode] || [lang isEqualToString:tCode]) {
                    [allArguments addObjectsFromArray:@[@"-a", [NSString stringWithFormat:@"%d", i]]];
                    break;
                }
                ++i;
            }
        }
        
        // Subtitle language arguments
        NSArray *subtitleLanguages = [(self.currentQueue)[0] subtitleLanguages];
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"HBBSubtitleSelection"] == 0) { // All languages
            if ([subtitleLanguages count]) { // Leave this alone if no subtitles are available
                NSMutableString *subtitleLanguageIDs = [NSMutableString stringWithString:@"1"];
                for (int i = 2; i <= [subtitleLanguages count]; ++i) {
                    [subtitleLanguageIDs appendFormat:@",%d", i];
                }
                [allArguments addObjectsFromArray:@[@"-s", subtitleLanguageIDs]];
            }
        } else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"HBBSubtitleSelection"] == 1) { // Preferred language (if available)
            NSString *bCode = [[HBBLangData defaultHBBLangData] langBCode:[[NSUserDefaults standardUserDefaults] objectForKey:@"HBBSubtitlePreferredLanguage"]];
            NSString *tCode = [[HBBLangData defaultHBBLangData] langTCode:[[NSUserDefaults standardUserDefaults] objectForKey:@"HBBSubtitlePreferredLanguage"]];
            int i = 1;
            for (NSString *lang in subtitleLanguages) {
                if ([lang isEqualToString:bCode] || [lang isEqualToString:tCode]) {
                    [allArguments addObjectsFromArray:@[@"-s", [NSString stringWithFormat:@"%d", i]]];
                    // Burn subtitles if required
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBSubtitleBurn"]) {
                        [allArguments addObjectsFromArray:@[@"--subtitle-burn", [NSString stringWithFormat:@"%d", i]]];
					}
                    break;
                }
                ++i;
            }
        } // Else no subtitle, thus no need for any arguments
    }
    
    [allArguments addObjectsFromArray:@[@"-i", inputFilePath, @"-o", tempOutputFilePath]];
    
    // Log arguments to CLI
    NSMutableString *args = [[NSMutableString alloc] init];
    for (NSString *arg in allArguments) {
        [args appendFormat:@"%@ ", arg];
    }
    NSLog(@"Calling CLI with arguments: %@", args);
    
    [self.backgroundTask setArguments: allArguments];
    
    // Set Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(getData:) 
                                                 name: NSFileHandleReadCompletionNotification 
                                               object: [[self.backgroundTask standardOutput] fileHandleForReading]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(taskCompleted:) 
                                                 name: NSTaskDidTerminateNotification
                                               object: nil];
    
    // Set the current file name in the progress window
    [self.messageField setStringValue:[(self.currentQueue)[0] name]];
    
    self.currentStartDate = [NSDate date];
    
    // Growl notification
    if ( ![[NSUserDefaults standardUserDefaults] boolForKey:@"HBBNotificationsDisabled"] ) {
        [GrowlApplicationBridge notifyWithTitle:@"HandBrakeBatch"
                                    description:[NSString stringWithFormat:@"Starting conversion of %@", [inputFilePath lastPathComponent]]
                               notificationName:@"Starting new video conversion"
                                       iconData:nil
                                       priority:-1
                                       isSticky:NO
                                   clickContext:nil];
    }
    
    // We tell the file handle to go ahead and read in the background asynchronously, and notify
    // us via the callback registered above when we signed up as an observer.  The file handle will
    // send a NSFileHandleReadCompletionNotification when it has data that is available.
    [[[self.backgroundTask standardOutput] fileHandleForReading] readInBackgroundAndNotify];
    
    // Creating a pipe to store STDERR (where HB CLI outputs the interesting information)
    // Will be stored in a file if required when the conversion is completed
    // We need to store the data to avoid the thread hanging if the pipe is full (happens for files with a lot of output, like MTS)
    [[[self.backgroundTask standardError] fileHandleForReading] readInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(storestdErrorString:) 
                                                 name: NSFileHandleReadCompletionNotification 
                                               object: [[self.backgroundTask standardError] fileHandleForReading]];
    
    stdErrorString = [[NSMutableString alloc] init];
}

- (void) startConversion {
    // Initialize progress bars
    [self.taskProgressBar setMinValue:0.0];
    [self.taskProgressBar setDoubleValue:0.0];
    [self.taskProgressBar setMaxValue:100.0];
    [self.taskProgressBar setIndeterminate:NO];
    [self.taskProgressBar startAnimation:self];
    
    [self.overallProgressBar setMinValue:0.0];
    [self.overallProgressBar setDoubleValue:0.0];
    [self.overallProgressBar setMaxValue:[queue count]*100.0];
    [self.overallProgressBar setIndeterminate:NO];
    [self.overallProgressBar startAnimation:self];
    
    [self.progressWheel startAnimation:self];
    
    // Prepare timer for the ETA estimation
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(incrementElapsed:) userInfo:nil repeats:YES];
        
    [self prepareTask];
    
    totalFiles = [queue count];
    currentFile = 0;
    [self.processingLabel setStringValue:[NSString stringWithFormat:@"Processing 1 / %ld", totalFiles]];
    
    [self.backgroundTask launch];
}

// Entry point
- (void)processQueue {
    self.cancel = FALSE;
    
    self.overallStartDate = [NSDate date];
    
    // Initialize queue mutable copy
    self.currentQueue = [queue mutableCopy];
    
    // Check if we have a valid queue
    if (self.currentQueue == nil || [self.currentQueue count] == 0) {
        [[self window] orderOut:nil];
        return;
    }
    
    self.handBrakeCLI = [[NSBundle mainBundle] pathForResource:@"HandBrakeCLI" ofType:@""];
    
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Initialization of common parameters
    // Build HandBrakeCLI arguments
    self.presets = [[HBBPresets hbbPresets] presets];
    self.selectedPresetName = [[NSUserDefaults standardUserDefaults] objectForKey:@"PresetName"];
    self.preset = (self.presets)[self.selectedPresetName];
    // Parsing arguments from preset line
    // The MPEG-4 file extension can be configured in the preferences
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"HBBMPEG4Extension"] == M4V_EXTENSION) {
        self.fileExtension = @"m4v";
    } else {
        self.fileExtension = @"mp4";
    }
    self.arguments = [[NSMutableArray alloc] init];

    BOOL ignoreFollowing = NO;
    
    for (NSString *currentArg in [self.preset componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]) {
        
        // We filter out the -a x,y,z argument: added later depending on the audio language preferences
        if (!ignoreFollowing) {
            if ([currentArg isEqualToString:@"-a"]) {
                ignoreFollowing = YES;
            } else {
                [self.arguments addObject:currentArg];
                
                // In case a preset specifies an mkv container as output format
                if ([currentArg isEqualToString:@"mkv"]) {
                    self.fileExtension = @"mkv";
				}
            }
        } else {
            ignoreFollowing = NO;
        }
    }
    
    self.outputFolder = [[NSUserDefaults standardUserDefaults] objectForKey:@"OutputFolder"];
    
    // Check whether the output folder exists
    BOOL exists;
    BOOL isDir;
    exists = [[NSFileManager defaultManager] fileExistsAtPath:self.outputFolder isDirectory:&isDir];
    if ((!exists || !isDir) && ![[NSUserDefaults standardUserDefaults] objectForKey:@"HBBDestinationSameAsSource"]) {
        NSBeginAlertSheet(@"Output Folder does not exist", @"Ok", NULL, NULL, [self window], self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, NULL, @"Please make sure that the selected output folder exists.");
        return;
    }
    
    // Initialization of common parameters complete
    ////////////////////////////////////////////////////////////////////////////////////////////////
    
    [self startConversion];
}

// Format a number of seconds as hh:mm:ss
-(NSString *) formatTime:(NSInteger)seconds {
    NSInteger h = seconds / 3600;
    NSInteger m = seconds / 60 - (h*60);
    NSInteger s = seconds % 60;
    
    return [NSString stringWithFormat:@"%0.2ld:%0.2ld:%0.2ld", h, m, s];
}

-(void)incrementElapsed:(NSTimer *)theTimer {
    NSInteger overallElapsedTime = [[NSDate date] timeIntervalSinceDate:self.overallStartDate];
    
    [self.elapsed setStringValue:[self formatTime:overallElapsedTime]];
    
    if (self.suspended) {
        [self.currentETA setStringValue:@"--:--:--"];
        [self.pausedLabel setHidden:![self.pausedLabel isHidden]];
        return;
    }
}

#pragma mark Notification methods

- (void)taskCompleted:(NSNotification *)notification {
    if ([notification object] != self.backgroundTask || self.cancel || [self.currentQueue count] == 0) {
        return;
    }
    // Removing observers for stdout and stderr
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:[[self.backgroundTask standardOutput] fileHandleForReading]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:[[self.backgroundTask standardError]  fileHandleForReading]];
    
    // First we need to empty the stdError pipe buffer
    NSFileHandle *file = [[self.backgroundTask standardError] fileHandleForReading];
    NSData *data = [file readDataToEndOfFile];
    
    if ([data length]) {
        NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [stdErrorString appendString:message];
    }
    
    // Check whether the conversion was successful and write log file if necessary
    NSData *stdErrData = [stdErrorString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *logFilePath = [[[(self.currentQueue)[0] outputPath] stringByDeletingPathExtension] stringByAppendingPathExtension:@"log"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[(self.currentQueue)[0] tempOutputURL] path]]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBWriteConversionLog"]) {
            [stdErrData writeToURL:[NSURL fileURLWithPath:logFilePath] atomically:NO];
        }
        
        // Modify timestamps if required
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBMaintainTimestamps"]) {
            NSFileManager *fm = [NSFileManager defaultManager];
            NSDictionary *sourceAttrs = [fm attributesOfItemAtPath:[(self.currentQueue)[0] inputPath] error:NULL];
            NSDictionary *destAttrs = [fm attributesOfItemAtPath:[(self.currentQueue)[0] tempOutputPath] error:NULL];
            
            if (sourceAttrs && destAttrs) {
                NSDate *creationDate = sourceAttrs[NSFileCreationDate];
                NSDate *modificationDate = sourceAttrs[NSFileModificationDate];
                
                NSMutableDictionary *destMutableAttrs = [destAttrs mutableCopy];
                destMutableAttrs[NSFileCreationDate] = creationDate;
                destMutableAttrs[NSFileModificationDate] = modificationDate;
                
                [fm setAttributes:destMutableAttrs ofItemAtPath:[(self.currentQueue)[0] tempOutputPath] error:NULL];
            }
        }
        
        // Remove destination file if it exists
        if ([[NSFileManager defaultManager] fileExistsAtPath:[[(self.currentQueue)[0] outputURL] path]]) {
            [[NSFileManager defaultManager] removeItemAtURL:[(self.currentQueue)[0] outputURL] error:nil];
        }
        // Remove source file if needed
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBDeleteSourceFiles"]) {
            [[NSFileManager defaultManager] removeItemAtURL:[(self.currentQueue)[0] inputURL] error:nil];
        }
        
        // Moving temp output file to destination
        [[NSFileManager defaultManager] moveItemAtURL:[(self.currentQueue)[0] tempOutputURL] toURL:[(self.currentQueue)[0] outputURL] error:nil];
        
        [self.processedQueue addObject:(self.currentQueue)[0]];
    } else {
        // Conversion failed! Write log file and do not delete source
        [stdErrData writeToURL:[NSURL fileURLWithPath:logFilePath] atomically:NO];
        
        [self.failedQueue addObject:(self.currentQueue)[0]];
    }
    
    // Remove processed file from the queue
    [self.currentQueue removeObjectAtIndex:0];

    // Check if all files have been processed
    if ([self.currentQueue count] == 0) {
        // Growl notification
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HBBNotificationsDisabled"]) {
            [GrowlApplicationBridge notifyWithTitle:@"HandBrakeBatch"
                                        description:@"All files have been converted"
                                   notificationName:@"All files converted"
                                           iconData:nil
                                           priority:-1
                                           isSticky:NO
                                       clickContext:nil];
        }
        
        // Deal with after conversion actions
        NSInteger actionIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"HBBAfterConversion"];
        NSAppleScript *script;
        NSDictionary *errorInfo;
        switch (actionIndex) {
            case ACTION_QUIT:
                NSLog(@"Conversion completed - Quitting HBB");
                if ( ![[NSUserDefaults standardUserDefaults] boolForKey:@"HBBNotificationsDisabled"] ) {
                    [GrowlApplicationBridge notifyWithTitle:@"HandBrakeBatch"
                                                description:[NSString stringWithFormat:@"HandBrakeBatch is quitting after completing the conversion"]
                                           notificationName:@"Quitting HandBrakeBatch"
                                                   iconData:nil
                                                   priority:-1
                                                   isSticky:NO
                                               clickContext:nil];
                }
                [NSApp terminate: nil];
                break;
                
            case ACTION_SLEEP:
                NSLog(@"Conversion completed - Putting the Mac to sleep");
                if ( ![[NSUserDefaults standardUserDefaults] boolForKey:@"HBBNotificationsDisabled"] ) {
                    [GrowlApplicationBridge notifyWithTitle:@"HandBrakeBatch"
                                                description:[NSString stringWithFormat:@"HandBrakeBatch is asking your Mac to sleep after completing the conversion"]
                                           notificationName:@"Putting the Mac to sleep"
                                                   iconData:nil
                                                   priority:-1
                                                   isSticky:NO
                                               clickContext:nil];
                }
                script = [[NSAppleScript alloc] initWithSource:@"tell application \"System Events\" to sleep"];
                [script executeAndReturnError:&errorInfo];
                [script release];
                break;
                
            case ACTION_SHUTDOWN:
                NSLog(@"Conversion completed - Shutting down the Mac");
                if ( ![[NSUserDefaults standardUserDefaults] boolForKey:@"HBBNotificationsDisabled"] ) {
                    [GrowlApplicationBridge notifyWithTitle:@"HandBrakeBatch"
                                                description:[NSString stringWithFormat:@"HandBrakeBatch is shutting down your Mac after completing the conversion"]
                                           notificationName:@"Shutting down this Mac"
                                                   iconData:nil
                                                   priority:-1
                                                   isSticky:NO
                                               clickContext:nil];
                }
                script = [[NSAppleScript alloc] initWithSource:@"tell application \"Finder\" to shut down"];
                [script executeAndReturnError:&errorInfo];
                [script release];
                [NSApp terminate: nil];
                break;
        }
        
        [self.progressWheel stopAnimation:self];
        [self.timer invalidate];
        NSString *message;
        if ([self.failedQueue count] == 0) {
            message = [NSString stringWithFormat:@"All %lu files have been converted successfully!", [self.processedQueue count]];
        } else {
            message = [NSString stringWithFormat:@"%lu files have been converted successfully.\n%lu conversions failed: for each failed conversion, the log has been written in destination folder(s).", [self.processedQueue count], [self.failedQueue count]];
        }
        NSBeginAlertSheet(@"Conversion Complete", @"Ok", nil, nil, [self window], self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, NULL, message, [self.processedQueue count]);
        return;
    }
    
    // Reset ETA
    [self.currentETA setStringValue:@"--:--:--"];
    
    [self.processingLabel setStringValue:[NSString stringWithFormat:@"Processing %ld / %ld", ++currentFile, totalFiles]];
    
    // Process next file
    [self prepareTask];
    [self.backgroundTask launch];
}

- (void)getData:(NSNotification *)aNotification {
    NSData *data = [aNotification userInfo][NSFileHandleNotificationDataItem];
    
    if ([data length]) {
        NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        // Searching percentage of progress
        if ([message rangeOfString:@"Encoding: task"].location != NSNotFound) {
            // The output format is in this form: "Encoding: task N of N, (x)x.xx%
            unsigned long location = [message rangeOfString:@", "].location;
            NSString *percentString = [message substringWithRange:NSMakeRange(location + 2, 5)];
            double percent = [percentString floatValue];
            double overallPercent = percent + ([self.processedQueue count]+[self.failedQueue count])*100.0;
            
            // Simple filter
            if (overallPercent > [self.overallProgressBar doubleValue]) {
                [self.taskProgressBar setDoubleValue:percent];
                [self.overallProgressBar setDoubleValue:overallPercent];
            }
        }
        
        // Checking if there is an ETA
        unsigned long etaLocation = [message rangeOfString:@"ETA "].location;
        if ( etaLocation != NSNotFound ) {
            int hours = [[message substringWithRange:NSMakeRange(etaLocation+4, 2)] intValue];
            int minutes = [[message substringWithRange:NSMakeRange(etaLocation+7, 2)] intValue];
            int seconds = [[message substringWithRange:NSMakeRange(etaLocation+10, 2)] intValue];
            [self.currentETA setStringValue:[NSString stringWithFormat:@"%0.2d:%0.2d:%0.2d", hours, minutes, seconds]];
        }
    }
    
    // we need to schedule the file handle go read more data in the background again.
    if ([self.backgroundTask isRunning]) {
        [[aNotification object] readInBackgroundAndNotify];
	}
}

- (void)storestdErrorString:(NSNotification *)aNotification {
    NSData *data = [aNotification userInfo][NSFileHandleNotificationDataItem];
    if ([data length]) {
        NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [stdErrorString appendString:message];
    }
    
    // we need to schedule the file handle go read more data in the background again.
    if ([self.backgroundTask isRunning]) {
        [[aNotification object] readInBackgroundAndNotify];
	}
}

// Called when the alert sheet is dismissed
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if ([(NSString *)contextInfo isEqual:@"Warning"]) {
        if (returnCode == NSAlertDefaultReturn) {
            [self startConversion];
            return;
        }
    }
        
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:@[self.processedQueue, self.currentQueue]
                                                         forKeys:@[PROCESSED_QUEUE_KEY, CURRENT_QUEUE_KEY]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:COMPLETE_NOTIFICATION object:self userInfo:userInfo];
    [self close];
}

@end
