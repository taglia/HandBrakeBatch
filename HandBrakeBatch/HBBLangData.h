//
//  HBBLangData.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 15/01/2012.
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface HBBLangData : NSObject {
    sqlite3 *dbHandle;
}

+(HBBLangData *)defaultHBBLangData;
-(NSArray *)languageList;
-(NSString *)langTCode: (NSString *)langName;
-(NSString *)langBCode: (NSString *)langName;
-(NSString *)langName: (NSString *)langCode;

@end
