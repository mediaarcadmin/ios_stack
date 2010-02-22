//
//  etup.m
//  tts_demo
//
//  Created by Jo De Lafonteyne on 02/10/08.
//  Copyright 2008 Acapela. All rights reserved.
//

#import "setupTTS.h"
#import "AcapelaTTS.h"
#import "BlioAppSettingsConstants.h"

@implementation setupTTS

@synthesize Voices;
@synthesize CurrentVoice;
@synthesize CurrentVoiceName;
@synthesize AutoMode;

-(id)initialize
{
	AutoMode = FALSE;
	Voices = [[NSArray arrayWithArray:[AcapelaSpeech availableVoices]] retain];
	if (Voices.count > 0) 
		CurrentVoiceName = [[self SetCurrentVoice:[[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastVoiceDefaultsKey]] retain];
	else
		CurrentVoice = NULL;
	
	return self;
}

- (NSString*)SetCurrentVoice:(NSInteger)row
{
	CurrentVoice = [Voices objectAtIndex:row];
	NSDictionary *dic = [AcapelaSpeech attributesForVoice:CurrentVoice];
	CurrentVoiceName = [dic valueForKey:AcapelaVoiceName];
	return CurrentVoiceName;
}
@end
