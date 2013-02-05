//
//  HBBDropView.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 24/06/2012.
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import "HBBDropView.h"

@interface HBBDropView ()

@property (readwrite, weak, nonatomic) IBOutlet RSRTVArrayController *fileNamesController;
@property (readwrite, weak, nonatomic) IBOutlet NSButton *startButton;
@property (readwrite, weak, nonatomic) IBOutlet NSProgressIndicator *progressIndicator;
@property (readwrite, weak, nonatomic) IBOutlet HBBAppDelegate *appDelegate;

@property (readwrite, assign, nonatomic) BOOL drawFocusRing;
@property (readwrite, assign, nonatomic) BOOL dropping;

@end

@implementation HBBDropView

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];

	if (self) {
		// Initialization code here.
	}

	return self;
}

- (void)drawRect:(NSRect)rect {
	[super drawRect:rect];

	if (self.drawFocusRing) {
		[NSGraphicsContext saveGraphicsState];

		[[NSColor blueColor] set];

		NSSetFocusRingStyle(NSFocusRingBelow);
		[[NSBezierPath bezierPathWithRect:[self bounds]] fill];

		[NSGraphicsContext restoreGraphicsState];
	}
}


///////////////////////////////////////
//                                   //
// Most basic implementation of D&D  //
//                                   //
///////////////////////////////////////

// Validate Drop
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	if (self.dropping) {
		return NSDragOperationNone;
	}

	self.drawFocusRing = YES;
	[self display];
	return NSDragOperationEvery;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	self.drawFocusRing = NO;
	[self display];
}

// Accept Drop
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	self.drawFocusRing = NO;
	[self display];
	NSPasteboard *pboard;
	NSDragOperation sourceDragMask;

	sourceDragMask = [sender draggingSourceOperationMask];
	pboard = [sender draggingPasteboard];

	NSArray *draggedItems = [pboard propertyListForType:NSFilenamesPboardType];

	[NSThread detachNewThreadSelector:@selector(processDraggedItems:) toTarget:self withObject:draggedItems];

	return YES;
}

- (void)processDraggedItems:(NSArray *)items {
	self.dropping = YES;
	[self.startButton setEnabled:NO];
	[self.startButton setTitle:@"Processing…"];
	[self.progressIndicator setHidden:NO];
	[self.progressIndicator startAnimation:self];

	for (NSString *item in items) {
		NSURL *completeFileName = [NSURL fileURLWithPath:item];
		[self.appDelegate processFiles:completeFileName];
	}

	[self.startButton setEnabled:YES];
	[self.startButton setTitle:@"Start"];
	[self.progressIndicator setHidden:YES];
	[self.progressIndicator stopAnimation:self];
	self.dropping = NO;
}

@end
