//
//  HBBVideoScan.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 16/01/2012.
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import <Foundation/Foundation.h>

@interface HBBVideoScan : NSObject

@property (readonly, strong, nonatomic) NSString *fileName;
@property (readonly, strong, nonatomic) NSArray *audioLanguages;
@property (readonly, strong, nonatomic) NSArray *subtitleLanguages;

- (id)initWithFile:(NSString *)path;
- (void)scan;

@end
