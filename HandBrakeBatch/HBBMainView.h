//
//  HBBMainView.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 24/06/2012.
//  Copyright (c) 2012 Murex SEA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSRTVArrayController.h"
#import "HBBInputFile.h"
#import "HandBrakeBatchAppDelegate.h"

@interface HBBMainView : NSView {
    IBOutlet RSRTVArrayController *fileNamesController;
    IBOutlet NSButton *startButton;
    IBOutlet NSProgressIndicator *progressIndicator;
    
    HandBrakeBatchAppDelegate *appDelegate;
}

@property (assign) HandBrakeBatchAppDelegate *appDelegate;

@end
