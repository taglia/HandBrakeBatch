//
//  HBBInputController.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 28/04/2011.
//  Copyright 2011 Murex SEA. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HBBInputController : NSWindowController {
@private
    
    IBOutlet NSArray *presets;
    
}

- (IBAction)chooseOutputFolder:(id)sender;
- (IBAction)startConversion:(id)sender;

@end
