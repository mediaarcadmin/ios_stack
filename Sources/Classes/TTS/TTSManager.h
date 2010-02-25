//
//  TTSManager.h
//
//  Created by Arnold Chien on 12/22/09.
//  Copyright 2009 Kurzweil Technologies Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TTSManager 
@required
- (BOOL)startSpeaking:(NSString *)string;
- (void)stopSpeaking;
- (void)pauseSpeaking;
@optional
- (void)stopSpeakingAtBoundary:(NSInteger)boundary;
- (BOOL)isSpeaking;
@end