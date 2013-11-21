//
//  AudioProcessor.m
//  MicInput
//
//  Created by Jacob Rosenthal on 7/24/12.
//  Copyright (c) 2013 MicInput. All rights reserved.
//

#import "AudioProcessor.h"

#pragma mark Recording callback

static OSStatus recordingCallback(void *inRefCon, 
                                  AudioUnitRenderActionFlags *ioActionFlags, 
                                  const AudioTimeStamp *inTimeStamp, 
                                  UInt32 inBusNumber, 
                                  UInt32 inNumberFrames, 
                                  AudioBufferList *ioData) {
	
	// the data gets rendered here
    AudioBuffer buffer;
    
    // a variable where we check the status
    OSStatus status;
    
    /**
     This is the reference to the object who owns the callback.
     */
    AudioProcessor *audioProcessor = (__bridge AudioProcessor*) inRefCon;
    
    /**
     on this point we define the number of channels, which is mono
     for the iphone. the number of frames is usally 512 or 1024.
     */
    buffer.mDataByteSize = inNumberFrames * 2; // sample size
    buffer.mNumberChannels = 1; // one channel
	buffer.mData = malloc( inNumberFrames * 2 ); // buffer size
	
    // we put our buffer into a bufferlist array for rendering
	AudioBufferList bufferList;
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0] = buffer;
    
    // render input and check for error
    status = AudioUnitRender([audioProcessor audioUnit], ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
    [audioProcessor hasError:status:__FILE__:__LINE__];
    
	// process the bufferlist in the audio processor
    [audioProcessor processBuffer:&bufferList];
	 
    // clean up the buffer
	free(bufferList.mBuffers[0].mData);
	
    return noErr;
}


#pragma mark objective-c class

@implementation AudioProcessor
@synthesize audioUnit, audioBuffer, sensitivity;

-(AudioProcessor*)init:(float)currentSensitivity
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSensitivity:) name:@"WatchSensitivityUpdated" object:nil];
        [self initializeAudio];
        [self setSensitivity:currentSensitivity];
        
    }
    return self;
}

-(void)initializeAudio
{    
    OSStatus status;
	
	// We define the audio component
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output; // we want to ouput
	desc.componentSubType = kAudioUnitSubType_RemoteIO; // we want in and ouput
	desc.componentFlags = 0; // must be zero
	desc.componentFlagsMask = 0; // must be zero
	desc.componentManufacturer = kAudioUnitManufacturer_Apple; // select provider
	
	// find the AU component by description
	AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
	
	// create audio unit by component
	status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    
	[self hasError:status:__FILE__:__LINE__];
	
    // define that we want record io on the input bus
    UInt32 flag = 1;
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_EnableIO, // use io
								  kAudioUnitScope_Input, // scope to input
								  kInputBus, // select input bus (1)
								  &flag, // set flag
								  sizeof(flag));
	[self hasError:status:__FILE__:__LINE__];
	
	// define that we want play on io on the output bus
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_EnableIO, // use io
								  kAudioUnitScope_Output, // scope to output
								  kOutputBus, // select output bus (0)
								  &flag, // set flag
								  sizeof(flag));
	[self hasError:status:__FILE__:__LINE__];
	
	/* 
     We need to specifie our format on which we want to work.
     We use Linear PCM cause its uncompressed and we work on raw data.
     for more informations check.
     
     We want 16 bits, 2 bytes per packet/frames at 44khz 
     */
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate			= SAMPLE_RATE;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 1;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 2;
	audioFormat.mBytesPerFrame		= 2;
    
    
    
	// set the format on the output stream
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Output, 
								  kInputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
    
	[self hasError:status:__FILE__:__LINE__];
    
    // set the format on the input stream
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Input, 
								  kOutputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
	[self hasError:status:__FILE__:__LINE__];
	
	
	
    /**
        We need to define a callback structure which holds
        a pointer to the recordingCallback and a reference to
        the audio processor object
     */
	AURenderCallbackStruct callbackStruct;
    
    // set recording callback
	callbackStruct.inputProc = recordingCallback; // recordingCallback pointer
	callbackStruct.inputProcRefCon = (__bridge void *)(self);

    // set input callback to recording callback on the input bus
	status = AudioUnitSetProperty(audioUnit, 
                                  kAudioOutputUnitProperty_SetInputCallback, 
								  kAudioUnitScope_Global, 
								  kInputBus, 
								  &callbackStruct, 
								  sizeof(callbackStruct));
    
    [self hasError:status:__FILE__:__LINE__];
	
 	
    // reset flag to 0
	flag = 0;
    
    /*
     we need to tell the audio unit to allocate the render buffer,
     that we can directly write into it.
     */
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_ShouldAllocateBuffer,
								  kAudioUnitScope_Output, 
								  kInputBus,
								  &flag, 
								  sizeof(flag));
		
	// Initialize the Audio Unit and cross fingers =)
	status = AudioUnitInitialize(audioUnit);
	[self hasError:status:__FILE__:__LINE__];
    
    NSLog(@"Started");
    
}

#pragma mark controll stream

-(void)start;
{
    // start the audio unit. You should hear something, hopefully :)
    OSStatus status = AudioOutputUnitStart(audioUnit);
    [self hasError:status:__FILE__:__LINE__];
}
-(void)stop;
{
    // stop the audio unit
    OSStatus status = AudioOutputUnitStop(audioUnit);
    [self hasError:status:__FILE__:__LINE__];
}


#pragma mark processing

-(void)processBuffer: (AudioBufferList*) audioBufferList
{
    
    int sampleRate = 44100;
    int n=audioBufferList->mBuffers[0].mDataByteSize / 2;
    
    double result1 = [self findFrequency:80 inSample:audioBufferList ofSampleRate:sampleRate withN:n];
    double result2 = [self findFrequency:100 inSample:audioBufferList ofSampleRate:sampleRate withN:n];
    NSDictionary *dictionary;
    
    if (result1 > sensitivity || result2> sensitivity) {
        
        dictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:@"color"];
        
    }else{
        dictionary = [NSDictionary dictionaryWithObject:[UIColor blackColor] forKey:@"color"];
        
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WatchColorUpdated" object:nil userInfo:dictionary];
    //NSLog(@"%f with check being %d",(double)result,self._uiViewController.progressAsInt);

}

-(double)findFrequency:(double)freq inSample:(AudioBufferList*)audioBufferList ofSampleRate:(int)sampleRate withN:(int)N{
    
    SInt16 *editBuffer = audioBufferList->mBuffers[0].mData;
    
    double realW = 2.0 * cos(2.0 * M_PI * freq / sampleRate);
    double imagW = 2.0 * sin(2.0 * M_PI * freq / sampleRate);
    double d1 = 0;
    double d2 = 0;
    double y;
    for (int nb = 0; nb < (audioBufferList->mBuffers[0].mDataByteSize / 2); nb++) {
        y=(double)(signed short)editBuffer[nb] +realW * d1 - d2;
        d2 = d1;
        d1 = y;
    }
    double rR = 0.5 * realW *d1-d2;
    double rI = 0.5 * imagW *d1-d2;
    
    return (sqrt(pow(rR, 2)+pow(rI,2)))/N;
}

#pragma mark Error handling

-(void)hasError:(int)statusCode:(char*)file:(int)line 
{
	if (statusCode) {
		printf("Error Code responded %d in file %s on line %d\n", statusCode, file, line);
        exit(-1);
	}
}

- (void) updateSensitivity: (NSNotification *) notify {
    NSNumber *temp = [[notify userInfo]
                           objectForKey:@"sensitivity"];               // the field editor

    sensitivity=[temp floatValue];
}


@end
