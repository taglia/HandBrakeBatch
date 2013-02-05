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

@interface HBBAppDelegate : NSObject <NSApplicationDelegate, NSSplitViewDelegate, NSWindowDelegate, GrowlApplicationBridgeDelegate>

@property (readonly, strong, nonatomic) NSMutableArray *inputFiles;
@property (readonly, strong, nonatomic) NSArray *presets;
@property (readonly, strong, nonatomic) HBBProgressController *progressController;
@property (readonly, strong, nonatomic) HBBPreferencesController *preferencesController;

- (IBAction)chooseOutputFolder:(id)sender;
- (IBAction)startConversion:(id)sender;
- (IBAction)displayLicense:(id)sender;
- (IBAction)presetSelected:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)donate:(id)sender;

- (void)processFiles:(NSURL *)url;

@end
