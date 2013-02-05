//
//  HBBAppDelegate.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import "HBBProgressController.h"
#import "HBBPreferencesController.h"
#import "RSRTVArrayController.h"
@class HBBDropView;

@interface HBBAppDelegate : NSObject <NSApplicationDelegate, NSSplitViewDelegate, NSWindowDelegate, GrowlApplicationBridgeDelegate> {
@private
    NSWindow *window;
    
    NSMutableArray *inputFiles;
    IBOutlet NSTableView *fileNamesView;
    IBOutlet RSRTVArrayController *fileNamesController;
    
    NSArray *presets;
    IBOutlet NSArrayController *presetNamesController;
    IBOutlet NSPopUpButton *presetPopUp;
    
    IBOutlet HBBDropView *dropView;
    IBOutlet NSView *leftPaneView;
    
    HBBProgressController *progressController;
    HBBPreferencesController *preferencesController;
    
    IBOutlet NSButton *chooseOutputFolder;
    
    NSString *appSupportFolder;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) NSMutableArray *inputFiles;

- (IBAction)chooseOutputFolder:(id)sender;
- (IBAction)startConversion:(id)sender;
- (IBAction)displayLicense:(id)sender;
- (IBAction)presetSelected:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)donate:(id)sender;

- (void)processFiles:(NSURL *)url;

@end
