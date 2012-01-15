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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
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

@end
