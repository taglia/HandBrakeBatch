//
//  HBBProgressController.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import "HBBProgressController.h"

#define EMPTY_QUEUE FALSE
#define NON_EMPTY_QUEUE TRUE

@implementation HBBProgressController

@synthesize queue;

- (id) init {
    self = [super initWithWindowNibName:@"HBBProgressWindow"];

    processedQueue = [[NSMutableArray alloc] init];
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

- (IBAction) cancelButton:(id)sender {
    cancel = TRUE;
    [backgroundTask terminate];
    [progressWheel stopAnimation:self];
    
    NSBeginAlertSheet(@"Operation canceled", @"Ok", NULL, NULL, [self window], self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, NULL, @"%d files have been converted, %d remaining.", [processedQueue count], [currentQueue count]);
}

-(BOOL) prepareTask {
    if (currentQueue == nil || [currentQueue count] == 0) {
        [[self window] orderOut:nil];
        return EMPTY_QUEUE;
    }
    
    // Initialize NSTask
    backgroundTask = [[NSTask alloc] init];
    [backgroundTask setStandardOutput: [NSPipe pipe]];
    [backgroundTask setStandardError: [backgroundTask standardOutput]];
    [backgroundTask setLaunchPath: handBrakeCLI];
    
    // Build HandBrakeCLI arguments
    NSArray *presets = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"HandBrakePresets"];
    NSInteger selectedPreset = [[[NSUserDefaults standardUserDefaults] objectForKey:@"HBPreset"] intValue];
    NSString *preset = [presets objectAtIndex:selectedPreset];
    NSString *outputFolder = [[NSUserDefaults standardUserDefaults] objectForKey:@"OutputFolder"];
    
    NSString *inputFilePath = [[currentQueue objectAtIndex:0] path];
    
    NSString *outputFilePath = [outputFolder stringByAppendingPathComponent:[[[inputFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"m4v"] lastPathComponent]];
    
    NSArray *arguments = [NSArray arrayWithObjects:@"--preset", preset, @"-i", inputFilePath, @"-o", outputFilePath, nil];
    
    [backgroundTask setArguments: arguments];
    
    // Set Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(getData:) 
                                                 name: NSFileHandleReadCompletionNotification 
                                               object: [[backgroundTask standardOutput] fileHandleForReading]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(taskCompleted:) 
                                                 name: NSTaskDidTerminateNotification
                                               object: nil];
    
    // We tell the file handle to go ahead and read in the background asynchronously, and notify
    // us via the callback registered above when we signed up as an observer.  The file handle will
    // send a NSFileHandleReadCompletionNotification when it has data that is available.
    [[[backgroundTask standardOutput] fileHandleForReading] readInBackgroundAndNotify];
    
    return NON_EMPTY_QUEUE;
}

- (void)processQueue {
    cancel = FALSE;
    
    // Initialize queue mutable copy
    currentQueue = [queue mutableCopy];
    
    // Check if we have a valid queue
    if (currentQueue == nil || [currentQueue count] == 0) {
        [[self window] orderOut:nil];
        return;
    }
    
    // Set appropriate HandBrakeCLI binary
    if ([[NSRunningApplication currentApplication] executableArchitecture] == NSBundleExecutableArchitectureX86_64) {
        handBrakeCLI = [[NSBundle mainBundle] pathForResource:@"HandBrakeCLI_32" ofType:@""];
    } else {
        handBrakeCLI = [[NSBundle mainBundle] pathForResource:@"HandBrakeCLI_32" ofType:@""];
    }
    
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
    
    [self prepareTask];
    
    //Set file name
    [messageField setStringValue:[[currentQueue objectAtIndex:0] name]];
    
    [backgroundTask launch];
}

#pragma mark Notification methods

-(void) taskCompleted:(NSNotification *)notification {
    if (cancel)
        return;
    // Remove processed file from the queue
    NSLog (@"File conversion completed");
    [processedQueue addObject:[currentQueue objectAtIndex:0]];
    [currentQueue removeObjectAtIndex:0];
    
    // Process next file (if any)
    if ([self prepareTask] == NON_EMPTY_QUEUE) {
        [backgroundTask launch];
    } else {
        [progressWheel stopAnimation:self];
        NSBeginAlertSheet(@"Conversion Complete", @"Ok", NULL, NULL, [self window], self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, NULL, @"%d files have been converted.", [processedQueue count]);
        }
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
            [taskProgressBar setDoubleValue:percent];
            [overallProgressBar setDoubleValue:overallPercent];
        }
    }
    
    // we need to schedule the file handle go read more data in the background again.
    [[aNotification object] readInBackgroundAndNotify];
}

// Called when the alert sheet is dismissed
-(void) sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:processedQueue, currentQueue, nil]
                                                         forKeys:[NSArray arrayWithObjects:PROCESSED_QUEUE_KEY, CURRENT_QUEUE_KEY, nil]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:COMPLETE_NOTIFICATION object:self userInfo:userInfo];
    [self close];
}

@end
