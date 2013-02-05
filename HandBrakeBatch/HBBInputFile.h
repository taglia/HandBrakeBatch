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

@interface HBBInputFile : NSObject <NSCoding>

@property (readonly, strong, nonatomic) NSString *name;
@property (readonly, strong, nonatomic) NSString *inputPath;
@property (readonly, strong, nonatomic) NSString *outputPath;
@property (readonly, strong, nonatomic) NSString *tempOutputPath;
@property (readonly, strong, nonatomic) NSURL *inputURL;
@property (readonly, strong, nonatomic) NSURL *outputURL;
@property (readonly, strong, nonatomic) NSURL *tempOutputURL;
@property (readonly, assign, nonatomic) NSUInteger size;
@property (readonly, strong, nonatomic) NSArray *audioLanguages;
@property (readonly, strong, nonatomic) NSArray *subtitleLanguages;

- (id)initWithURL:(NSURL *)url;
- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)coder;

@end
