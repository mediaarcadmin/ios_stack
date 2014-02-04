/*
 Copyright 2010 Microsoft Corp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <Foundation/Foundation.h>


#ifdef DEBUG
#define FULL_LOGGING 1  // set to 1 to enable logging of request/response data
#else
#define FULL_LOGGING 0  // set to 1 to enable logging of request/response data
#endif

#ifdef DEBUG
#define WA_BEGIN_LOGGING { NSString* _varName = nil; void(^_loggingBlock)() = ^ {
#else
#define WA_BEGIN_LOGGING { {
#endif

#ifdef DEBUG
#define WA_BEGIN_LOGGING_CUSTOM(name) { NSString* _varName = @#name; void(^_loggingBlock)() = ^ {
#else
#define WA_BEGIN_LOGGING_CUSTOM(name) { {
#endif

#if FULL_LOGGING
	void logBlock(void(^block)(), NSString* varName);
	#define WA_END_LOGGING }; logBlock(_loggingBlock, _varName); }
#else
	#define WA_END_LOGGING }; }
#endif
