//
//  HBBInputFile.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.

//

#import <Foundation/Foundation.h>


@interface HBBInputFile : NSObject {
    NSURL *inputURL;
    NSURL *outputURL;
    
    NSArray *audioLanguages;
    NSArray *subtitleLanguages;
    
    // Used to compute the ETA
    NSInteger size;
}

@property (readonly)NSString *name;
@property (readonly)NSString *inputPath;
@property (readonly)NSString *outputPath;
@property (assign)NSURL *inputURL;
@property (assign)NSURL *outputURL;
@property (readonly)NSInteger size;
@property (readonly)NSArray *audioLanguages;
@property (readonly)NSArray *subtitleLanguages;

- (id)initWithURL:(NSURL *)u;

@end
