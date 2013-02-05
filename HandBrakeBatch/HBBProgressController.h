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

@interface HBBProgressController : NSWindowController

@property (readwrite, strong, nonatomic) NSArray *queue;

// Items remaining in the queue, to be processed
@property (readonly, strong, nonatomic) NSMutableArray *currentQueue;

// Processed items
@property (readonly, strong, nonatomic) NSMutableArray *processedQueue;
@property (readonly, strong, nonatomic) NSMutableArray *failedQueue;

@property (readonly, strong, nonatomic) NSTask *backgroundTask;
@property (readonly, assign, nonatomic) BOOL suspended;

@property (readonly, strong, nonatomic) NSString *handBrakeCLI;

@property (readonly, assign, nonatomic) BOOL cancel;

// Start times
@property (readonly, strong, nonatomic) NSDate *overallStartDate;
@property (readonly, strong, nonatomic) NSDate *currentStartDate;

@property (readonly, strong, nonatomic) NSTimer *timer;

// Common parameters
@property (readonly, strong, nonatomic) NSDictionary *presets;
@property (readonly, strong, nonatomic) NSString *selectedPresetName;
@property (readonly, strong, nonatomic) NSString *preset;
@property (readonly, strong, nonatomic) NSString *fileExtension;
@property (readonly, strong, nonatomic) NSMutableArray *arguments;
@property (readonly, strong, nonatomic) NSString *outputFolder;

- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)pauseButtonAction:(id)sender;
- (void)processQueue;

@end
