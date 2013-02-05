//
//  HBBPreferencesController.h
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 30/07/2011.
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import <Cocoa/Cocoa.h>

@interface HBBPreferencesController : NSWindowController <NSComboBoxDataSource>

- (IBAction)languageSelected:(id)sender;
- (IBAction)toggleLanguageScan:(id)sender;

@end
