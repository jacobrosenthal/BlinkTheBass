//
//  AudioProcessor.h
//  MicInput
//
//  Created by Jacob Rosenthal on 7/24/12.
//  Copyright (c) 2013 MicInput. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MyAudioViewController.h"

// return max value for given values
#define max(a, b) (((a) > (b)) ? (a) : (b))
// return min value for given values
#define min(a, b) (((a) < (b)) ? (a) : (b))

#define kOutputBus 0
#define kInputBus 1

// our default sample rate
#define SAMPLE_RATE 44100.00

@interface AudioProcessor : NSObject
{
    // Audio unit
    AudioComponentInstance audioUnit;
    
    // Audio buffers
	AudioBuffer audioBuffer;
}

@property (readonly) AudioBuffer audioBuffer;
@property (readonly) AudioComponentInstance audioUnit;
@property (nonatomic) float sensitivity;

-(AudioProcessor*)init:(float)currentSensitivity;

-(void)initializeAudio;
-(void)processBuffer: (AudioBufferList*) audioBufferList;

// control object
-(void)start;
-(void)stop;

// error managment
-(void)hasError:(int)statusCode:(char*)file:(int)line;

@end
