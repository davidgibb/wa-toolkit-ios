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

#import "PeekQueueMessagesDirectTests.h"
#import "WAToolkit.h"

@implementation PeekQueueMessagesDirectTests

#ifdef INTEGRATION_DIRECT

- (void)setUp
{
    [super setUp];
    
    [directClient addQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        XCTAssertNil(error, @"Error returned from addQueueNamed: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    [directClient addMessageToQueue:@"My Message test" queueName:randomQueueNameString withCompletionHandler:^(NSError *error) {
        XCTAssertNil(error, @"Error returned addMessageToQueue: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
    }];
	[directDelegate waitForResponse];
}

- (void)tearDown
{
    [directClient deleteQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        XCTAssertNil(error, @"Error returned from deleteQueueNamed: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    [super tearDown];
}

-(void)testShouldFetchQueueMessagesWithCompletionHandler
{
    [directClient peekQueueMessages:randomQueueNameString fetchCount:32 withCompletionHandler:^(NSArray* queueMessages, NSError* error) {
        XCTAssertNil(error, @"Error returned from peekQueueMessages: %@",[error localizedDescription]);
        XCTAssertEqual([queueMessages count], (NSUInteger)1, @"Should only be on message in queue.");
        WAQueueMessage *message = [queueMessages objectAtIndex:0];
        XCTAssertEqualObjects(@"My Message test", message.messageText, @"Message text was not saved correctly.");
        [directDelegate markAsComplete];
    }];
	[directDelegate waitForResponse];
}
#endif

@end
