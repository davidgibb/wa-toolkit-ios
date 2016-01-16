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

#import "FetchContainersDirectTests.h"
#import "WAToolkit.h"

@implementation FetchContainersDirectTests

#ifdef INTEGRATION_DIRECT

- (void)setUp
{
    [super setUp];
    WABlobContainer *container = [[[WABlobContainer alloc] initContainerWithName:randomContainerNameString] autorelease];
    [directClient addBlobContainer:container withCompletionHandler:^(NSError *error) {
        XCTAssertNil(error, @"Error returned from addBlobContainer: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
}

- (void)tearDown
{
    WABlobContainer *container = [[[WABlobContainer alloc] initContainerWithName:randomContainerNameString] autorelease];
    [directClient deleteBlobContainer:container withCompletionHandler:^(NSError *error) {
        XCTAssertNil(error, @"Error returned from deleteBlobContainer: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    [super tearDown];
}

- (void)testShouldFetchContainersWithContinuationUsingCompletionHandler
{
    WABlobContainerFetchRequest *fetchRequest = [WABlobContainerFetchRequest fetchRequest];
    fetchRequest.maxResult = 100;
    [directClient fetchBlobContainersWithRequest:fetchRequest usingCompletionHandler:^(NSArray* containers, WAResultContinuation *resultContinuation, NSError* error) 
     {
         XCTAssertNil(error, @"Error returned by fetchBlobContainersSegmented: %@", [error localizedDescription]);
         XCTAssertNotNil(containers, @"fetchBlobContainersSegmented returned nil");
         XCTAssertTrue(containers.count <= 100, @"fetchBlobContainersSegmented returned more than maxresults");
         [directDelegate markAsComplete];
     }];
	
	[directDelegate waitForResponse];	
}

- (void)testShouldFetchBlobContainersWithCompletionHandler
{   
    WABlobContainerFetchRequest *fetchRequest = [WABlobContainerFetchRequest fetchRequest];
    [directClient fetchBlobContainersWithRequest:fetchRequest usingCompletionHandler:^(NSArray *containers, WAResultContinuation *resultContinuation, NSError *error) {
        XCTAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
        XCTAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
        [directDelegate markAsComplete];
    }];
    
    [directDelegate waitForResponse];
}

#endif

@end
