//
//  HandBrakeBatchAppDelegate.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 28/04/2011.
//  Copyright 2011 Murex SEA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HBBInputController.h"

@interface HandBrakeBatchAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
    
    IBOutlet HBBInputController *inputController;
}

@property (assign) IBOutlet NSWindow *window;

@end
