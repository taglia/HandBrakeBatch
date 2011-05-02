//
//  HandBrakeBatchAppDelegate.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import <Cocoa/Cocoa.h>
#import "HBBProgressController.h"

@interface HandBrakeBatchAppDelegate : NSObject <NSApplicationDelegate, NSSplitViewDelegate, NSWindowDelegate> {
@private
    NSWindow *window;
    
    IBOutlet NSArray *presets;
    
    NSMutableArray *inputFiles;
    IBOutlet NSTableView *fileNamesView;
    IBOutlet NSArrayController *fileNamesController;
    
    HBBProgressController *progressController;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) NSMutableArray *inputFiles;

- (IBAction)chooseOutputFolder:(id)sender;
- (IBAction)startConversion:(id)sender;
- (IBAction)displayLicense:(id)sender;

@end
