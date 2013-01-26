//
//  HBBAppFunctions.h
//  HandBrakeBatch
//
//  Created by Matt Maher on 1/26/13.
//
//

#import <Foundation/Foundation.h>

@interface HBBAppFunctions : NSObject


// SEND TO APP
+ (NSString *) getSendToAppPath;
+ (void) setSendToAppPath:(NSString *)path;
+ (NSString *) getSendToAppName;
+ (NSImage *) getIconForSendToApp;
+ (void) setSendToAppName:(NSString *)name;
+ (BOOL) isSendToAppValid;
+ (void) clearAllSendToAppPreferences;
+ (void) openFileWithSendToApp:(NSString *) filePath;


// MMStringFunctions (partials)
+ (NSString *) fRightBackOf:(NSString *)substring inString:(NSString *)inString;
+ (BOOL) string:(NSString *)inString contains:(NSString *)substring;
@end
