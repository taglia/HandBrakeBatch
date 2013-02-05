//
//  HBBPresets.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import <Foundation/Foundation.h>


@interface HBBPresets : NSObject {
@private
    NSDictionary *presets;
}

@property (assign) NSDictionary *presets;

+ (id)hbbPresets;
- (void)initPresets;

@end
