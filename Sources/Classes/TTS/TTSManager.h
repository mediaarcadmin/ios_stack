//
//  TTSManager.h
//  TTSDemo
//
//  Created by Arnold Chien on 12/22/09.
//  Copyright 2009 Kurzweil Technologies Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TTSManager 
@required
- (void)initTTS;
- (BOOL)startSpeaking:(NSString *)string;
- (void)stopSpeaking;
@optional
- (BOOL)isSpeaking;
@end