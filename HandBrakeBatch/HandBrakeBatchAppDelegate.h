//
//  HandBrakeBatchAppDelegate.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 28/04/2011.
//  Copyright 2011 Cesare Tagliaferri. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HandBrakeBatchAppDelegate : NSObject <NSApplicationDelegate, NSSplitViewDelegate> {
@private
    NSWindow *window;
    
    IBOutlet NSArray *presets;
    
    NSMutableArray *inputFiles;
    IBOutlet NSTableView *fileNamesView;
    IBOutlet NSArrayController *fileNamesController;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) NSMutableArray *inputFiles;

- (IBAction)chooseOutputFolder:(id)sender;
- (IBAction)startConversion:(id)sender;

@end
