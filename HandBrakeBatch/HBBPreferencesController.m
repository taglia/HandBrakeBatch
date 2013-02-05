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

@interface HBBPreferencesController ()
	
@property (readwrite, assign, nonatomic) IBOutlet NSButton * maintainTimestamps;
@property (readwrite, assign, nonatomic) IBOutlet NSPopUpButton *mpeg4Extension;

@property (readwrite, assign, nonatomic) IBOutlet NSComboBox *audioBox;
@property (readwrite, assign, nonatomic) IBOutlet NSComboBox *subtitleBox;
@property (readwrite, assign, nonatomic) IBOutlet NSMatrix *audioMatrix;
@property (readwrite, assign, nonatomic) IBOutlet NSMatrix *subtitleMatrix;

@property (readwrite, strong, nonatomic) HBBLangData *langData;
@property (readwrite, strong, nonatomic) NSArray *languages;

@end

@implementation HBBPreferencesController

- (void)toggleLanguage:(bool)enable {
    if (enable) {
        [self.subtitleBox setEnabled:YES];
        [self.audioBox setEnabled:YES];
        [self.subtitleMatrix setEnabled:YES];
        [self.audioMatrix setEnabled:YES];
    } else {
        [self.subtitleBox setEnabled:NO];
        [self.audioBox setEnabled:NO];
        [self.subtitleMatrix setEnabled:NO];
        [self.audioMatrix setEnabled:NO];
    }
}

- (id)init {
	self = [super initWithWindowNibName:@"Preferences"];
    
    // Language radio buttons initialization
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"HBBAudioSelection"] == nil) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"HBBAudioSelection"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"HBBSubtitleSelection"] == nil) {
        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"HBBSubtitleSelection"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"HBBScanEnabled"] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HBBScanEnabled"];
    }
    
    self.langData = [HBBLangData defaultHBBLangData];
    self.languages = [self.langData languageList];
    
	return self;
}

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBScanEnabled"]) {
        [self toggleLanguage:YES];
    } else {
        [self toggleLanguage:NO];
    }
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return [self.languages count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    return [self.languages objectAtIndex:index];
}

- (IBAction)languageSelected:(id)sender {
    NSComboBox *box = sender;
    if ([self.languages containsObject:[box stringValue]]) {
        return;
	}
    NSBeginAlertSheet(@"Unknown Language!", @"Ok", nil, nil, [self window], nil, NULL, NULL, NULL, @"Please select a language from the dropdown list.");
    [box setStringValue:@"English"];
    
    if (sender == self.audioBox) {
        [[NSUserDefaults standardUserDefaults] setValue:@"English" forKey:@"HBBAudioPreferredLanguage"];
    } else {
        [[NSUserDefaults standardUserDefaults] setValue:@"English" forKey:@"HBBSubtitlePreferredLanguage"];
	}
}

- (IBAction)toggleLanguageScan:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HBBScanEnabled"]) {
        [self toggleLanguage:YES];
    } else {
        [self toggleLanguage:NO];
    }
}

@end
