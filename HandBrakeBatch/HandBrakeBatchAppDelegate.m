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
#import "HBBDropView.h"

@implementation HandBrakeBatchAppDelegate

@synthesize window, inputFiles;


#pragma mark Initialization

static NSString *PREF_SEND_FILE_TO_APP_PATH		= @"HBBSendConvertedFileToAppPath";
static NSString *PREF_SEND_FILE_TO_APP_NAME		= @"HBBSendConvertedFileToAppName";


- (id) init {
	
    // Initialize application directory
	NSFileManager *fm = [NSFileManager defaultManager];
	appSupportFolder = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)
                         objectAtIndex:0] stringByAppendingPathComponent:@"HandBrakeBatch"];
	
	if ( ![fm fileExistsAtPath:appSupportFolder] ) {
		[fm createDirectoryAtPath:[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)
                                    objectAtIndex:0] stringByAppendingPathComponent:@"HandBrakeBatch"]
      withIntermediateDirectories:NO attributes:nil error:NULL];
    }
    
    // Load queue
    if ([[NSFileManager defaultManager] fileExistsAtPath:[appSupportFolder stringByAppendingPathComponent:@"SavedQueue.data"]]) {
        NSLog(@"Loading queue…");
        inputFiles = [NSKeyedUnarchiver unarchiveObjectWithFile:[appSupportFolder stringByAppendingPathComponent:@"SavedQueue.data"]];
    } else {
        inputFiles = [[NSMutableArray alloc] init];
    }
    
    self = [super init];
    
    // Subscribe to the Progress Window Notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(conversionCompleted:) name:COMPLETE_NOTIFICATION object:nil];
    
    // Initialize sorted preset names
    presets = [[[[HBBPresets hbbPresets] presets] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    // Store first launch date in the preferences
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"HBBFirstLaunchDate"] == nil)
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"HBBFirstLaunchDate"];
    
    return self;
}

- (NSDictionary *)registrationDictionaryForGrowl {
    return [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Growl Registration Ticket" ofType:@"growlRegDict"]];
}

- (void)awakeFromNib {
    // Workaround for Growl bug (need a delegate defined)
    [GrowlApplicationBridge setGrowlDelegate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [dropView setAppDelegate:self];
    [dropView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    NSString *selectedPreset = [[NSUserDefaults standardUserDefaults] objectForKey:@"PresetName"];
    [presetPopUp selectItemWithTitle:selectedPreset];
    
    // Donation Nag window (every 2 days)
    if ( ![[NSUserDefaults standardUserDefaults] boolForKey:@"HBBNoDonation"] ) {
        NSDate *firstLaunchDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"HBBFirstLaunchDate"];
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:firstLaunchDate];
        if ( (interval / 172800) > 10.0 ) {
            NSInteger choice = NSRunInformationalAlertPanel(@"Donate!", @"HandBrakeBatch is Charitiware. I have selected some charities to which you can contribute, please consider this! The donation process is managed securely by JustGiving, and you can remain completely anonymous to OSOMac. Thank you in advance!", @"Ok", @"No", @"Later");
            switch (choice) {
                case NSAlertDefaultReturn:
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://donate.osomac.com/apps/2"]];
                    [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"HBBNoDonation"];
                    break;
					
                case NSAlertAlternateReturn:
                    [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"HBBNoDonation"];
                    break;
					
                default:
                    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"NSFirstLaunchDate"];
                    break;
            }
        }
    }
    
    // Add observer for arrangedObjects
    [fileNamesController addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionNew context:nil];
	
	// Set up send file to checkbox
	[self redrawSendFileToCheckbox];
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
    [panel setCanCreateDirectories:YES];
    NSString *outputFolder = [[NSUserDefaults standardUserDefaults] objectForKey:@"OutputFolder"];
    
    BOOL outputFolderExists = false;
    if (outputFolder) {
        BOOL isDir;
        outputFolderExists = [[NSFileManager defaultManager] fileExistsAtPath:outputFolder isDirectory:&isDir];
        outputFolderExists &= isDir;
    }
    
    if (outputFolderExists)
        [panel setDirectoryURL:[NSURL fileURLWithPath:outputFolder]];
	
    
    if ([panel runModal] == NSOKButton) {
        NSString *path = [[panel directoryURL] path];
        [[NSUserDefaults standardUserDefaults] setValue:path forKey:@"OutputFolder"];
    }
}

- (IBAction)startConversion:(id)sender {
    // Warn the user if there are no files to convert
    if ([inputFiles count] == 0) {
        NSBeginAlertSheet(@"No files to convert", @"Ok", nil, nil, [self window], nil, NULL, NULL, NULL, @"Please drag some files in the table.");
        return;
    }
    
    // Warn the user if the output folder is not set
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"OutputFolder"] length] == 0 && ![[NSUserDefaults standardUserDefaults] objectForKey:@"HBBDestinationSameAsSource"]) {
        NSBeginAlertSheet(@"No output folder", @"Ok", nil, nil, [self window], nil, NULL, NULL, NULL, @"Please select an output folder.");
        return;
    }
    
    progressController = [[HBBProgressController alloc] init];
    
    [progressController loadWindow];
    
    [[self window] orderOut:nil];
    
    [progressController setQueue:[fileNamesController arrangedObjects]];
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

#pragma mark Managing supported files

-(BOOL) application:(NSApplication *)sender openFile:(NSString *)filename {
    NSURL *completeFileName = [NSURL fileURLWithPath:filename];
    [self processFiles:completeFileName];
    return TRUE;
}

// Check if the movie is already present in the queue
-(BOOL) isDuplicate:(HBBInputFile *)file {
    NSArray *files = [fileNamesController arrangedObjects];
    
    for (HBBInputFile *f in files) {
        if ([[f inputPath] isEqualToString:[file inputPath]])
            return true;
    }
    return false;
}




// --++--   --++--   --++--   --++--   --++--   --++--
#pragma mark -
#pragma mark SEND FILE TO WORK
#pragma mark -

- (void) redrawSendFileToCheckbox {
	if ([self isSendToAppValid]) {
		[sendFileToCheckbox setState:NSOnState];
	}
	
	else {
		[self clearAllSendToAppPreferences];
		[sendFileToCheckbox setState:NSOffState];
	}
}
- (void) logAllSendToAppPrefs {
	NSLog(@"--- [ SEND TO APP PREFERENCES ] ---");
	NSLog(@"PREF_SEND_FILE_TO_APP_PATH %@", [[NSUserDefaults standardUserDefaults] stringForKey:PREF_SEND_FILE_TO_APP_PATH]);
	NSLog(@"PREF_SEND_FILE_TO_APP_NAME %@", [[NSUserDefaults standardUserDefaults] stringForKey:PREF_SEND_FILE_TO_APP_NAME]);
}

// Select app to send file to when finished
- (IBAction)chooseSendToApplication:(id)sender {
	
	// OPEN APP SELECTION PANEL
	NSOpenPanel *panel	= [NSOpenPanel openPanel];
    
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanCreateDirectories:NO];
	
    NSString *appPath	= [[NSUserDefaults standardUserDefaults] objectForKey:PREF_SEND_FILE_TO_APP_PATH];
	
	// POINT THE SELECTION PANEL TO OUR OLD LOCATION
    if ([self isSendToAppValid]) {
        [panel setDirectoryURL:[NSURL fileURLWithPath:appPath]];
	}
	
	// NEW FILE SELECTED -- save it
    if ([panel runModal] == NSOKButton) {
        NSURL *firstPath		= [[panel URLs] objectAtIndex:0];
		
		// SAVE PATH
		NSString *filePath		= [[firstPath absoluteString] stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""];
		[[NSUserDefaults standardUserDefaults] setObject:filePath forKey:PREF_SEND_FILE_TO_APP_PATH];
		
		// SAVE APP NAME
		NSString *appName		= [[firstPath lastPathComponent] stringByReplacingOccurrencesOfString: @".app" withString:@""];
		
		[[NSUserDefaults standardUserDefaults] setValue:appName forKey:PREF_SEND_FILE_TO_APP_NAME];
		
		// MAKE SURE SETTINGS ARE SAVED
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		// Set up send file to checkbox
		[self redrawSendFileToCheckbox];
    }
}

- (IBAction)sendToApplicationClicked:(id)sender {
	NSButtonCell *checkbox	= (NSButtonCell *)sender;
	if (checkbox) {
		[checkbox setState:NSOffState];
	}
	
	BOOL hadPreviousValue	= [self isSendToAppValid];
	
	// no matter what we will remove pervious values, then
	// call what is needed here
	[self clearAllSendToAppPreferences];
	
	// TRYING TO ENABLE
	// call "chooseSendToApplication:"
	if ( ! hadPreviousValue ) {
		[self chooseSendToApplication:nil];
	}
	
}
- (BOOL) isSendToAppValid {
	NSString *appPath	= [[NSUserDefaults standardUserDefaults] stringForKey:PREF_SEND_FILE_TO_APP_PATH];
	
	if ( ! appPath) {
		return NO;
	}
	
	NSURL *theURL		= [NSURL fileURLWithPath:appPath isDirectory:NO];
	return ([theURL checkResourceIsReachableAndReturnError:nil] == YES);
}
- (void) clearAllSendToAppPreferences {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:PREF_SEND_FILE_TO_APP_NAME];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:PREF_SEND_FILE_TO_APP_PATH];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


// Recursively process files & directories
-(void)processFiles:(NSURL *)url {
    NSArray *videoExtensions = [NSArray arrayWithObjects:@"3g2", @"3gp", @"asf", @"asx", @"avi", @"flv", @"mov", @"mp4", @"mpg", @"rm", @"srt", @"swf", @"vob", @"wmv", @"264", @"3gpp2", @"3mm", @"60d", @"aet", @"avd", @"avs", @"bdt2", @"bnp", @"box", @"bs4", @"byu", @"camv", @"dav", @"ddat", @"dif", @"dlx", @"dmsm3d", @"dnc", @"dv4", @"fbr", @"flx", @"gvp", @"h264", @"irf", @"iva", @"k3g", @"lrec", @"lsx", @"m1v", @"m2a", @"m4u", @"meta", @"mjpg", @"modd", @"moff", @"moov", @"movie", @"mp2v", @"mp4v", @"mpe", @"mpsub", @"mvc", @"mvex", @"mys", @"osp", @"par", @"playlist", @"pns", @"pssd", @"pva", @"pvr", @"qt", @"qtch", @"qtm", @"rp", @"rts", @"sbt", @"scn", @"sfd", @"sml", @"smv", @"spl", @"str", @"vcr", @"vem", @"vft", @"vfw", @"vid", @"video", @"vs4", @"vse", @"w32", @"wm", @"wot", @"787", @"am", @"anim", @"bix", @"cel", @"cvc", @"dsy", @"gl", @"grasp", @"gvi", @"ivs", @"lsf", @"m15", @"m4e", @"m75", @"mmv", @"mob", @"mpeg4", @"mpf", @"mpg2", @"mpv2", @"msh", @"mvb", @"pmv", @"rmd", @"rts", @"scm", @"sec", @"ssm", @"tdx", @"vdx", @"viv", @"vivo", @"vp3", @"aepx", @"ale", @"avp", @"avs", @"bdm", @"bik", @"bin", @"bsf", @"camproj", @"cpi", @"dat", @"divx", @"dmsm", @"dream", @"dvdmedia", @"dvr-ms", @"dzm", @"dzp", @"edl", @"f4v", @"fbr", @"fcproject", @"hdmov", @"imovieproj", @"ism", @"ismv", @"m2p", @"m4v", @"mkv", @"mod", @"moi", @"mpeg", @"mts", @"mxf", @"ogv", @"pds", @"prproj", @"psh", @"r3d", @"rcproject", @"rmvb", @"scm", @"smil", @"sqz", @"stx", @"swi", @"tix", @"trp", @"ts", @"veg", @"vf", @"vro", @"webm", @"wlmp", @"wtv", @"xvid", @"yuv", @"3gp2", @"3gpp", @"3p2", @"aaf", @"aep", @"aetx", @"ajp", @"amc", @"amv", @"amx", @"arcut", @"arf", @"avb", @"axm", @"bdmv", @"bdt3", @"bmk", @"camrec", @"cine", @"clpi", @"cmmp", @"cmmtpl", @"cmproj", @"cmrec", @"cst", @"d2v", @"d3v", @"dce", @"dck", @"dcr", @"dcr", @"dir", @"dmb", @"dmsd", @"dmsd3d", @"dmss", @"dpa", @"dpg", @"dv", @"dv-avi", @"dvr", @"dvx", @"dxr", @"dzt", @"evo", @"eye", @"f4p", @"fbz", @"fcp", @"flc", @"flh", @"fli", @"gfp", @"gts", @"hkm", @"ifo", @"imovieproject", @"ircp", @"ismc", @"ivf", @"ivr", @"izz", @"izzy", @"jts", @"jtv", @"m1pg", @"m21", @"m21", @"m2t", @"m2ts", @"m2v", @"mgv", @"mj2", @"mjp", @"mk3d", @"mnv", @"mp21", @"mp21", @"mpgindex", @"mpl", @"mpls", @"mpv", @"mqv", @"msdvd", @"mse", @"mswmm", @"mtv", @"mvd", @"mve", @"mvp", @"mvp", @"mvy", @"ncor", @"nsv", @"nuv", @"nvc", @"ogm", @"ogx", @"pgi", @"photoshow", @"piv", @"plproj", @"pmf", @"ppj", @"prel", @"pro", @"prtl", @"pxv", @"qtl", @"qtz", @"rcd", @"rdb", @"rec", @"rmd", @"rmp", @"rms", @"roq", @"rsx", @"rum", @"rv", @"rvl", @"sbk", @"scc", @"screenflow", @"seq", @"sfvidcap", @"siv", @"smi", @"smk", @"stl", @"svi", @"swt", @"tda3mt", @"tivo", @"tod", @"tp", @"tp0", @"tpd", @"tpr", @"tsp", @"tvs", @"usm", @"vc1", @"vcpf", @"vcv", @"vdo", @"vdr", @"vep", @"vfz", @"vgz", @"viewlet", @"vlab", @"vp6", @"vp7", @"vpj", @"vsp", @"wcp", @"wmd", @"wmmp", @"wmx", @"wp3", @"wpl", @"wvx", @"xej", @"xel", @"xesc", @"xfl", @"xlmv", @"zm1", @"zm2", @"zm3", @"zmv", @"iso", nil];
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:nil];
    NSString *fileType = [fileAttributes objectForKey:NSFileType];
    
    if ([fileType isEqualToString:NSFileTypeDirectory]) {
        if ([[[url path] lastPathComponent] isEqualToString:@"VIDEO_TS"]) {
            // Getting the name of the enclosing folder
            NSURL *enclosingFolderURL = [NSURL fileURLWithPath:[[url path] stringByDeletingLastPathComponent]];
            
            HBBInputFile *input = [[HBBInputFile alloc] initWithURL:enclosingFolderURL];
            if ([self isDuplicate:input])
                return;
            
            [fileNamesController performSelectorOnMainThread:@selector(addObject:) withObject:input waitUntilDone:YES ];
            [leftPaneView setNeedsDisplay:YES];
            [leftPaneView display];
        } else {
            NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants;
            NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtURL:url includingPropertiesForKeys:nil options:options errorHandler:nil];
            NSURL *itemURL;
            while (itemURL = [dirEnum nextObject])
                [self processFiles:itemURL];
        }
    } else if ([fileType isEqualToString:NSFileTypeRegular] && [videoExtensions containsObject:[[[url path] pathExtension] lowercaseString]]) {
        HBBInputFile *input = [[HBBInputFile alloc] initWithURL:url];
        if ([self isDuplicate:input])
            return;
        
        [fileNamesController performSelectorOnMainThread:@selector(addObject:) withObject:input waitUntilDone:YES ];
        [leftPaneView setNeedsDisplay:YES];
        [leftPaneView display];
    }
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

#pragma mark Other
-(void) conversionCompleted:(NSNotification *)notification {
    [[self window] makeKeyAndOrderFront:nil];
    NSArray *processed = [[notification userInfo] objectForKey:PROCESSED_QUEUE_KEY];
    
    [fileNamesController removeObjects:processed];
}

///////////////////////////////////////
//                                   //
// Preference Windows                //
//                                   //
///////////////////////////////////////

- (IBAction)showPreferences:(id)sender
{
    if (!preferencesController)
        preferencesController = [[HBBPreferencesController alloc] init];
    [preferencesController showWindow:self];
}

- (IBAction)donate:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://donate.osomac.com/apps/2"]];
}

///////////////////////////////////////
//                                   //
// Observing inputFiles controller   //
//                                   //
///////////////////////////////////////

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [NSKeyedArchiver archiveRootObject:[object arrangedObjects] toFile:[appSupportFolder stringByAppendingPathComponent:@"SavedQueue.data"]];
}

@end