//
//  HBBDropView.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 24/06/2012.
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import <Cocoa/Cocoa.h>
#import "RSRTVArrayController.h"
#import "HBBInputFile.h"
#import "HBBAppDelegate.h"

@interface HBBDropView : NSView {
    IBOutlet RSRTVArrayController *fileNamesController;
    IBOutlet NSButton *startButton;
    IBOutlet NSProgressIndicator *progressIndicator;
    
    HBBAppDelegate *appDelegate;
}

@property (assign) HBBAppDelegate *appDelegate;

@end
