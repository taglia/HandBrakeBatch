//
//  HandBrakeBatchAppDelegate.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 28/04/2011.
//  Copyright 2011 Cesare Tagliaferri. All rights reserved.
//

#import "HandBrakeBatchAppDelegate.h"
#import "HBBInputFile.h"

@implementation HandBrakeBatchAppDelegate

@synthesize window, inputFiles;

#pragma mark Initialization

- (id) init {
    presets = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"HandBrakePresets"];
    inputFiles = [[NSMutableArray alloc] init];
    
    self = [super init];
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [fileNamesView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [fileNamesView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
}

#pragma mark Button Actions

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
        [[NSAlert alertWithMessageText:@"No files to convert" defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please drag some files in the table."] runModal];
        return;
    }
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

@end