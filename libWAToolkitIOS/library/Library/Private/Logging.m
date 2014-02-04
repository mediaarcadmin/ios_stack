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

#import "Logging.h"


#if FULL_LOGGING

void logBlock(void(^block)(), NSString* variableName)
{
	if(variableName)
	{
		NSString* logging = [[[NSProcessInfo processInfo] environment] valueForKey:variableName]; 
		if(logging && [logging compare:@"YES" options:NSCaseInsensitiveSearch] == NSOrderedSame)
		{
			block();
		}
		
		return;
	}

	static dispatch_once_t once;
    static BOOL shouldLog;
    dispatch_once(&once, ^
	{ 
		NSString* logging = [[[NSProcessInfo processInfo] environment] valueForKey:@"WALogging"]; 
		shouldLog = (logging && [logging compare:@"YES" options:NSCaseInsensitiveSearch] == NSOrderedSame); 
	});

	if(shouldLog)
	{
		block();
	}
}

#endif