//
//  MyAudioViewController.m
//  MicInput
//
//  Created by Jacob Rosenthal on 7/24/12.
//  Copyright (c) 2013 MicInput. All rights reserved.
//

#import "MyAudioViewController.h"
#import "AudioProcessor.h"

@implementation MyAudioViewController
@synthesize topLabel;
@synthesize audioSwitch, gainValueLabel, audioProcessor, uiColor, slider;



#pragma mark -
#pragma mark View lifecycle
/****************************************************************************/
/*								View Lifecycle                              */
/****************************************************************************/
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setGainLabelValue:(slider.value)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColor:) name:@"WatchColorUpdated" object:nil];
    NSTimer *mTimer;
    mTimer=[NSTimer scheduledTimerWithTimeInterval:.01
                                                       target:self
                                                     selector:@selector(updateScreen)
                                                     userInfo:nil
                                                      repeats:YES];

}

- (void)viewDidUnload
{
    [self setAudioSwitch:nil];
    [self setGainValueLabel:nil];
    [self setTopLabel:nil];
    [self setAudioProcessor:nil];
    [self setUiColor:nil];

    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark -
#pragma mark Screen Updaters
/****************************************************************************/
/*                              Screen Updaters                             */
/****************************************************************************/
- (void)updateScreen
{
    self.view.backgroundColor = uiColor;
}

- (void) updateColor: (NSNotification *) notify
{
    uiColor= [[notify userInfo]
                           objectForKey:@"color"];               // the field editor
}

// set gain label text value by given float
- (void)setGainLabelValue:(float)gainValue
{
    NSString *gain = [NSString stringWithFormat:@"%d", (int)gainValue];
    [gainValueLabel setText:gain];
}

- (void)showLabelWithText:(NSString*)labelText {
    [topLabel setText:labelText];
}

#pragma mark -
#pragma mark App IO
/****************************************************************************/
/*                              App IO Methods                              */
/****************************************************************************/
-(IBAction) sliderChanged:(id)sender {
    [self setGainLabelValue:(slider.value)];

    NSNumber *sensitivity = [NSNumber numberWithInt:(slider.value) ];

    NSString *key = @"sensitivity";
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:sensitivity forKey:key];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WatchSensitivityUpdated" object:nil userInfo:dictionary];
    

}

- (IBAction)audioSwitch:(id)sender {
    if (!audioSwitch.on) {
        [self showLabelWithText:@"Stopping AudioUnit"];
        [audioProcessor stop];
        [self showLabelWithText:@"AudioUnit stopped"];
        
    } else {
        if (audioProcessor == nil) {
            audioProcessor = [[AudioProcessor alloc] init:[slider value]];
        }
        [self showLabelWithText:@"Starting up AudioUnit"];
        [audioProcessor start];
        [self showLabelWithText:@"AudioUnit running"];
        
    }
    [self performSelector:@selector(showLabelWithText:) withObject:@"" afterDelay:3.5];
}

@end
