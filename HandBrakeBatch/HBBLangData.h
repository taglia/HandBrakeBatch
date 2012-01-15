//
//  HBBLangData.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 15/01/2012.
//  Copyright (c) 2012 Cesare Tagliaferri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface HBBLangData : NSObject {
    sqlite3 *dbHandle;
}

+(HBBLangData *)defaultHBBLangData;
-(NSArray *)languageList;
-(NSString *)langCode: (NSString *)langName;

@end
