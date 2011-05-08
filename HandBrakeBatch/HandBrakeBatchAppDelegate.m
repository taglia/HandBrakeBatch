//
//  HandBrakeBatchAppDelegate.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import "HandBrakeBatchAppDelegate.h"
#import "HBBInputFile.h"
#import "HBBProgressController.h"
#import "HBBPresets.h"

@implementation HandBrakeBatchAppDelegate

@synthesize window, inputFiles;

#pragma mark Initialization

- (id) init {
    //presets = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"HandBrakePresets"];
    inputFiles = [[NSMutableArray alloc] init];
    
    self = [super init];
    
    // Subscribe to the Progress Window Notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(conversionCompleted:) name:COMPLETE_NOTIFICATION object:nil];
    
    // Initialize preset names
    presets = [[[HBBPresets hbbPresets] presets] allKeys];
    
    return self;
}

- (void)awakeFromNib {

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [fileNamesView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [fileNamesView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
    
    NSString *selectedPreset = [[NSUserDefaults standardUserDefaults] objectForKey:@"PresetName"];
    [presetPopUp selectItemWithTitle:selectedPreset];
}

- (void)windowWillClose:(NSNotification *)notification {
    [NSApp terminate:nil];
}

#pragma mark Button & Menu Actions

///////////////////////////////////////
//                                   //
// Linked to the window buttons      //
//                                   //
///////////////////////////////////////

- (IBAction)chooseOutputFolder:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO];
    
    [panel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:@"OutputFolder"] file:nil];
    
    NSString *path = [[panel directoryURL] path];
    
    [[NSUserDefaults standardUserDefaults] setValue:path forKey:@"OutputFolder"];
}

- (IBAction)startConversion:(id)sender {
    // Warn the user if there are no files to convert
    if ([inputFiles count] == 0) {
        NSBeginAlertSheet(@"No files to convert", @"Ok", NULL, NULL, [self window], NULL, NULL, NULL, NULL, @"Please drag some files in the table.");
        return;
    }
    
    // Warn the user if the output folder is not set
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"OutputFolder"] length] == 0) {
        NSBeginAlertSheet(@"No output folder", @"Ok", NULL, NULL, [self window], NULL, NULL, NULL, NULL, @"Please select an output folder.");
        return;
    }
    
    progressController = [[HBBProgressController alloc] init];
    
    [progressController loadWindow];
    
    [[self window] orderOut:nil];
    
    [progressController setQueue:inputFiles];
    [progressController processQueue];
}

- (IBAction)displayLicense:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"gpl-3.0" ofType:@"txt"]];
}

- (IBAction)presetSelected:(id)sender {
    NSPopUpButton *control = sender;
    
    NSString *selectedPreset = [[control selectedItem] title];
    [[NSUserDefaults standardUserDefaults] setObject:selectedPreset forKey:@"PresetName"];
}

#pragma mark Drag & Drop

///////////////////////////////////////
//                                   //
// Most basic implementation of D&D  //
//                                   //
///////////////////////////////////////

// Validate Drop
- (NSDragOperation)tableView:(NSTableView*)pTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
    return NSDragOperationEvery;
}

// Accept Drop
- (BOOL)tableView:(NSTableView *)pTableView 
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)pRow 
	dropOperation:(NSTableViewDropOperation)operation
{
	if (pRow < 0) pRow = 0;
    
    NSPasteboard* pboard = [info draggingPasteboard];
	
	NSArray* draggedItems = [pboard propertyListForType:NSFilenamesPboardType];
    
	for (NSString *item in draggedItems) {
		NSURL *completeFileName = [NSURL fileURLWithPath:item];
        HBBInputFile *file = [[HBBInputFile alloc] initWithURL:completeFileName];
		[fileNamesController insertObject:file atArrangedObjectIndex:pRow];
	}
	
	return YES;
}

#pragma mark NSSplitViewDelegate methods

///////////////////////////////////////
//                                   //
// Limit the size of the split views //
//                                   //
///////////////////////////////////////
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
    return 250.0;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex {
    NSRect frame = [[self window] frame];
    return frame.size.width - 250.0;
}

#pragma mark Notifications
-(void) conversionCompleted:(NSNotification *)notification {
    [[self window] makeKeyAndOrderFront:nil];
    NSArray *processed = [[notification userInfo] objectForKey:PROCESSED_QUEUE_KEY];
    
    [fileNamesController removeObjects:processed];
}

@end