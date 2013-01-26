//
//  HBBAppFunctions.m
//  HandBrakeBatch
//
//  Created by Matt Maher on 1/26/13.
//
//

#import "HBBAppFunctions.h"

@implementation HBBAppFunctions






// --++--   --++--   --++--   --++--   --++--   --++--
#pragma mark -
#pragma mark SEND TO APP (after conversion)
#pragma mark -
static NSString *PREF_SEND_FILE_TO_APP_PATH		= @"HBBSendConvertedFileToAppPath";
static NSString *PREF_SEND_FILE_TO_APP_NAME		= @"HBBSendConvertedFileToAppName";
+ (NSString *) getSendToAppPath {
	return [[NSUserDefaults standardUserDefaults] objectForKey:PREF_SEND_FILE_TO_APP_PATH];
}
+ (void) setSendToAppPath:(NSString *)path {
	NSString *filePath		= [path stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""];
	filePath				= [filePath stringByReplacingPercentEscapesUsingEncoding:NSStringEncodingConversionAllowLossy];
	[[NSUserDefaults standardUserDefaults] setObject:filePath forKey:PREF_SEND_FILE_TO_APP_PATH];
}
+ (NSString *) getSendToAppName {
	return [[NSUserDefaults standardUserDefaults] valueForKey:PREF_SEND_FILE_TO_APP_NAME];
}
+ (void) setSendToAppName:(NSString *)name {
	NSString *appName		= [name stringByReplacingOccurrencesOfString: @".app" withString:@""];
	[[NSUserDefaults standardUserDefaults] setValue:appName forKey:PREF_SEND_FILE_TO_APP_NAME];
}
+ (NSImage *) getIconForSendToApp {
	if ([self isSendToAppValid]) {
		return [[NSWorkspace sharedWorkspace] iconForFile:[self getSendToAppPath]];
	}
	
	return nil;
}
+ (BOOL) isSendToAppValid {
	NSString *appPath	= [self getSendToAppPath];
	
	if ( ! appPath) {
		return NO;
	}
	
	NSURL *theURL		= [NSURL fileURLWithPath:appPath isDirectory:NO];
	return ([theURL checkResourceIsReachableAndReturnError:nil] == YES);
}
+ (void) clearAllSendToAppPreferences {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:PREF_SEND_FILE_TO_APP_NAME];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:PREF_SEND_FILE_TO_APP_PATH];
	[[NSUserDefaults standardUserDefaults] synchronize];
}
+ (void) openFileWithSendToApp:(NSString *) filePath {
	if ([self isSendToAppValid]) {
		NSURL *fileURL		= [NSURL fileURLWithPath: filePath];
		NSWorkspace * ws	= [NSWorkspace sharedWorkspace];
		[ws openFile:[fileURL path] withApplication:[self getSendToAppPath]];
	}
}



// --++--   --++--   --++--   --++--   --++--   --++--
#pragma mark -
#pragma mark MMStringFunctions
#pragma mark -

+ (NSString *) fRightBackOf:(NSString *)substring inString:(NSString *)inString {
	if(inString == nil || substring == nil || [inString length] < 1 || [substring length] < 1) {
		return @"";
	}
	
	NSArray *parts		= [inString componentsSeparatedByString:substring];
	
	// does it exist?
	if([parts count] < 1) {
		return @"";
	}
	
	return [parts objectAtIndex:([parts count] - 1)];
}
+ (BOOL) string:(NSString *)inString contains:(NSString *)substring {
	if(substring == nil || inString == nil || [substring length] < 1 || [inString length] < 1) {
		return NO;
	}
	
	NSRange range		= [inString rangeOfString:substring];
	return range.location != NSNotFound;
}

@end
