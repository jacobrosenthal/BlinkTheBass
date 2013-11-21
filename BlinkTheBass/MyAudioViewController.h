//
//  MyAudioViewController.h
//  MicInput
//
//  Created by Jacob Rosenthal on 7/24/12.
//  Copyright (c) 2013 MicInput. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AudioProcessor;

@interface MyAudioViewController : UIViewController {

}

@property (strong, nonatomic) AudioProcessor *audioProcessor;
@property (nonatomic) BOOL flag;
@property (nonatomic) int progressAsInt;
@property (nonatomic) NSMutableDictionary *dic;

@property (strong, nonatomic) UIColor *uiColor;
@property (strong, nonatomic) UILabel    *sliderLabel;

@property (strong, nonatomic) IBOutlet UISwitch *audioSwitch;
@property (strong, nonatomic) IBOutlet UILabel *gainValueLabel;
@property (strong, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet UILabel *topLabel;

// actions
- (IBAction)audioSwitch:(id)sender;
- (IBAction)sliderChanged:(id)sender;

// ui element manipulation
- (void)setGainLabelValue:(float)gainValue;
- (void)showLabelWithText:(NSString*)labelText;

@end
