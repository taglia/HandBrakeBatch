//
//  HBBInputController.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 28/04/2011.
//  Copyright 2011 Murex SEA. All rights reserved.
//

#import "HBBInputController.h"


@implementation HBBInputController

- (id)init {
    self = [super initWithWindowNibName:@"HBBInput"];
    
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

- (void)dealloc
{
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    presets = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"HandBrakePresets"];
}

- (IBAction)chooseOutputFolder:(id)sender {
    
}

- (IBAction)startConversion:(id)sender {
    
}

@end
