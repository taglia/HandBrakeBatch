//
//  HBBProgressController.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import <Cocoa/Cocoa.h>
#import "HBBInputFile.h"

#define COMPLETE_NOTIFICATION @"HBBConversionCompleted"
#define PROCESSED_QUEUE_KEY @"HBBProcessedQueue"
#define CURRENT_QUEUE_KEY @"HBBCurrentQueue"

@interface HBBProgressController : NSWindowController {
@private
    NSArray *queue;
    // Items remaining in the queue, to be processed
    NSMutableArray *currentQueue;
    
    // Processed items
    NSMutableArray *processedQueue;
    
    NSTask *backgroundTask;

    NSString *handBrakeCLI;
    
    IBOutlet NSProgressIndicator *taskProgressBar;
    IBOutlet NSProgressIndicator *overallProgressBar;
    IBOutlet NSProgressIndicator *progressWheel;
    IBOutlet NSTextField *messageField;
    
    IBOutlet NSTextField *currentETA;
    IBOutlet NSTextField *overallETA;
    IBOutlet NSTextField *elapsed;
    
    BOOL cancel;
    
    // Start times
    NSDate *overallStartDate;
    NSDate *currentStartDate;
    NSInteger totalSize;
    NSInteger remainingSize;
    
    NSTimer *timer;
    
    // Common parameters
    NSDictionary *presets;
    NSString *selectedPresetName;
    NSString *preset;
    NSString *fileExtension;
    NSMutableArray *arguments;
    NSString *outputFolder;
}

@property (assign) NSArray *queue;

- (IBAction) cancelButton:(id)sender;
- (void) processQueue;

@end
