//
//  HBBPreferencesController.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 30/07/2011.
//  Copyright 2011 Cesare Tagliaferri. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HBBPreferencesController : NSWindowController {

    IBOutlet NSButton * maintainTimestamps;
    IBOutlet NSPopUpButton *mpeg4Extension;

}

@end
