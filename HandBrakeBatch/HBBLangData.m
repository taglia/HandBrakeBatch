//
//  HBBLangData.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 15/01/2012.
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import "HBBLangData.h"

#import <sqlite3.h>

static HBBLangData *instance = nil;

@interface HBBLangData ()

@property (readwrite, assign, nonatomic) sqlite3 *dbHandle;

@end

@implementation HBBLangData

+ (HBBLangData *)defaultHBBLangData {
    if (instance == nil) {
        instance = [[HBBLangData alloc] init];
    }
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        NSString *dbFileName = [[NSBundle mainBundle] pathForResource:@"iso639-2" ofType:@"db"];
		sqlite3 *dbHandle = self.dbHandle;
        int status = sqlite3_open_v2([dbFileName cStringUsingEncoding:NSUTF8StringEncoding], &dbHandle, SQLITE_OPEN_READONLY, NULL);
        if (status != SQLITE_OK) {
            NSLog(@"Error opening language list database: %s", sqlite3_errmsg(dbHandle));
            return nil;
        }
    }
    return self;
}

- (NSArray *)languageList {
    NSString *statementString = @"SELECT Ref_Name_EN FROM ISO_639_2 ORDER BY Ref_Name_EN";
    const char *unused;
    sqlite3_stmt *statement;
    sqlite3 *dbHandle = self.dbHandle;
    if (sqlite3_prepare_v2(dbHandle, [statementString cStringUsingEncoding:NSUTF8StringEncoding], (int)[statementString length], &statement, &unused) != SQLITE_OK) {
        NSLog(@"Error preparing SQL statement (%@): %s", statementString, sqlite3_errmsg(dbHandle));
        return nil;
    }
    NSMutableArray *result = [[NSMutableArray alloc] init];
    int status;
    while ((status = sqlite3_step(statement)) == SQLITE_ROW) {
        const char *resultBytes = (const char *)sqlite3_column_text(statement, 0);
        [result addObject:[NSString stringWithUTF8String:resultBytes]];
    }
    if ( status != SQLITE_DONE ) {
        NSLog(@"Error executing SQL statement (%@): %s", statementString, sqlite3_errmsg(dbHandle));
        sqlite3_finalize(statement);
        return nil;
    }
    sqlite3_finalize(statement);
    return result;
}

- (NSString *)execSimpleStatement: (NSString *)statementString {
    const char *unused;
    sqlite3_stmt *statement;
    sqlite3 *dbHandle = self.dbHandle;
    if (sqlite3_prepare_v2(dbHandle, [statementString cStringUsingEncoding:NSUTF8StringEncoding], (int)[statementString length], &statement, &unused) != SQLITE_OK) {
        NSLog(@"Error preparing SQL statement (%@): %s", statementString, sqlite3_errmsg(dbHandle));
        return nil;
    }
    if (sqlite3_step(statement) != SQLITE_ROW) {
        NSLog(@"Error executing SQL statement (%@): %s", statementString, sqlite3_errmsg(dbHandle));
        sqlite3_finalize(statement);
        return nil;
    }
    const char *resultBytes = (const char *)sqlite3_column_text(statement, 0);
    NSString *result = [NSString stringWithUTF8String:resultBytes];
    sqlite3_finalize(statement);
    return result;
}

- (NSString *)langBCode: (NSString *)langName {
    NSString *statementString = [NSString stringWithFormat:@"SELECT Part2B FROM ISO_639_2 WHERE Ref_Name_EN = '%@'", langName];
    return [self execSimpleStatement:statementString];
}

- (NSString *)langTCode: (NSString *)langName {
    NSString *statementString = [NSString stringWithFormat:@"SELECT Part2T FROM ISO_639_2 WHERE Ref_Name_EN = '%@'", langName];
    return [self execSimpleStatement:statementString];
}

- (NSString *)langName: (NSString *)langCode {
    NSString *statementString = [NSString stringWithFormat:@"SELECT Ref_Name_EN FROM ISO_639_2 WHERE Part2B = '%@' OR Part2T = '%@'", langCode, langCode];
    return [self execSimpleStatement:statementString];
}

@end
