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

#import "WAQueueMessage.h"
#import "WASimpleBase64.h"

@implementation WAQueueMessage

@synthesize messageId = _messageId;
@synthesize insertionTime = _insertionTime;
@synthesize expirationTime = _expirationTime;
@synthesize popReceipt = _popReceipt;
@synthesize timeNextVisible = _timeNextVisible;
@synthesize messageText = _messageText;
@synthesize dequeueCount = _dequeueCount;

- (id)initQueueMessageWithMessageId:(NSString *)messageId insertionTime:(NSString *)insertionTime expirationTime:(NSString *)expirationTime popReceipt:(NSString *)popReceipt timeNextVisible:(NSString *)timeNextVisible messageText:(NSString *)messageText {
    return [self initQueueMessageWithMessageId:messageId insertionTime:insertionTime expirationTime:expirationTime popReceipt:popReceipt timeNextVisible:timeNextVisible messageText:messageText dequeueCount:0];
}

- (id)initQueueMessageWithMessageId:(NSString *)messageId insertionTime:(NSString *)insertionTime expirationTime:(NSString *)expirationTime popReceipt:(NSString *)popReceipt timeNextVisible:(NSString *)timeNextVisible messageText:(NSString *)messageText dequeueCount:(NSInteger)dequeueCount{
	if ((self = [super init])) {
        _messageId = [messageId copy];
        _insertionTime = [insertionTime copy];
        _expirationTime = [expirationTime copy];
		_popReceipt = [popReceipt copy];
        _timeNextVisible = [timeNextVisible copy];
		_dequeueCount = dequeueCount;
        
		NSData* data = [messageText dataWithBase64DecodedString];
        self.messageText = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    }    
    return self;
}


- (NSString*) description {
    return [NSString stringWithFormat:@"QueueMessage { messageId = %@, insertionTime = %@, expirationTime = %@, popReceipt = %@, timeNextVisible = %@, messageText = %@ dequeueCount = %ld }", _messageId, _insertionTime, _expirationTime, _popReceipt, _timeNextVisible, _messageText, (long)_dequeueCount];
}

- (void) dealloc {
	
    self.messageText = nil;
    [_messageId release];
	[_insertionTime release];
	[_expirationTime release];
	[_popReceipt release];
	[_timeNextVisible release];
    
    [super dealloc];
}



@end
