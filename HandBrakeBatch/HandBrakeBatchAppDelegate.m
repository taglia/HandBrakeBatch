//
//  HandBrakeBatchAppDelegate.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 28/04/2011.
//  Copyright 2011 Murex SEA. All rights reserved.
//

#import "HandBrakeBatchAppDelegate.h"

@implementation HandBrakeBatchAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    presets = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"HandBrakePresets"];
}

@end
