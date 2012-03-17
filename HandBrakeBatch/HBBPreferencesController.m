//
//  HBBPreferencesController.m
//  HandBrakeBatch
//
//  Created by Cesare Tagliaferri on 30/07/2011.
//  This file is part of the HandBrakeBatch source code.
//  Homepage: <http://www.osomac.com/>.
//  It may be used under the terms of the GNU General Public License.
//

#import "HBBPreferencesController.h"

@implementation HBBPreferencesController

- (void)toggleLanguage: (bool)enable {
    if (enable) {
        [subtitleBox setEnabled:true];
        [audioBox setEnabled:true];
        [subtitleMatrix setEnabled:true];
        [audioMatrix setEnabled:true];
    } else {
        [subtitleBox setEnabled:false];
        [audioBox setEnabled:false];
        [subtitleMatrix setEnabled:false];
        [audioMatrix setEnabled:false];
    }
}

- (id)init
{
	self = [super initWithWindowNibName:@"Preferences"];
    
    // Language radio buttons initialization
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"HBBAudioSelection"] == nil) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"HBBAudioSelection"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"HBBSubtitleSelection"] == nil) {
        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"HBBSubtitleSelection"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"HBBScanEnabled"] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"HBBScanEnabled"];
    }
    
    langData = [HBBLangData defaultHBBLangData];
    languages = [langData languageList];
    
	return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBScanEnabled"]) {
        [self toggleLanguage:true];
    } else {
        [self toggleLanguage:false];
    }
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return [languages count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    return [languages objectAtIndex:index];
}

-(IBAction)languageSelected:(id)sender {
    NSComboBox *box = sender;
    
    if ( [languages containsObject:[box stringValue]] )
        return;
    
    NSBeginAlertSheet(@"Unknown Language!", @"Ok", nil, nil, [self window], nil, NULL, NULL, NULL, @"Please select a language from the dropdown list.");
    [box setStringValue:@"English"];
    
    if (sender == audioBox)
        [[NSUserDefaults standardUserDefaults] setValue:@"English" forKey:@"HBBAudioPreferredLanguage"];
    else
        [[NSUserDefaults standardUserDefaults] setValue:@"English" forKey:@"HBBSubtitlePreferredLanguage"];
}

-(IBAction)toggleLanguageScan:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBScanEnabled"]) {
        [self toggleLanguage:true];
    } else {
        [self toggleLanguage:false];
    }
}

@end
