//
//  HBBPreferencesController.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 30/07/2011.
//  Copyright 2011 Cesare Tagliaferri. All rights reserved.
//

#import "HBBPreferencesController.h"

@implementation HBBPreferencesController

- (id)init
{
	self = [super initWithWindowNibName:@"Preferences"];
	return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
