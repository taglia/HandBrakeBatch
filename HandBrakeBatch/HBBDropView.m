//
//  HBBMainView.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 24/06/2012.
//  Copyright (c) 2012 Murex SEA. All rights reserved.
//

#import "HBBDropView.h"

@implementation HBBDropView

@synthesize appDelegate;

static bool drawFocusRing = NO;
static bool dropping = NO;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];
    
    if (drawFocusRing) {
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
    if (dropping)
        return NSDragOperationNone;
    
    drawFocusRing = YES;
    [self display];
    return NSDragOperationEvery;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    drawFocusRing = NO;
    [self display];
}

// Accept Drop
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    drawFocusRing = NO;
    [self display];
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    NSArray* draggedItems = [pboard propertyListForType:NSFilenamesPboardType];
    
    [[NSGarbageCollector defaultCollector] disable];
    [NSThread detachNewThreadSelector:@selector(processDraggedItems:) toTarget:self withObject:draggedItems];
    [[NSGarbageCollector defaultCollector] enable];
	
	return YES;
}

- (void) processDraggedItems:(NSArray *)items {
    dropping = YES;
    [startButton setEnabled:NO];
    [startButton setTitle:@"Processing…"];
    [progressIndicator setHidden:NO];
    [progressIndicator startAnimation:self];
    for (NSString *item in items) {
        NSURL *completeFileName = [NSURL fileURLWithPath:item];
    
        [appDelegate processFiles:completeFileName];
    }
    [startButton setEnabled:YES];
    [startButton setTitle:@"Start"];
    [progressIndicator setHidden:YES];
    [progressIndicator stopAnimation:self];
    dropping=NO;
}

@end
