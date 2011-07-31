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
    
    // Used to compute the ETA
    NSInteger size;
}

@property (readonly)NSString *name;
@property (readonly)NSString *inputPath;
@property (readonly)NSString *outputPath;
@property (assign)NSURL *inputURL;
@property (assign)NSURL *outputURL;
@property (readonly)NSInteger size;

- (id)initWithURL:(NSURL *)u;

@end
